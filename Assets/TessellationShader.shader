Shader "Unlit/TessellationShader"
{
    Properties
    {
        _HeightMap ("Texture", 2D) = "white" {}
        _HeightScale ("Height Scale", Range(0, 100)) = 1
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #pragma target 4.6

            #include "UnityCG.cginc"
            #include "MyTessellation.hlsl"
            #pragma vertex MyTessellationVertexProgram
            #pragma fragment frag
            #pragma hull MyHullProgram
            #pragma domain MyDomainProgram
            // make fog work
            #pragma multi_compile_fog

            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            float4 _MainTex_ST;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_HeightMap, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                col = float4(i.uv, 0, 1);
                return col;
            }
            ENDHLSL
        }
    }
}
