Shader "Custom/RayMarchTEst TGlad2 Moving" 
{
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_S ("S", float) = 3.4
		_Sc ("Sc", Vector) = (1,1,1,1)
	}
	CGINCLUDE
		#include "UnityStandardCore.cginc"
		#include "Assets/Ist/Raymarching/foundation.cginc"
		float _S;
		float3 _Sc;

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

		float DE(float3 z0)
		{
			    z0 = modc(z0, 2.0);

				float mr=0.25, mxr=1.0;
				float4 scale=float4(-1,-1,-1,1)*_S, p0=float4(_CosTime.x,1.59,-1.0,0.0);
				float4 z = float4(z0,1.0);
				for (int n = 0; n < 4; n++) {
					//z.xyz=clamp(z.xyz, -1, 1)*2.0-z.xyz;
					z.x =clamp(z.x, -_Sc.x, _Sc.x)*2 - z.x;
					z.y =clamp(z.y, -_Sc.y, _Sc.y)*2 - z.y;
					z.z =clamp(z.z, -_Sc.z, _Sc.z)*2 - z.z;
					z*=scale/clamp(dot(z.xyz,z.xyz),mr,mxr);
					z+=p0;
				}
				float dS=(length(max(abs(z.xyz)-float3(1.2,49.0,1.4),0.0))-0.06)/z.w;
				return dS;
		}

		void raymarching(float3 pos3, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos, float max)
		{
			float3 cam_pos      = GetCameraPosition();
			//float3 cam_pos = float3(_CosTime.w,20,0);//mul (_Object2World, pos3 + float3(0,10,0)).xyz;

			float3 cam_forward  = GetCameraForward();
			float3 cam_up       = GetCameraUp();
			float3 cam_right    = GetCameraRight();
			float  cam_focal_len= GetCameraFocalLength();
			
			float2 pos = pos3.xy;
			
			float3 ray_dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward);
			//float3 ray_dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward*cam_focal_len);
			//float3 ray_dir = normalize(cam_pos - pos3);
			//float3 ray_dir = normalize(cam_pos - pos3);

			o_raypos = cam_pos + ray_dir * o_total_distance;

			o_num_steps = 0.0;
			o_last_distance = 0.0;
			for(int i=0; i<=100; ++i) {
				o_last_distance = DE(o_raypos);
				o_total_distance += o_last_distance;
				o_raypos += ray_dir * o_last_distance;
				
				if(o_last_distance < 0.0005 || o_total_distance > max)
				{ 
					o_num_steps = i;
					break; 
				}
			}
			//o_total_distance = min(o_total_distance, max);
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

		struct PixelOut 
		{
			half4 Color		: COLOR;
			half Depth		: DEPTH;
			half4 normal	: SV_Target2;
		};

	ENDCG

	SubShader{
		Pass{
			Tags {"Queue"="Transparent"  "RenderType" = "Opaque" }
			ZWrite On
			Cull Off
			LOD 200

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			/*gbuffer_out frag2(vs_out I) : SV_Target{
				gbuffer_out O;
				return O;
			}*/

			/*
			void vert (inout appdata_full v) {
				v.vertex.xyz += float3(v.normal.xyz * _Dist*0.33);
			}
			*/

			PixelOut frag(vs_out v) 
			{
				PixelOut ret;
				v.spos.xy /= v.spos.w;
				//v.spos.xyz /= 10;
				float3 coord = v.spos.xyz;
				coord.x *= _ScreenParams.x / _ScreenParams.y;
				
				float max_distance = _ProjectionParams.z - _ProjectionParams.y;

				float tDist = 0;//_ProjectionParams.y;
				float numSteps;
				float lastDist = 0;
				float3 rayPos;
				//void raymarching(float2 pos, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos, max_distance)
				raymarching(coord.xyz, tDist, numSteps, lastDist, rayPos, max_distance);
				
				float r = 1-(numSteps/100);
				
				ret.Color = _Color * r *2;// _Color * (lastDist/tDist);
				
				if(numSteps >= 100 || tDist >= max_distance || numSteps <= 1)
				{
					ret.Color = float4(0,0,0,0);
				}
					
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
