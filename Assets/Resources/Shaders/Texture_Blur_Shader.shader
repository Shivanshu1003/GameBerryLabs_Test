Shader "Unlit/Texture_Blur_Shader"
{
    CGINCLUDE
    #include "UnityCG.cginc" 
    CBUFFER_START(UnityPerMaterial)
        sampler2D _MainTex;
        float4 _MainTex_ST,_MainTex_TexelSize,_Center;
        half _BlurAmount,_Sigma,_Radius,_SpaceSigma,_RangeSigma,_Width,_Radius2,_Iterations,_Amount;
    CBUFFER_END

    inline float BellCurve(float sigma, int x)
    {
        return exp(-(x * x) / (2 * sigma * sigma));
    }

    inline float Gauss(float sigma, int x, bool isHalf)
    {
        return BellCurve(sigma, x) * (isHalf ? 0.5 : 1);
    }

    inline float GaussianWeightSum1D(float sigma, int radius)
    {
        float sum = 0;
        for(int j = 0 ; j < radius * 2 + 1 ; j++)
        {
            sum += BellCurve(sigma, j - radius);
        }
        return sum;
    }

    inline float GaussianWeightSum2D(float sigma, int radius)
    {
        const float baseSum = GaussianWeightSum1D(sigma, radius);
        float sum = 0;
        for(int j = 0; j < radius * 2 + 1; j++)
        {
            sum += BellCurve(sigma, j - radius) * baseSum;
        }
        return sum;
    }

    float4 GaussianBlurSeparable(sampler2D tex, float2 delta, float2 uv, float sigma, int radius)
    {
        int idx = -radius;
        float4 res = 0;

        const float totalWeight = GaussianWeightSum1D(sigma, radius);
        const float totalWeightRcp = 1.0 / totalWeight;

        for (int i = 0; i < radius + 1; ++i)
        {
            const int x0 = idx;
            const bool isNarrow = (radius & 1) == 0 && x0 == 0;
            const int x1 = isNarrow ? x0 : x0 + 1;

            const float w0 = Gauss(sigma, x0, x0 == 0);
            const float w1 = Gauss(sigma, x1, x1 == 0);

            const float texelOffset = isNarrow ? 0 : w1 / (w0 + w1);
            const float2 sampleUV = uv + (x0 + texelOffset) * delta;
            const float weight = (w0 + w1) * totalWeightRcp;
            res += tex2D(tex, sampleUV) * weight;

            UNITY_FLATTEN
            if ((radius & 1) == 1 && x1 == 0)
            {
                idx = 0;
            }
            else
            {
                idx = x1 + 1;
            }
        }
        return res;
    }

    float4 GaussianBlurHorizontal(sampler2D tex, float2 delta, float2 uv, float sigma, int radius)
    {
        return GaussianBlurSeparable(tex, float2(delta.x, 0), uv, sigma, radius);
    }

    float4 GaussianBlurVertical(sampler2D tex, float2 delta, float2 uv, float sigma, int radius)
    {
        return GaussianBlurSeparable(tex, float2(0, delta.y), uv, sigma, radius);
    }

    float4 GaussianBlurSingle(sampler2D tex, float2 delta, float2 uv, float sigma, int radius)
    {
        float4 res = 0;

        const float totalWeight = GaussianWeightSum2D(sigma, radius);
        const float totalWeightRcp = 1.0 / totalWeight;

        int idxY = -radius;

        for (int i = 0; i < radius + 1; ++i)
        {
            const int y0 = idxY;
            const bool isNarrowY = (radius & 1) == 0 && y0 == 0 || (radius & 1) == 1 && y0 == radius;
            const int y1 = isNarrowY ? y0 : y0 + 1;

            int idxX = -radius;

            for (int j = 0; j < radius + 1; ++j)
            {
                const int x0 = idxX;
                const bool isNarrowX = (radius & 1) == 0 && x0 == 0 || (radius & 1) == 1 && x0 == radius;
                const int x1 = isNarrowX ? x0 : x0 + 1;

                const float wx0 = Gauss(sigma, x0, isNarrowX);
                const float wx1 = Gauss(sigma, x1, isNarrowX);
                const float wy0 = Gauss(sigma, y0, isNarrowY);
                const float wy1 = Gauss(sigma, y1, isNarrowY);

                const float2 texelOffset = float2(isNarrowX ? 0 : wx1 / (wx0 + wx1), isNarrowY ? 0 : wy1 / (wy0 + wy1));
                const float2 sampleUV = uv + (float2(x0, y0) + texelOffset) * delta;

                const float weight = ((wx0 + wx1) * wy0 + (wx0 + wx1) * wy1) * totalWeightRcp;
                res += tex2D(tex, sampleUV) * weight;

                idxX = x1 + 1;
            }

            idxY = y1 + 1;
        }
        return res;
    }

    float3 BilateralBlur(float2 uv, float space_sigma, float range_sigma)
    {
        float weight_sum = 0;
            float3 color_sum = 0;

            float3 color_origin = tex2D(_MainTex,uv);
            float3 color = 0;

            for(int m = -4; m < 4; m++)
            {
                for(int n = -4; n < 4; n++)
                {
                    float2 varible = uv + float2(m * _MainTex_TexelSize.x, n * _MainTex_TexelSize.y);
                    float space_factor = m * m + n * n;
                    space_factor = (-space_factor) / (2 * space_sigma * space_sigma);
                    float space_weight = 1/(space_sigma * space_sigma * 2 * UNITY_PI) * exp(space_factor);


                    float3 color_neighbor = tex2D(_MainTex,varible);
                    float3 color_distance = (color_neighbor - color_origin);
                    float value_factor = color_distance.r * color_distance.r ;
                    value_factor = (-value_factor) / (2 * range_sigma * range_sigma);
                    float value_weight = (1 / (2 * UNITY_PI * range_sigma)) * exp(value_factor);

                    weight_sum += space_weight * value_weight;
                    color_sum += color_neighbor * space_weight * value_weight;
                }   
            }
            if(weight_sum > 0)
            {
            color = color_sum / weight_sum;
            }
            return color;
    }

    float3 DirectionalBlur(float2 uv,half width)
    {
        half4 color = tex2D(_MainTex,uv);
        half samples[10];
        samples[0] = -0.8;
        samples[1] = -0.5;
        samples[2] = -0.3;
        samples[3] = -0.2;
        samples[4] = -0.1;
        samples[5] =  0.1;
        samples[6] =  0.2;
        samples[7] =  0.3;
        samples[8] =  0.5;
        samples[9] =  0.8;

        half2 dir = 0.5 * half2(_MainTex_TexelSize.z,_MainTex_TexelSize.w) - uv;
       
        half dist = sqrt(dir.x * dir.x + dir.y * dir.y);
       
        //normalize direction
        dir = dir/dist;
       
        half4 sum = color;
        for(int n = 0; n < 10; n++)
        {
            sum += tex2D(_MainTex, uv + dir * samples[n] * max(0.0f,width) * _MainTex_TexelSize.z * 0.000001);
        }      
        sum *= 1.0f/11.0f;
        half t = saturate(dist);
        return lerp(color, sum, t);
    }

    float3 RadialBlur(float2 uv,float2 center,half amount,half iterations,half radius)
    {
        fixed4 col = fixed4(0,0,0,0);
        float2 dist = uv - float2(center.x,center.y);
        for(int j = 0; j < iterations; j++) {
            float scale = 1 - amount * (j / iterations)* (saturate(length(dist) / radius));
            col += tex2D(_MainTex, dist * scale + float2(center.x,center.y));
        }
        col /= iterations;
        return col;
    }
    
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
        [KeywordEnum(BoxBlur,GaussianBlur,BilateralBlur,DirectionalBlur,RadialBlur)]_BlurType("Opeartion",float) = 0
        _MainTex ("Texture", 2D) = "grey" {}

        [Header(Box Blur)][Space(5)]
        _BlurAmount("Amount",float) = 0

        [Header(Gaussian Blur)][Space(5)]
        _Sigma("Amount",float) = 0
        _Radius("Iterations",float) = 0

        [Header(Bilateral Blur)][Space(5)]
        _SpaceSigma("Amount",float) = 0
        _RangeSigma("Iterations",float) = 0

        [Header(Directional Blur)][Space(5)]
        _Width("Amount",float) = 0

        [Header(Radial Blur)][Space(5)]         
        _Radius2("Radius",float) = 0
        _Iterations("Iterations",float) = 0
        _Amount("Amount",float) = 0
        _Center("Center",vector) = (0.5,0.5,0,0)
    }
    SubShader
    {
    Tags { "Queue"="Transparent" }
    Cull Off 
    ZWrite Off 
    //ZTest Always
    Pass
    {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma shader_feature _BLURTYPE_BOXBLUR _BLURTYPE_GAUSSIANBLUR _BLURTYPE_BILATERALBLUR _BLURTYPE_DIRECTIONALBLUR _BLURTYPE_RADIALBLUR
        
        #ifdef _BLURTYPE_BOXBLUR
        fixed4 frag (v2f i) : SV_Target
        {
            float3 col = 0;
            UNITY_UNROLL
            for(int m = -4 ; m <= 4 ; m++)
            {
                UNITY_UNROLL
                for(int n = -4; n <= 4 ; n++)
                {
                    float2 o = float2(m,n) * _MainTex_TexelSize.xy * max(0.0f,_BlurAmount);
                    col += tex2D(_MainTex,i.uv + o).xyz;
                }
            }
            col *= 1.0f/81.0f;
            return float4(col,1);
        }
        #endif

        #ifdef _BLURTYPE_GAUSSIANBLUR
        fixed4 frag(v2f i) : SV_Target
        {
            float4 blur = GaussianBlurSingle(_MainTex,_MainTex_TexelSize.xy, i.uv,max(0.1f,_Sigma),max(0.0f,floor(_Radius)));
            return float4(blur.xyz,1);
        }
        #endif

        #ifdef _BLURTYPE_BILATERALBLUR
        fixed4 frag(v2f i) : SV_Target
        {
            float3 col = BilateralBlur(i.uv,_SpaceSigma,_RangeSigma);
            return float4(col.xyz,1);
        }
        #endif

        #ifdef _BLURTYPE_DIRECTIONALBLUR
        fixed4 frag(v2f i) : SV_Target
        {
            float3 col = DirectionalBlur(i.uv,_Width);
            return float4(col.xyz,1);
        }
        #endif

        #ifdef _BLURTYPE_RADIALBLUR
        fixed4 frag(v2f i) : SV_Target
        {
            float3 col =  RadialBlur(i.uv,_Center.xy,clamp(_Amount,0.0f,2.0f),ceil(max(1.0f,_Iterations)),max(0.0f,_Radius2));
            return float4(col.xyz,1);
        }
        #endif
        ENDCG
        }
    }
}

