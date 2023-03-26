/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	Pixel shader combines the bloom image with the original scene, 
		using tweakable intensity levels and saturation. This is the 
		final step in applying a bloom postprocess.
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

// Chromatic Spread Parameters
// ***********************************
float2 ChromaticSpread = 0;


// Depth Of Field Parameters
// ***********************************
bool DoDepthOfField = false;
float FarClip;
float FocalDistance;
float FocalWidth;

texture DepthMap;
sampler DepthSampler
{
	Texture = (DepthMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};

texture BlurTexture;
sampler BlurSampler
{
	Texture = (BlurTexture);

	MinFilter = Linear;
	MagFilter = Linear;

	AddressU = Clamp;
	AddressV = Clamp;
};




// Bloom Parameters
// ***********************************

float BloomQuality = 0;

float BloomIntensity;
float BaseIntensity;

float BloomSaturation;
float BaseSaturation;

texture BloomTexture;
sampler BloomSampler = sampler_state//: register(s1) = sampler_state
{
	Texture = (BloomTexture);

	MinFilter = Linear;
	MagFilter = Linear;

	AddressU = Clamp;
	AddressV = Clamp;
};



// Basic Vertex Shader
void SpriteVertexShader(inout float4 vColor : COLOR0,
	inout float2 texCoord : TEXCOORD0,
	inout float4 position : POSITION0)
{
	position = mul(position, MatrixTransform);
}




// Helper for modifying the saturation of a color.
float4 AdjustSaturation(float4 color, float saturation)
{
    // The constants 0.3, 0.59, and 0.11 are chosen because the
    // human eye is more sensitive to green light, and less to blue.
    float grey = dot(color, float3(0.3, 0.59, 0.11));

    return lerp(grey, color, saturation);
}

float GetBlurFactor(float DepthVS)
{
	//return smoothstep(0, FocalWidth, abs(FocalDistance - (DepthVS * FarClip)));
	//DepthVS = 1 - DepthVS;
	float fSceneZ = -FarClip / (DepthVS * FarClip - FarClip);
	return  saturate(abs(fSceneZ - FocalDistance) / FocalWidth);
}




float4 PixelShaderFunction(float2 texCoord : TEXCOORD0) : COLOR0
{
    // Look up the bloom and original base image colors.
    float4 bloom = tex2D(BloomSampler, texCoord);
    float4 base = tex2D(SceneSampler, texCoord);
	
	float4 output = base;


	// Apply a Chromatic Blend
	// ****************************************
	base.r = tex2D(SceneSampler, texCoord + ChromaticSpread).r * (1 + 10*ChromaticSpread.x);

	base.b = tex2D(SceneSampler, texCoord - ChromaticSpread).b * (1 + 10 *ChromaticSpread.x);
    



    // Adjust color saturation and intensity for Bloom.
	// ****************************************
	if (BloomQuality > 0)
	{
		bloom = AdjustSaturation(bloom, BloomSaturation) * BloomIntensity;
		base = AdjustSaturation(base, BaseSaturation) * BaseIntensity;

		// Darken down the base image in areas where there is a lot of bloom,
		// to prevent things looking excessively burned-out.
		base *= (1 - saturate(bloom));

		output = base + bloom;
	}

	// Handle Depth of Field
	// ****************************************
	if (DoDepthOfField == true)
	{
		float depthVal = tex2D(DepthSampler, texCoord).r;
		float4 blur = tex2D(BlurSampler, texCoord);

		float blurFactor = GetBlurFactor(depthVal);

		output = lerp(output, blur, blurFactor);
	}

    // Combine the two images.
    return output;
}


technique BloomCombine
{
    pass Pass1
    {
		VertexShader = compile VS_SHADERMODEL SpriteVertexShader();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}
