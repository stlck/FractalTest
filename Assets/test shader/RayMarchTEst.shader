Shader "Custom/RayMarchTEst" 
{

	CGINCLUDE
		#include "UnityStandardCore.cginc"
		#include "Assets/Ist/Raymarching/foundation.cginc"
		
		struct ia_out
		{
			float4 vertex : POSITION;
		};

		struct vs_out
		{
			float4 vertex : SV_POSITION;
			float4 spos : TEXCOORD0;
		};

		struct gbuffer_out
		{
			half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
			half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
			half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
			half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
			float depth : SV_Depth;
		};

		float DE(float3 z)
		{
			/*float dS = (length(max(abs(z.xyz) - float3(1.2, 49.0, 1.4), 0.0)) - 0.06) / z.w;
			return dS;*/
			float Scale = 2;
			float Offset = 1;
			int Iterations = 5;
			float r;
			int n = 0;
			while (n < Iterations) {
				if (z.x + z.y<0) z.xy = -z.yx; // fold 1
				if (z.x + z.z<0) z.xz = -z.zx; // fold 2
				if (z.y + z.z<0) z.zy = -z.yz; // fold 3	
				z = z*Scale - Offset*(Scale - 1.0);
				n++;
			}
			return (length(z)) * pow(Scale, -float(n));
		}

		float3 guess_normal(float3 p)
		{
			const float d = 0.001;
			return normalize(float3(
				DE(p + float3(d, 0.0, 0.0)) - DE(p + float3(-d, 0.0, 0.0)),
				DE(p + float3(0.0, d, 0.0)) - DE(p + float3(0.0, -d, 0.0)),
				DE(p + float3(0.0, 0.0, d)) - DE(p + float3(0.0, 0.0, -d))));
		}

		float MaximumRaySteps = 100;
		float MinimumDistance = 1;

		float trace(float3 from, float3 direction) {

			float totalDistance = 0.0;
			int steps;

			for (steps = 0; steps < MaximumRaySteps; steps++) {
				float3 p = from + totalDistance * direction;
				float distance = DE(p);
				totalDistance += distance;
				if (distance < MinimumDistance) break;
			}
			
			return 1.0 - float(steps) / float(MaximumRaySteps);
		}

		float rayMarch(float3 pos)
		{
			float3 cam_pos = GetCameraPosition();
			float3 cam_forward = GetCameraForward();
			float3 cam_up = GetCameraUp();
			float3 cam_right = GetCameraRight();
			float  cam_focal_len = GetCameraFocalLength();

			float3 dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward*cam_focal_len);

			return trace(pos, dir);
		}


	ENDCG

	SubShader{
		Pass{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			/*gbuffer_out frag2(vs_out I) : SV_Target{
				gbuffer_out O;
				return O;
			}*/

			float4 frag(float4 v:VPOS) : SV_Target
			{
				float r = rayMarch(v.xyz);

				return float4(r,r,r,1);
			}

			vs_out vert(ia_out I)
			{
				vs_out O;
				O.vertex = mul(UNITY_MATRIX_MVP, I.vertex);
				O.spos = O.vertex;
				return O;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
