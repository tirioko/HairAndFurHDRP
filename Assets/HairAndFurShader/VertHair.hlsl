
PackedVaryingsType VertC(AttributesMesh inputMesh)
{
    VaryingsType varyingsType;
    varyingsType.vmesh = VertMesh(inputMesh);
	 
    return PackVaryingsType(varyingsType);
}

