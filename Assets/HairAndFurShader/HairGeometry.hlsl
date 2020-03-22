// Geometry shader
//https://github.com/tirioko/

struct AttributesMeshC
{
	float3 positionOS   : POSITION;
	float3 normalOS     : NORMAL;

#ifdef ATTRIBUTES_NEED_TANGENT
	float4 tangentOS    : TANGENT; // Store sign in w
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD0
	float2 uv0          : TEXCOORD0;
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD1
	float2 uv1          : TEXCOORD1;
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD2
	float2 uv2          : TEXCOORD2;
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD3
	float2 uv3          : TEXCOORD3;
#endif
#ifdef ATTRIBUTES_NEED_COLOR
	float4 color        : COLOR;
#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
};


PackedVaryingsToPS VertexOutput(
    AttributesMeshC source,   float3 position, float3 position_prev, float3 normal,  float3 tanVector, half vaDir, float4 color)

{
#if defined(VARYINGS_NEED_TEXCOORD1) || defined(VARYINGS_DS_NEED_TEXCOORD1)   
    source.uv1 = source.uv1 + 1e-12;
#endif
#ifdef ATTRIBUTES_NEED_NORMAL
    source.normalOS = normal;
#endif
#ifdef ATTRIBUTES_NEED_COLOR
    source.color = color;
#endif

PackedVaryingsToPS result;
PackedVaryingsMeshToPS vmesh;
float3 vPos = TransformWorldToView(position);
float3 tanPos = TransformWorldToView(tanVector);
float3 vPosShadowfix=vPos;
#if SHADERPASS == SHADERPASS_SHADOWS 
if (UNITY_MATRIX_P[3][3]==1)
{
 vPosShadowfix=float3(0,0,-1);
}
#endif

float3 norm = normalize(cross(vPos-tanPos,vPosShadowfix));
vmesh.positionCS =  TransformWViewToHClip(vPos+0.001*vaDir*norm);

#ifdef VARYINGS_NEED_PASS
    PackedVaryingsPassToPS vpass;
	float4 vppos = mul(UNITY_MATRIX_UNJITTERED_VP, float4(position , 1));

	vmesh.positionCS.z -= 0.001;// unity_MotionVectorsParams.z * vmesh.positionCS.w;//TODO check why not working

	float4 prev_vppos = mul(UNITY_MATRIX_PREV_VP, float4(position_prev, 1));
	vpass.interpolators0 = float3(vppos.xyw);
	vpass.interpolators1 = float3(prev_vppos.xyw);
#endif
	
#ifdef VARYINGS_NEED_POSITION_WS
     vmesh.interpolators0= float4(1,1,1,1);// source.positionOS.xyz;
#endif
#ifdef VARYINGS_NEED_TANGENT_TO_WORLD
   vmesh.interpolators1=source.normalOS;
    vmesh.interpolators2= source.tangentOS;
#endif
#ifdef VARYINGS_NEED_TEXCOORD1
     vmesh.interpolators3.xy=float2(0,0);
     vmesh.interpolators3.zw=float2(0,0);
	 #endif
#ifdef VARYINGS_NEED_TEXCOORD3
     vmesh.interpolators4.xy=float2(0,0);
    vmesh.interpolators4.zw=float2(0,0);
#endif
#ifdef VARYINGS_NEED_COLOR
     vmesh.interpolators5= color;
#endif
 UNITY_VERTEX_INPUT_INSTANCE_ID 

#if defined(VARYINGS_NEED_CULLFACE) && SHADER_STAGE_FRAGMENT
    FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
#endif
result.vmesh=vmesh;
#ifdef VARYINGS_NEED_PASS
result.vpass=vpass;
#endif
return result;
} 


AttributesMeshC ConvertToAttributesMeshC(PackedVaryingsToPS input)
{
	AttributesMeshC am;
    am.positionOS = input.vmesh.positionCS.xyz;	

#ifdef VARYINGS_NEED_TANGENT_TO_WORLD
    am.normalOS = input.vmesh.interpolators1;
#else
	am.normalOS = float3(0, 0, 0);

#endif

#ifdef ATTRIBUTES_NEED_TANGENT
    am.tangentOS = input.vmesh.interpolators2;
#endif
#if (SHADERPASS != SHADERPASS_DEPTH_ONLY &&SHADERPASS != SHADERPASS_SHADOWS)
#ifdef ATTRIBUTES_NEED_TEXCOORD0
    am.uv0 = input.vmesh.interpolators3.xy;
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD1
    am.uv1 = input.vmesh.interpolators3.zw;
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD2
    am.uv2 = input.vmesh.interpolators4.xy;
#endif
#ifdef ATTRIBUTES_NEED_TEXCOORD3
    am.uv3 = input.vmesh.interpolators4.zw;
#endif
#ifdef ATTRIBUTES_NEED_COLOR
    am.color = input.vmesh.interpolators5;
#endif

#endif
    UNITY_TRANSFER_INSTANCE_ID(input, am);
    return am;
} 


[maxvertexcount(36)]
void HairGeometry(
    triangle PackedVaryingsToPS input[3], uint pid : SV_PrimitiveID,
    inout TriangleStream<PackedVaryingsToPS> outStream
)
{   
    // Input vertices
	AttributesMeshC v0 = ConvertToAttributesMeshC(input[0]);
	AttributesMeshC v1 = ConvertToAttributesMeshC(input[1]);
	AttributesMeshC v2 = ConvertToAttributesMeshC(input[2]);

    float3 p0 = (v0.positionOS);
    float3 p1 =(v1.positionOS);
    float3 p2 =( v2.positionOS);

#if SHADERPASS == SHADERPASS_MOTION_VECTORS
    bool hasDeformation = unity_MotionVectorsParams.x > 0.0;    
	float3 p0_prev = input[0].vpass.interpolators1.xyz;
	float3 p1_prev = input[1].vpass.interpolators1.xyz;
	float3 p2_prev = input[2].vpass.interpolators1.xyz;
#else
    float3 p0_prev = p0;
    float3 p1_prev = p1;
    float3 p2_prev = p2;
#endif

#ifdef ATTRIBUTES_NEED_NORMAL
	float3 n0 = v0.normalOS;
    float3 n1 = v1.normalOS;
    float3 n2 =  v2.normalOS;
#else
    float3 n0 = float3(100, 0, 0);
    float3 n1 = float3(100, 0, 0);
    float3 n2 = float3(100, 0, 0);
#endif
#if SHADERPASS != SHADERPASS_MOTION_VECTORS

#ifdef ATTRIBUTES_NEED_TANGENT
    float3 t0 = v0.tangentOS;
    float3 t1 = v1.tangentOS;
    float3 t2 = v2.tangentOS;
#else
    float3 t0 = float3(10000, 0, 0);
    float3 t1 = float3(10000, 0, 0);
    float3 t2 = float3(10000, 0, 0);
#endif

#ifdef ATTRIBUTES_NEED_TEXCOORD0
	float2 uv0 = v0.uv0;
	
#else
	float2 uv0 = float2(0, 0);
	
#endif

#endif

  float a =0;

#if SHADERPASS == SHADERPASS_GBUFFER
  UVMapping _UVMapping;
  _UVMapping.mappingType = 0;
  _UVMapping.uv = uv0;
  _UVMapping.uvZY= uv0;
  _UVMapping.uvXZ = uv0;
  _UVMapping.uvXY = uv0;
  _UVMapping.normalWS = float3(0, 0, 0);
  _UVMapping.triplanarWeights = float3(0, 0, 0);
  _UVMapping.tangentWS = float3(0, 0, 0);
  _UVMapping.bitangentWS = float3(0, 0, 0);
		  

  float4 texTest = SAMPLE_UVMAPPING_TEXTURE2D_LOD(_BaseColorMap, sampler_BaseColorMap, _UVMapping, 0);
#else
	 float4 texTest = float4(0,0,0,0);
#endif


 float3 pt =  (p2+p1+p0)/3; 

 float _Width = 1;
  float3 pA1 = pt+0.05*n0-float3(0,0.02,0); 
  float3 pA15 = pt+0.09*n0-float3(0,0.04,0);
  float3 pA2 = pt+0.13*n0-float3(0,0.06,0); 
  
 
#if SHADERPASS == SHADERPASS_MOTION_VECTORS

   float3 pt_prev = (p2_prev + p1_prev + p0_prev) / 3;

   float3 pA1_prev = pt_prev + 0.05*n0 - float3(0, 0.02, 0);
   float3 pA15_prev = pt_prev + 0.09*n0 - float3(0, 0.04, 0);
   float3 pA2_prev = pt_prev + 0.13*n0 - float3(0, 0.06, 0);

#else
   float3 pA1_prev = pA1;
   float3 pA15_prev = pA15;
   float3 pA2_prev = pA2;   
  float3 pt_prev = pt;

#endif

   	   outStream.Append(VertexOutput(v0, pt, pt_prev, n0, pA1,   1, float4(0.01, 0.05, 0.6, 1)));
	   outStream.Append(VertexOutput(v0, pt, pt_prev, n0, pA1,  -1,  float4(0.01, 0.05, 0.6, 1)));

       outStream.Append(VertexOutput(v0,  pA1,  pA1_prev, n0, pt,  -1, float4(0.5, 0.0, 0.6, 1)));
       outStream.Append(VertexOutput(v0,  pA1,  pA1_prev, n0, pt,  1, float4(0.5, 0.0, 0.6, 1)));
	   
	   outStream.Append(VertexOutput(v0,  pA15, pA15_prev, n0, pA1, -1, float4(0.9, 0.1, 0.2, 1)));
       outStream.Append(VertexOutput(v0,  pA15, pA15_prev, n0, pA1, 1, float4(0.9, 0.1, 0.2, 1)));

	   outStream.Append(VertexOutput(v0,  pA2, pA2_prev, n0, pA15, 0, texTest));
       outStream.RestartStrip();
	  
}
