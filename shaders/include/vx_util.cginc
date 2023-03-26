/*
@Title: Vertices Engine - Utility Shader Functions
@autor: Robert Roe
@brief:	This holds the basic utility functions for Vertices Engine shaders
*/

#ifndef VX_UTILS
#define VX_UTILS

#include "vx_core.cginc"


float3 GetNormalFromMap(sampler normalSampler, vx_v2f_full input)
{
	float3 normalFromMap = input.tangentToWorld[2];
	//Thirdly, get the Normal from both the Gemoetry and any supplied Normal Maps.
	//*********************************************************************************************
	// read the normal from the normal map
	normalFromMap = tex2D(normalSampler, input.uv);
	//tranform to [-1,1]
	normalFromMap = 2.0f * normalFromMap - 1.0f;
	//transform into world space
	normalFromMap = mul(normalFromMap, input.tangentToWorld);

	return normalFromMap;
}

// Gets the 3D Position based on the UV and Depth Coorrdinates
float3 GetWorldPosition(float2 uv, float depth)
{
	float4 pos = 1.0f;

	// Convert the UV values.
	pos.x = (uv.x * 2.0f - 1.0f);
	pos.y = -(uv.y * 2.0f - 1.0f);

	pos.z = depth;

	//Transform Position from Homogenous Space to World Space 
	pos = mul(pos, VX_CAMERA_INV_VP);

	pos /= pos.w;

	return pos.xyz;
}

float GetLinearisedDepth(float depth)
{
	float z = depth;
	float n = VX_ProjectionParams.y;
	float f = VX_ProjectionParams.z;
	float dLin = n * (z + 1.0) / (f + n - z * (f - n));
	float d = dLin * f;
	return d;
}


inline float4 ComputeScreenPos (float4 pos) {
    float4 o = pos * 0.5f;
    #if defined(UNITY_HALF_TEXEL_OFFSET)
    o.xy = float2(o.x, o.y*-1) + o.w;// * _ScreenParams.zw;
    #else
    o.xy = float2(o.x, o.y*-1) + o.w;
    #endif
 
    o.zw = pos.zw;
    return o;
}

inline float4 GetTestColour()
{
	#ifdef VX_TEST_DEF
	return float4(1,0,0,1);
	#else
	return float4(0,1,0,1);
	#endif
}

inline void CheckAlphaMask(float2 uv)
{
	float noise = tex2D(AlphaMaskSampler, uv).r;
	clip(noise - AlphaMaskCutoff);
}

float3 rgb2grayscale(float3 c)
{
	float g = dot(c, float3(0.2126, 0.7152, 0.0722));
	return float3(g,g,g);
}

float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


/*
	This will return the emissive colour in the RGB along with the emission factor in the alpha channel.
*/
float4 GetEmissiveTexture(float2 uv)
{
	// first we'll sample the emissive sampler
	float4 emsvMap = tex2D(emissiveSampler, uv);
	
	// next we'll add up each component and saturate it as the emissive factor
	float emsvFactor = saturate(emsvMap.r + emsvMap.g + emsvMap.b);

	return saturate(float4(emsvMap.r * EmissiveColour.r, emsvMap.g * EmissiveColour.g, emsvMap.b * EmissiveColour.b, emsvFactor * EmissiveIntensity));
}

#endif