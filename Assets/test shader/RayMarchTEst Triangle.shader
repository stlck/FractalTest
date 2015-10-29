Shader "Custom/RayMarchTEst Triangle" {
Properties {
		_Color ("Color", Color) = (1,1,1,1)
	}
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
			float Scale = 2;
			float Offset = 10;
			int Iterations = 20;
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

		void raymarching(float3 pos3, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
		{
			float3 cam_pos      = GetCameraPosition();

			float3 cam_forward  =  GetCameraForward();
			float3 cam_up       = GetCameraUp();
			float3 cam_right    = GetCameraRight();
			float  cam_focal_len= GetCameraFocalLength();
			
			float2 pos = pos3.xy;
			float3 ray_dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward);

			float max_distance = _ProjectionParams.z - _ProjectionParams.y;
			o_raypos = cam_pos + ray_dir * o_total_distance;

			o_num_steps = 0.0;
			o_last_distance = 0.0;
			for(int i=0; i<50; ++i) {
				o_last_distance = DE(o_raypos);
				o_total_distance += o_last_distance;
				o_raypos += ray_dir * o_last_distance;
				
				if(o_last_distance < 0.001 )//|| o_total_distance > max_distance)
				{ 
					o_num_steps = i;
					break; 
				}
			}
			o_total_distance = min(o_total_distance, max_distance);
			//if(o_total_distance > max_distance) { discard; }
		}

		float3 guess_normal(float3 p)
		{
			const float d = 0.001;
			return normalize(float3(
				DE(p + float3(d, 0.0, 0.0)) - DE(p + float3(-d, 0.0, 0.0)),
				DE(p + float3(0.0, d, 0.0)) - DE(p + float3(0.0, -d, 0.0)),
				DE(p + float3(0.0, 0.0, d)) - DE(p + float3(0.0, 0.0, -d))));
		}

		float MaximumRaySteps = 20;
		float MinimumDistance = 1;

		float trace(float3 from, float3 direction) {

			float totalDistance = 0.0;
			int steps;

			//for (steps = 0; steps < MaximumRaySteps; steps++) 
			while(steps < MaximumRaySteps)
			{
				steps++;
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
		struct PixelOut 
		{
			half4 Color		: COLOR;
			half Depth		: DEPTH;
			half4 normal	: SV_Target2;
		};

	ENDCG

	SubShader{
		Pass{
			Tags {"Queue"="Transparent"  "RenderType" = "Transparent" }
			ZWrite On
			Cull Off
			LOD 200

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			PixelOut frag(vs_out v) 
			{
				PixelOut ret;
				v.spos.xy /= v.spos.w;
				float3 coord = v.spos.xyz;
				//coord.x *= _ScreenParams.x / _ScreenParams.y;

				float tDist = _ProjectionParams.y;
				float numSteps;
				float lastDist = 0;
				float3 rayPos;
				//void raymarching(float2 pos, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
				raymarching(coord.xyz, tDist, numSteps, lastDist, rayPos);
				
				float r = (numSteps/100);
				
				ret.Color = _Color * r;// _Color * (lastDist/tDist);
				if(numSteps == 50)
					ret.Color.a = 0;
					
				ret.normal = half4(guess_normal(rayPos),1);
				ret.Depth =  ComputeDepth(mul(UNITY_MATRIX_VP, float4(rayPos, 1.0)));
				
				return ret;
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
