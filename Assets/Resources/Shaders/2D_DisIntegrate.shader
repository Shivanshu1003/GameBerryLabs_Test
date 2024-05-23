Shader "Unlit/2D_DisIntegrate"
{
    CGINCLUDE
    #include "UnityCG.cginc"
    CBUFFER_START(UnityPerMaterial)
        sampler2D _MainTex;
        float4 _MainTex_ST,_EdgeColor,_Color;
        half _Scale,_Blend, _EdgeThreshold;
    CBUFFER_END

        void Unity_Remap_float4(float4 In, float2 InMinMax, float2 OutMinMax, out float4 Out)
    {
        Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
    }

    float2 unity_gradientNoise_dir(float2 p)
    {
        p = p % 289;
        float x = (34 * p.x + 1) * p.x % 289 + p.y;
        x = (34 * x + 1) * x % 289;
        x = frac(x / 41) * 2 - 1;
        return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
    }

    float unity_gradientNoise(float2 p)
    {
        float2 ip = floor(p);
        float2 fp = frac(p);
        float d00 = dot(unity_gradientNoise_dir(ip), fp);
        float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
        float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
        float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
        fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
        return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
    }

    void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
    {
        Out = unity_gradientNoise(UV * Scale) + 0.5;
    }

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    v2f vert(appdata_base v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
        return o;
    }
    ENDCG
    Properties
    {
        _Color("Color",color) = (1,1,1,1)
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        _Scale("Noise Scale",float) = 3
        _Blend("Blend",Range(0,1)) = 0
        //_EdgeColor("Edge Color",color)=(0,0,0,0)
        _EdgeThreshold("Edge Threshold",float) = 0.5
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent"
                "Queue" ="Transparent"
             }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float noise;
                Unity_GradientNoise_float(i.uv,_Scale, noise);

                float b = (_Blend * 2.0f - 1.0f) * 1.05f;  
                float edgeFactor = smoothstep(b - 0.05, b + 0.05,noise);
                //float edgeFactor = saturate(pow(noise,0.5));
                edgeFactor = step(edgeFactor,_EdgeThreshold);
                //float3 outline = edgeFactor * _EdgeColor;
                return float4(col * edgeFactor * _Color);
            }
            ENDCG
        }
    }
}
