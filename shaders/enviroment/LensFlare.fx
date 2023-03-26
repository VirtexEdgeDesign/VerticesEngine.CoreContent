/*
@Title: God Rays - Vertices Engine
@autor: Robert Roe
@brief:	This shader applies a godrays effect to an already masked out image
*/
#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_4_0_level_9_1
	#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

// #include "../include/vx_core.cginc"
// #include "../include/vx_util.cginc"


sampler SceneTextureSampler : register(s0);

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


float2 lightScreenPosition;
float4x4 MatrixTransform;
float2 HalfPixel;

void SpriteVertexShader(inout float4 vColor : COLOR0,
	inout float2 texCoord : TEXCOORD0,
	inout float4 position : POSITION0)
{
	position = mul(position, MatrixTransform);
}

float4 PixelShaderFunction(float4 vColor : COLOR0, float2 texCoord : TEXCOORD0) : COLOR0
{
    
    //return float4(texCoord.x, texCoord.y, 0, 1);
    float4 colour = tex2D(SceneTextureSampler, texCoord)  * vColor;

    float factor = 0;

    // create an average of the 
    int size = 4;
    int step = 2;
    int count = 0;
    for(int i = -size/2; i < size /2; i+= step){
        for(int j = -size/2; j < size /2; j+= step){
            factor = factor + tex2D(DepthSampler, lightScreenPosition + 2 * HalfPixel * float2(i, j));
            count ++;
        }
    }
    factor = factor / (count);

    return colour * (1 - factor);
    
	return tex2D(DepthSampler, lightScreenPosition + HalfPixel).r > 0 ? 0 : colour;
}

technique Technique_LensFlare
{
	pass Pass1
	{
		VertexShader = compile VS_SHADERMODEL SpriteVertexShader();
		PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
	}
}

