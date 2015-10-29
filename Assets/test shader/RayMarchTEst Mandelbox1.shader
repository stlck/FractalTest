Shader "Custom/RayMarchTEst Mandel1" 
{
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_S ("S", float) = 0
		_Scale ("Scale", Vector) = (1,1,1,1)
	}
	CGINCLUDE
		#include "UnityStandardCore.cginc"
		#include "Assets/Ist/Raymarching/foundation.cginc"
		float _S;
		float3 _Scale;

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

		void boxFold2(inout float3 z, inout float dz) {
			float foldingLimit = 1;
			z = clamp(z, -foldingLimit, foldingLimit) * 2.0 - z;
		}

		void sphereFold(inout float3 z, inout float dz) {
			float r2 = dot(z, z);
			float minRadius2 = 0.4;
			float fixedRadius2 = .8;

			if (r2 < minRadius2) {
				// linear inner scaling
				float temp = (fixedRadius2 / minRadius2);
				z *= temp;
				dz *= temp;
			}
			else if (r2 < fixedRadius2) {
				// this is the actual sphere inversion
				float temp = (fixedRadius2 / r2);
				z *= temp;
				dz *= temp;
			}
		}


		float DE(float3 z)
		{
			float3 offset = z ;
			float Scale = _S;
			float dr = 1.0;
			float Iterations = 20;
	
			for (int n = 0; n < Iterations; n++) {
				//z += .123;
				boxFold2(z, dr);       // Reflect
				sphereFold(z, dr);    // Sphere Inversion
				z = Scale*z + offset;  // Scale & Translate
				dr = dr*abs(Scale) + 1.0;
			}
			float r = length(z);
			//return dot(z,z) / length(z*dr);
			//return .5 * r * log(r)/abs(dr);
			return r / abs(dr);
		}

		void raymarching(float3 pos3, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
		{
			float3 cam_pos      = GetCameraPosition();
			//float3 cam_pos = float3(_CosTime.w,20,0);//mul (_Object2World, pos3 + float3(0,10,0)).xyz;

			float3 cam_forward  = float3(0,-1,0);//GetCameraForward();
			float3 cam_up       = float3(0,0,1);//GetCameraUp();
			float3 cam_right    = float3(1,0,0);//GetCameraRight();
			float  cam_focal_len= GetCameraFocalLength();
			
			float2 pos = pos3.xy;
			
			float3 ray_dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward);
			//float3 ray_dir = normalize(cam_right*pos.x + cam_up*pos.y + cam_forward*cam_focal_len);
			//float3 ray_dir = normalize(cam_pos - pos3);
			//float3 ray_dir = normalize(cam_pos - pos3);

			float max_distance = _ProjectionParams.z - _ProjectionParams.y;
			o_raypos = cam_pos + ray_dir * o_total_distance;

			o_num_steps = 0.0;
			o_last_distance = 0.0;
			for(int i=0; i<=100; ++i) {
				o_last_distance = DE(o_raypos);
				o_total_distance += o_last_distance;
				o_raypos += ray_dir * o_last_distance;
				
				if(o_last_distance < 0.0001 )//|| o_total_distance > max_distance)
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
				v.spos.xyz /= _Scale;
				float3 coord = v.spos.xyz;
				coord.x *= _ScreenParams.x / _ScreenParams.y;

				float tDist = _ProjectionParams.y;
				float numSteps;
				float lastDist = 0;
				float3 rayPos;
				//void raymarching(float2 pos, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
				raymarching(coord.xyz, tDist, numSteps, lastDist, rayPos);
				
				float r = (numSteps/100);
				
				ret.Color = _Color * r;// _Color * (lastDist/tDist);
				if(numSteps >= 100)
				{
					ret.Color = float4(1,0,0,0);
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
