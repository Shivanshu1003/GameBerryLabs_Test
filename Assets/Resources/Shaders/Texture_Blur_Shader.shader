Shader "Unlit/Texture_Blur_Shader"
{
    CGINCLUDE
    #include "UnityCG.cginc" 
    CBUFFER_START(UnityPerMaterial)
        sampler2D _MainTex;
        float4 _MainTex_ST,_MainTex_TexelSize,_Center;
        half _Blend,_Sigma,_Radius,_SpaceSigma,_RangeSigma,_Width,_Radius2,_Iterations,_Amount;
    CBUFFER_END      
    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };
    v2f vert (appdata_base v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
        return o;
    }    
    ENDCG

    

    Properties
    {
        _MainTex ("Texture", 2D) = "grey" {}
        [Header(Box Blur)][Space(5)]
        _Blend("Amount",float) = 0        
    }
    SubShader
    {
    Tags { "Queue"="Transparent" }
    Cull Off 
    ZWrite Off 
    Pass
    {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag        
        
        fixed4 frag (v2f i) : SV_Target
        {
            float3 col = 0;
            UNITY_UNROLL
            for(int m = -4 ; m <= 4 ; m++)
            {
                UNITY_UNROLL
                for(int n = -4; n <= 4 ; n++)
                {
                    float2 o = float2(m,n) * _MainTex_TexelSize.xy * max(0.0f,_Blend);
                    col += tex2D(_MainTex,i.uv + o).xyz;
                }
            }
            col *= 1.0f/81.0f;
            return float4(col,1);
        }  
        ENDCG
        }
    }
}

