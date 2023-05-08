Shader "Custom/shadow_shader" {
	Properties {
	}
	SubShader {
		Tags { "RenderType" = "Opaque" }
		LOD 200
		pass
		{
			Lighting On
			Tags { "LightMode" = "ForwardBase" }

			CGINCLUDE
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			ENDCG

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			struct v2f {
				float4 pos: SV_POSITION;
				float2 uv: TEXCOORD1;
				SHADOW_COORDS(2)
			};

			v2f vert(appdata_tan v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			float4 frag(v2f i) : COLOR {
				float atten = LIGHT_ATTENUATION(i);
				float3 color = atten;
				return float4(color, 1);
			}
			ENDCG
		}
	} 
	FallBack "Legacy Shaders/VertexLit"
}