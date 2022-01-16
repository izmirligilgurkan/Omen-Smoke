Shader "Gurkan Shaders/Smoke" {
     Properties {
          _ColorOut ("Color Out", Color) = (0.38, 0.38, 0.7, 1)
          _ColorIn ("Color In", Color) = (0.17, 0.16, 0.31, 1)
          _NoiseColor ("Noise Color", Color) = (0.28, 0.3, 0.52, .4)
          _OutlineColor ("Outline Color", Color) = (0.69, 0.53, 1, .5)
          _OutlineSize ("Outline Thickness", Float) = 0.02

     }
     SubShader {
     
     Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
     LOD 100

     // render outline

     Pass {
          Blend SrcAlpha OneMinusSrcAlpha                 

          Stencil {
          Ref 1
          Comp NotEqual
          }

          Cull Off
          ZWrite Off

          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag

          #include "UnityCG.cginc"

          half _OutlineSize;
          fixed4 _OutlineColor;
          
          struct v2f {
               float4 pos : SV_POSITION;
          };

          v2f vert (appdata_base v) {
               v2f o;
               v.vertex.xyz += v.normal * (_OutlineSize);
               o.pos = UnityObjectToClipPos (v.vertex);
               return o;
          }

          half4 frag (v2f i) : SV_Target
          {
               return _OutlineColor;
          }

          ENDCG
     }



     //render model
     Pass
          {
          Cull Off
          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag

          #include "UnityCG.cginc"

          struct v2f
          {
               float4 vertex : SV_POSITION;
               float value : TEXCOORD0;
               float4 objPos : TEXCOORD1;
          };

          fixed4 _ColorOut;
          fixed4 _ColorIn;

          v2f vert (appdata_base v)
          {
               v2f o;
               o.vertex = UnityObjectToClipPos(v.vertex);
               o.value = dot(UnityObjectToWorldNormal(v.normal), normalize(WorldSpaceViewDir(v.vertex)));
               o.objPos = v.vertex;
               return o;
          }

          fixed4 frag (v2f i) : SV_Target
          {
               float y = smoothstep(0, .4, abs(i.objPos.y));
               float v = smoothstep((sin(_Time.w) * .1 + .1), .75, i.value);
               return lerp(_ColorIn, _ColorOut, v * y);
          }
          ENDCG

     }


     // render outer outline

     Pass {
          Blend SrcAlpha OneMinusSrcAlpha                 

          Stencil {
          Ref 1
          Comp NotEqual
          }

          ZWrite Off
          Cull Off
          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag
          #define vec2 float2
          #define fract frac
          #define mix lerp
          #define mat2 float2x2
          #include "UnityCG.cginc"

          fixed4 _NoiseColor;
          // 2D Random
          float random (in vec2 st) {
               return fract(sin(dot(st.xy,
                    vec2(12.9898,78.233)))
               * 43758.5453123);
          }

          // 2D Noise based on Morgan McGuire @morgan3d
          // https://www.shadertoy.com/view/4dS3Wd
          float noise (in vec2 st) {
               vec2 i = floor(st);
               vec2 f = fract(st);

               // Four corners in 2D of a tile
               float a = random(i);
               float b = random(i + vec2(1.0, 0.0));
               float c = random(i + vec2(0.0, 1.0));
               float d = random(i + vec2(1.0, 1.0));

               // Smooth Interpolation

               // Cubic Hermine Curve.  Same as SmoothStep()
               vec2 u = f*f*(3.0-2.0*f);
               u = smoothstep(0.,1.,f);

               // Mix 4 coorners percentages
               return mix(a, b, u.x) +
               (c - a)* u.y * (1.0 - u.x) +
               (d - b) * u.x * u.y;
          }
          
          mat2 rotate2d(float angle){
               return mat2(cos(angle),-sin(angle),
               sin(angle),cos(angle));
          }
          //2D Line noise
          //Source: https://thebookofshaders.com/11/
          float lines(in vec2 pos, float b){
               const float scale = 10.0;
               pos *= scale;
               return smoothstep(0.0,.5+b*.5,abs((sin(pos.x*3.1415)-b*2.0))*.5);
          }
          
          struct v2f {
               float4 pos : SV_POSITION;
               float2 uv : TEXCOORD0;
               float4 objPos : TEXCOORD1;
          };

          v2f vert (appdata_base v) {
               v2f o;
               o.uv = v.texcoord;
               o.objPos = v.vertex;
               o.pos = UnityObjectToClipPos (v.vertex);
               return o;
          }

         
          half4 frag (v2f i) : SV_Target
          {
               i.objPos.xz = mul(i.objPos.xz, rotate2d(_Time.w));
               vec2 pos = i.objPos.yz*vec2(5,2);
               vec2 pos2 = i.objPos.yz*vec2(5,2);
               float pattern = pos.x;
               float pattern2 = pos2.x;
               float pattern3 = pos2.x;

               // Add noise
               pos = mul(rotate2d( noise(pos+ _Time.x * .1)), pos);
               pos2 = mul(rotate2d( noise(pos2 + _Time.x * .1)), pos2);

               // Draw lines
               pattern = lines(i.uv.yx * 2,.3);
               pattern2 = lines(pos * .2,.5);
               pattern3 = lines((pos2 - mul(rotate2d(1), pos2)) * .2, .5);
               fixed4 tex = pattern - (pattern3 - pattern2) * .5;;
               if(tex.r < 0.1) discard;
               tex = smoothstep(.01, .05, tex);
               tex = 1 - tex;
               fixed4 col = tex * _NoiseColor;
               col.a = _NoiseColor.a * .1;
               return col;
          }

          ENDCG
     }


     }
     //FallBack "Diffuse" //Uncomment this if you want shadows.

     }
