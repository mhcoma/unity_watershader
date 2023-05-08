Shader "Custom/water_shader" {
	Properties {
		_NormalMap1 ("Normal Map 1", 2D) = "bump" {}
		_WavePower1 ("Wave Power 1", Range(0, 1)) = 1

		_NormalMap2 ("Normal Map 2", 2D) = "bump" {}
		_WavePower2 ("Wave Power 2", Range(0, 1)) = 1

		_WaveSpeed1 ("Wave Speed 1 & 2", Vector) = (1, 0, -1, 0)

		_NormalMap3 ("Normal Map 3", 2D) = "bump" {}
		_WavePower3 ("Wave Power 3", Range(0, 1)) = 1

		_NormalMap4 ("Normal Map 4", 2D) = "bump" {}
		_WavePower4 ("Wave Power 4", Range(0, 1)) = 1

		_WaveSpeed2 ("Wave Speed 3 & 4", Vector) = (0, 1, 0, -1)


		_ShadowRender ("Shadow Render Texture", 2D) = "black" {}
		_ReflectionRender ("Reflection Render Texture", 2D) = "black" {}
		_Color ("Color", Color) = (1, 1, 1, 1)


		_WaterFog1 ("Water Fog 1", Range(0, 1)) = 1
		_WaterFog2 ("Water Fog 2", Range(0, 1)) = 1

		_ShadowOnWater ("Shadow on Water", Range(0, 1)) = 0

		_WaterPrism ("Water Prism", Range(0, 1)) = 1
	}
	SubShader {
		Tags {
			"RenderType" = "Opaque"
		}
		LOD 200 

		GrabPass {
			"_BackgroundTexture"
		}

		CGPROGRAM
		#pragma surface surf Lambert
		#pragma target 3.0

		struct Input {
			float2 uv_NormalMap1;
			float2 uv_NormalMap2;
			float2 uv_NormalMap3;
			float2 uv_NormalMap4;
			float3 worldRefl;
			float3 viewDir;
			float4 screenPos;
			float3 worldPos;
			INTERNAL_DATA
		};

		float _WavePower1, _WavePower2, _WavePower3, _WavePower4;
		float4 _WaveSpeed1, _WaveSpeed2;
		float _WaveLerp;
		float4 _Color;

		float _WaterFog1;
		float _WaterFog2;
		float _ShadowOnWater;

		float _WaterPrism;
		
		sampler2D _NormalMap1, _NormalMap2, _NormalMap3, _NormalMap4;
		sampler2D _ShadowRender;
		sampler2D _CameraDepthTexture, _LastCameraDepthTexture, _BackgroundTexture;
		float4 _CameraDepthTexture_TexelSize;

		sampler2D _ReflectionRender;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutput o) {
			float3 n1 = UnpackNormal(tex2D(_NormalMap1,
				float2(
					IN.uv_NormalMap1.x + _Time.x * _WaveSpeed1.x,
					IN.uv_NormalMap1.y + _Time.x * _WaveSpeed1.y
				)
			));
			n1 = lerp(float3(0, 0, 1), normalize(n1), _WavePower1);

			float3 n2 = UnpackNormal(tex2D(_NormalMap2,
				float2(
					IN.uv_NormalMap2.x + _Time.x * _WaveSpeed1.z,
					IN.uv_NormalMap2.y + _Time.x * _WaveSpeed1.w
				)
			));
			n2 = lerp(float3(0, 0, 1), normalize(n2), _WavePower2);

			float3 n3 = UnpackNormal(tex2D(_NormalMap3,
				float2(
					IN.uv_NormalMap3.x + _Time.x * _WaveSpeed2.x,
					IN.uv_NormalMap3.y + _Time.x * _WaveSpeed2.y
				)
			));
			n3 = lerp(float3(0, 0, 1), normalize(n3), _WavePower3);

			float3 n4 = UnpackNormal(tex2D(_NormalMap4,
				float2(
					IN.uv_NormalMap4.x + _Time.x * _WaveSpeed2.z,
					IN.uv_NormalMap4.y + _Time.x * _WaveSpeed2.w
				)
			));
			n4 = lerp(float3(0, 0, 1), normalize(n4), _WavePower4);

			float3 n = (n1 + n2 + n3 + n4) / 4;

			float3 screen_uv = (IN.screenPos.rgb) / IN.screenPos.a;
			float2 depth_uv = screen_uv.xy;

			float3 n5th = n / 5;
			float3 n_prism = n5th * _WaterPrism;
			float2 jitter_uv = depth_uv + n5th;

			#if UNITY_UV_STARTS_AT_TOP
				if (_CameraDepthTexture_TexelSize.y < 0) {
					jitter_uv.y = 1 - jitter_uv.y;
				}
			#endif

			float background_depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, jitter_uv));
			float surface_depth = UNITY_Z_0_FAR_FROM_CLIPSPACE(IN.screenPos.z);
			float depth_difference = background_depth - surface_depth;
			float fog = 1 - saturate(depth_difference * _WaterFog1 - _WaterFog2);

			if (depth_difference < 0) {
				jitter_uv = depth_uv;
				n_prism = 0;
				background_depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, depth_uv));
				surface_depth = UNITY_Z_0_FAR_FROM_CLIPSPACE(IN.screenPos.z);
				depth_difference = background_depth - surface_depth;
				fog = 1 - saturate(depth_difference * _WaterFog1 - _WaterFog2);
			}

			float underwater_r = tex2D(
				_BackgroundTexture,
				float2(
					jitter_uv.x + n_prism.r,
					jitter_uv.y
				)
			).r;
			float underwater_g = tex2D(
				_BackgroundTexture,
				float2(
					jitter_uv.x + n_prism.r / 2,
					jitter_uv.y + n_prism.g / 2
				)
			).g;
			float underwater_b = tex2D(
				_BackgroundTexture,
				float2(
					jitter_uv.x,
					jitter_uv.y + n_prism.g
				)
			).b;

			float3 underwater = float3(underwater_r, underwater_g, underwater_b);
			float3 underwater_with_fog = lerp(_Color.rgb, underwater, fog);
			underwater = lerp(underwater, underwater_with_fog, _Color.a);
			underwater = lerp(underwater, float3(0, 0, 0), (1 - tex2D(_ShadowRender, jitter_uv)) * (_ShadowOnWater));

			float4 re = tex2D(_ReflectionRender,
				float2(
					1 - jitter_uv.x,
					jitter_uv.y
				)
			);

			float rim = pow(abs(1 - dot(IN.viewDir, n)), 3);
			o.Emission = lerp(underwater, re.rgb, rim);
			o.Alpha = 1;
			o.Albedo = 0;
			o.Normal = n;
		}
		ENDCG

		CGPROGRAM
		#pragma surface surf WaterSpecHL alpha:fade
		#pragma target 3.0

		sampler2D _NormalMap1, _NormalMap2, _NormalMap3, _NormalMap4;
		float4 _WaveSpeed1, _WaveSpeed2;

		sampler2D _ShadowRender;

		struct Input {
			float2 uv_NormalMap1;
			float2 uv_NormalMap2;
			float2 uv_NormalMap3;
			float2 uv_NormalMap4;
			float3 viewDir;
			float4 screenPos;
		};

		fixed4 _SpecCol;
		float _SpecPow;

		float _WavePower1, _WavePower2, _WavePower3, _WavePower4;

		void surf (Input IN, inout SurfaceOutput o) {
			float3 n1 = UnpackNormal(tex2D(_NormalMap1,
				float2(
					IN.uv_NormalMap1.x + _Time.x * _WaveSpeed1.x,
					IN.uv_NormalMap1.y + _Time.x * _WaveSpeed1.y
				)
			));
			n1 = lerp(float3(0, 0, 1), normalize(n1), _WavePower1);

			float3 n2 = UnpackNormal(tex2D(_NormalMap2,
				float2(
					IN.uv_NormalMap2.x + _Time.x * _WaveSpeed1.z,
					IN.uv_NormalMap2.y + _Time.x * _WaveSpeed1.w
				)
			));
			n2 = lerp(float3(0, 0, 1), normalize(n2), _WavePower2);

			float3 n3 = UnpackNormal(tex2D(_NormalMap3,
				float2(
					IN.uv_NormalMap3.x + _Time.x * _WaveSpeed2.x,
					IN.uv_NormalMap3.y + _Time.x * _WaveSpeed2.y
				)
			));
			n3 = lerp(float3(0, 0, 1), normalize(n3), _WavePower3);

			float3 n4 = UnpackNormal(tex2D(_NormalMap4,
				float2(
					IN.uv_NormalMap4.x + _Time.x * _WaveSpeed2.z,
					IN.uv_NormalMap4.y + _Time.x * _WaveSpeed2.w
				)
			));
			n4 = lerp(float3(0, 0, 1), normalize(n4), _WavePower4);

			float3 n = (n1 + n2 + n3 + n4) / 4;

			float3 screen_uv = (IN.screenPos.rgb) / IN.screenPos.a;
			o.Alpha = tex2D(_ShadowRender, screen_uv);

			o.Normal = n;
		}
		float4 LightingWaterSpecHL(SurfaceOutput s, float3 lightDir, float3 viewDir, float atten) {
			float3 halfVec = normalize(lightDir + viewDir);
			float spec = pow(saturate(dot(halfVec, s.Normal)), 200);

			float4 final;
			final.rgb = 1;
			final.a = spec * s.Alpha;

			return final;
		}

		ENDCG
	}
	FallBack "Legacy Shaders/Transparent/VertexLit"
}
