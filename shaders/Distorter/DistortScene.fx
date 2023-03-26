//-----------------------------------------------------------------------------
// Distort.fx
//
// Microsoft XNA Community Game Platform
// Copyright (C) Microsoft Corporation. All rights reserved.
//-----------------------------------------------------------------------------

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

sampler SceneTexture : register(s0);


texture DistortionMap;
sampler DistortionSampler : register(s1) = sampler_state
{
	Texture = (DistortionMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};


// This texture contains the Depth Value.
texture DepthMap;
sampler DepthSampler : register(s2) = sampler_state
{
	Texture = (DepthMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};

#define SAMPLE_COUNT 15
float2 SampleOffsets[SAMPLE_COUNT];
float SampleWeights[SAMPLE_COUNT];
bool distortionBlur;



// The Distortion map represents zero displacement as 0.5, but in an 8 bit color
// channel there is no exact value for 0.5. ZeroOffset adjusts for this error.
float ZeroOffset = 0.5f / 255.0f;


float4 MainPS(vx_v2f_img input) : COLOR0
{
    // Look up the displacement
    float2 displacement = tex2D(DistortionSampler, input.uv).rg;
    
	// Get the distortion Amount
	float Amount = tex2D(DistortionSampler, input.uv).a;
    
        //displacement -= ;
        //return Amount;

    return (displacement.x == 0) && (displacement.y == 0) ? tex2D(SceneTexture, input.uv) : tex2D(SceneTexture, input.uv + (displacement - 0.5 + 0.5 / 255.0) * Amount);
    /*
    // We need to constrain the area potentially subjected to the gaussian blur to the
    // distorted parts of the scene texture.  Therefore, we can sample for the color
    // we used to clear the distortion map (black).  We used 0 to avoid any potential
    // rounding errors.
    if ((displacement.x == 0) && (displacement.y == 0))
    {
        finalColor = tex2D(SceneTexture, TexCoord);
    }
    else
    {
        // Convert from [0,1] to [-.5, .5) 
        // .5 is excluded by adjustment for zero
        //displacement -= .5 + ZeroOffset;
        displacement -= .5 + 0.5f / 255.0f;

        if (distortionBlur == true)
        {
            // Combine a number of weighted displaced-image filter taps
            for (int i = 0; i < SAMPLE_COUNT; i++)
            {
                finalColor += tex2D(SceneTexture, TexCoord.xy + displacement * Amount +
                    SampleOffsets[i]) * SampleWeights[i];
            }
        }
        else
        {
            // Look up the displaced color, without multisampling
            finalColor = tex2D(SceneTexture, TexCoord.xy + displacement * Amount);
        }


    }
	return finalColor;
    */
}

technique Distort
{
    pass
    {
		VertexShader = compile VS_SHADERMODEL VXImageVertexShaderFunction();
        PixelShader = compile PS_SHADERMODEL MainPS();
    }
}