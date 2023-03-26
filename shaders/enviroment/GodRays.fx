/*
@Title: God Rays - Vertices Engine
@autor: Robert Roe
@brief:	This shader applies a godrays effect to an already masked out image
*/

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

texture SceneTexture;
sampler SceneSampler : register(s0) = sampler_state
{
    Texture = (SceneTexture);
    
    MinFilter = Linear;
    MagFilter = Linear;
    
    AddressU = Clamp;
    AddressV = Clamp;
};

// This texture contains the Depth Value.
texture DepthMap;
sampler DepthSampler : register(s1) = sampler_state
{
	Texture = (DepthMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};


// This is the Sun Mask Texture which holds the masked image of the sun.
texture2D SunMaskTexture;
sampler SunMaskSampler = sampler_state
{
	Texture = <SunMaskTexture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = wrap;
	AddressV = wrap;
};

// This is the Sun Texture which holds the image of the sun.
texture2D SunTexture;
sampler SunSampler = sampler_state
{
	Texture = <SunTexture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = clamp;
	AddressV = clamp;
};


// God Rays
// ****************************************************************************

#define NUM_SAMPLES 25

float2 lightScreenPosition;
float2 TextureScale = float2(4, 4);
float2 TextureSize = float2(1, 1);

float Density = .5f;
float Decay = .95f;
float Weight = 1.0f;
float Exposure = .15f;


// God Ray Mask Generation
// ****************************************************************************

float4 PS_GenerateSun(vx_v2f_img input) : COLOR0
{
	float2 texCoord = (input.uv - lightScreenPosition + TextureSize) * TextureScale;
	return tex2D(DepthSampler, input.uv).r > 0 ? float4 (0, 0, 0, 1) : 0;
}

technique GenerateSunMaskTechnique
{
	pass Pass1
	{
		VertexShader = compile VS_SHADERMODEL VXImageVertexShaderFunction();
		PixelShader = compile PS_SHADERMODEL PS_GenerateSun();
	}
}



float4 PS_ApplyGodRays(vx_v2f_img input) : COLOR0
{
	float4 SunColor = tex2D(SunMaskSampler, input.uv);

	// return SunColor;
	// Look up the bloom and original base image colors.
	//float4 base = tex2D(TextureSampler, texCoord);
	//float3 col = tex2D(TextureSampler, texCoord);
	float IlluminationDecay = 0.75f;
	float3 Sample;
	float2 texCoord = input.uv - HalfPixel;
	float2 DeltaTexCoord = (texCoord - lightScreenPosition) * (1.0f / (NUM_SAMPLES) * Density);
	for (int i = 0; i < NUM_SAMPLES; ++i)
	{
		texCoord -= DeltaTexCoord;
		Sample = tex2D(SunMaskSampler, texCoord);
		Sample *= IlluminationDecay * Weight;
		SunColor.rgb += Sample;
		IlluminationDecay *= Decay;
	}
	return lerp(tex2D(SceneSampler, input.uv), float4(SunColor.rgb, SunColor.r), saturate(SunColor.r));
}



technique Technique_ApplyEffect
{
	// Apply God Rays
	pass Pass1
	{
		VertexShader = compile VS_SHADERMODEL VXImageVertexShaderFunction();
		PixelShader = compile PS_SHADERMODEL PS_ApplyGodRays();
	}
}
