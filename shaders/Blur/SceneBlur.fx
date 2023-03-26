/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	Scene blur effect
*/

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

sampler SceneTexture : register(s0);

#define SAMPLE_COUNT 15

float2 SampleOffsets[SAMPLE_COUNT];
float SampleWeights[SAMPLE_COUNT];



float4 MainPS(vx_v2f_img input) : COLOR0
{
    float4 c = 0;
    
    // Combine a number of weighted image filter taps.
    for (int i = 0; i < SAMPLE_COUNT; i++)
    {
        c += tex2D(SceneTexture, input.uv + SampleOffsets[i]/2) * SampleWeights[i];
    }
    
    return c;
}

technique SceneBlur
{
    pass
    {
		VertexShader = compile VS_SHADERMODEL VXImageVertexShaderFunction();
        PixelShader = compile PS_SHADERMODEL MainPS();
    }
}