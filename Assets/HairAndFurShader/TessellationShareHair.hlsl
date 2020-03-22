//Tesselation for hair is not depend from view, to prevent changes in hair density. Density values are hardcoded for now
#if defined(SHADER_API_XBOXONE) || defined(SHADER_API_PSSL)
// AMD recommand this value for GCN http://amd-dev.wpengine.netdna-cdn.com/wordpress/media/2013/05/GCNPerformanceTweets.pdf
#define MAX_TESSELLATION_FACTORS 15.0
#else
#define MAX_TESSELLATION_FACTORS 64.0
#endif

struct TessellationFactorsCust
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

TessellationFactorsCust HullConstantC(InputPatch<PackedVaryingsToDS, 3> input)
{
  
    TessellationFactorsCust output;
    output.edge[0] = 10;// min(tf.x, MAX_TESSELLATION_FACTORS);
    output.edge[1] = 10;//min(tf.y, MAX_TESSELLATION_FACTORS);
    output.edge[2] = 10;//min(tf.z, MAX_TESSELLATION_FACTORS);
    output.inside  = 10;//min(tf.w, MAX_TESSELLATION_FACTORS);

    return output;
}

[maxtessfactor(MAX_TESSELLATION_FACTORS)]
[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HullConstantC")]
[outputcontrolpoints(3)]
PackedVaryingsToDS HullHair(InputPatch<PackedVaryingsToDS, 3> input, uint id : SV_OutputControlPointID)
{
    // Pass-through
    return input[id];
}

[domain("tri")]
PackedVaryingsToPS DomainHair(TessellationFactorsCust tessFactors, const OutputPatch<PackedVaryingsToDS, 3> input, float3 baryCoords : SV_DomainLocation)
{
    VaryingsToDS varying0 = UnpackVaryingsToDS(input[0]);
    VaryingsToDS varying1 = UnpackVaryingsToDS(input[1]);
    VaryingsToDS varying2 = UnpackVaryingsToDS(input[2]);

    VaryingsToDS varying = InterpolateWithBaryCoordsToDS(varying0, varying1, varying2, baryCoords);

    // We have Phong tessellation in all case where we don't have displacement only
//#ifdef _TESSELLATION_PHONG
//
 //   float3 p0 = varying0.vmesh.positionRWS;
//    float3 p1 = varying1.vmesh.positionRWS;
//    float3 p2 = varying2.vmesh.positionRWS;
//
//    float3 n0 = varying0.vmesh.normalWS;
//    float3 n1 = varying1.vmesh.normalWS;
 //   float3 n2 = varying2.vmesh.normalWS;

 //   varying.vmesh.positionRWS = PhongTessellation(  varying.vmesh.positionRWS,
 //                                                   p0, p1, p2, n0, n1, n2,
 //                                                   baryCoords,_TesselationShapeFactor);
//#endif

#ifdef HAVE_TESSELLATION_MODIFICATION
    //ApplyTessellationModification(varying.vmesh, varying.vmesh.normalWS, varying.vmesh.positionRWS);
#endif

	VaryingsToPS output;

 VaryingsMeshToPS vmesh;

vmesh.positionCS =float4(varying.vmesh.positionRWS,1);

#ifdef VARYINGS_NEED_POSITION_WS
     vmesh.positionRWS = varying.vmesh.positionRWS;
#endif

#ifdef VARYINGS_NEED_TANGENT_TO_WORLD
     vmesh.normalWS = varying.vmesh.normalWS;
     vmesh.tangentWS = varying.vmesh.tangentWS;
#endif

#ifdef VARYINGS_NEED_TEXCOORD0
     vmesh.texCoord0 = varying.vmesh.texCoord0;
#endif
#ifdef VARYINGS_NEED_TEXCOORD1
     vmesh.texCoord1 = varying.vmesh.texCoord1;
#endif
#ifdef VARYINGS_NEED_TEXCOORD2
     vmesh.texCoord2 = varying.vmesh.texCoord2;
#endif
#ifdef VARYINGS_NEED_TEXCOORD3
     vmesh.texCoord3 = varying.vmesh.texCoord3;
#endif
#ifdef VARYINGS_NEED_COLOR
     vmesh.color = varying.vmesh.color;
#endif
output.vmesh=vmesh;

#ifdef VARYINGS_NEED_PASS
output.vpass = varying.vpass;
#endif

    return PackVaryingsToPS(output);


   // return VertTesselation(varying);
}
