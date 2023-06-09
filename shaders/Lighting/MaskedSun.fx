
#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"


texture2D Texture;
sampler TextureSampler : register(s0) = sampler_state
{
	texture = <Texture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = wrap;
	AddressV = wrap;
};

texture2D DepthMap;
sampler DepthMapSampler : register(s1) = sampler_state
{
	texture = <DepthMap>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};


void SpriteVertexShader(inout float4 vColor : COLOR0,
	inout float2 texCoord : TEXCOORD0,
	inout float4 position : POSITION0)
{
	position = mul(position, MatrixTransform);
}

float4 PixelShaderFunction(float2 texCoord : TEXCOORD0) : COLOR0
{
    return tex2D(DepthMapSampler, texCoord).r > 0 ? float4 (0, 0, 0, 1) : tex2D(TextureSampler, texCoord);
}

technique Technique1
{
    pass Pass1
    {
		VertexShader = compile VS_SHADERMODEL SpriteVertexShader();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}
