float _TessellationUniform;
sampler2D _HeightMap;
float _HeightScale;

struct VertexData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
};

struct InterpolatorsVertex {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;

    #if defined(BINORMAL_PER_FRAGMENT)
    float4 tangent : TEXCOORD2;
    #else
    float3 tangent : TEXCOORD2;
    float3 binormal : TEXCOORD3;
    #endif


};

struct TessellationControlPoint {
    float4 vertex : INTERNALTESSPOS;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
};

struct TessellationFactor
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

TessellationFactor MyPatchConstantFunction(InputPatch<TessellationControlPoint, 3> patch)
{
    TessellationFactor f;
    f.edge[0] = _TessellationUniform;
    f.edge[1] = _TessellationUniform;
    f.edge[2] = _TessellationUniform;
    f.inside = _TessellationUniform;
    return f;
}

InterpolatorsVertex MyVertexProgram (VertexData v) {
    InterpolatorsVertex i;
    UNITY_INITIALIZE_OUTPUT(InterpolatorsVertex, i);
    i.pos = UnityObjectToClipPos(v.vertex);
    #if FOG_DEPTH
    i.worldPos.w = i.pos.z;
    #endif
    i.normal = UnityObjectToWorldNormal(v.normal);

    #if defined(BINORMAL_PER_FRAGMENT)
    i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    #else
    i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
    #endif


    #if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
    i.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
    i.dynamicLightmapUV =
        v.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    #if defined (_PARALLAX_MAP)
    #if defined(PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING)
    v.tangent.xyz = normalize(v.tangent.xyz);
    v.normal = normalize(v.normal);
    #endif
    float3x3 objectToTangent = float3x3(
        v.tangent.xyz,
        cross(v.normal, v.tangent.xyz) * v.tangent.w,
        v.normal
    );
    i.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
    #endif

    i.uv = v.uv;
    return i;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("MyPatchConstantFunction")]
TessellationControlPoint MyHullProgram(InputPatch<TessellationControlPoint, 3> patch,
    uint id : SV_OutputControlPointID)
{
    return patch[id];
}

[UNITY_domain("tri")]
InterpolatorsVertex  MyDomainProgram(TessellationFactor factors,
    OutputPatch<TessellationControlPoint, 3> patch,
    float3 barycentricCoordinates : SV_DomainLocation)
{
    VertexData data;
    
    #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
        patch[0].fieldName * barycentricCoordinates.x + \
        patch[1].fieldName * barycentricCoordinates.y + \
        patch[2].fieldName * barycentricCoordinates.z;
    
    MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
    MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
    MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
    MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
    MY_DOMAIN_PROGRAM_INTERPOLATE(uv1)
    MY_DOMAIN_PROGRAM_INTERPOLATE(uv2)

    data.vertex.xyz += tex2Dlod(_HeightMap, float4(data.uv, 0, 0)) * data.normal * _HeightScale;

    return MyVertexProgram(data);
}

TessellationControlPoint MyTessellationVertexProgram(VertexData v)
{
    TessellationControlPoint p;
    p.vertex = v.vertex;
    p.normal = v.normal;
    p.tangent = v.tangent;
    p.uv = v.uv;
    p.uv1 = v.uv1;
    p.uv2 = v.uv2;
    return p;
}