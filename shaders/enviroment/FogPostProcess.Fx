/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	This shader applies a screenspace fog post process to the scene
*/

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"


sampler SceneTextureSampler : register(s0);

// This texture contains the Depth Value.
texture DepthMap;
sampler DepthSampler : register(s1) = sampler_state
{
	Texture = (DepthMap);

	MinFilter = Point;
	MagFilter = Point;

	AddressU = Clamp;
	AddressV = Clamp;
};

texture EmissiveMapTexture;
sampler EmissiveMapSampler = sampler_state//: register(s1) = sampler_state
{
	Texture = (EmissiveMapTexture);
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

texture HeightMapTexture;
sampler HeightMapSampler = sampler_state//: register(s1) = sampler_state
{
	Texture = (HeightMapTexture);
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

float FogNear = 25;
float FogFar = 250;
float FogHeight = 100;
float FogHeightDepth = 10;

float FogHeightNear = 25;
float FogHeightFar = 250;

float4 FogColor = 0.75f;
float4 FogHeightColor = 0.75f;
float isFogDepthEnabled = 0;
float2 FogWindSpeed = 0;
float FogHeightMapFactor = 1;
//Computes the Fog Factor
float ComputeFogFactor(float d, float y)
{
	float fogHeight = clamp((d - FogNear) / (FogFar - FogNear), 0, 1);
	return fogHeight * clamp((FogHeight-y) / (FogHeight - 0), 0, 1);
}


float4 PixelShaderFunction(vx_v2f_img input) : COLOR0
{
	// This is the scene lit
    float4 litScene = tex2D(SceneTextureSampler, input.uv);
	
	float depth = (tex2D(DepthSampler, input.uv));
    float e = tex2D(EmissiveMapSampler, input.uv).g;// + diffuseLight + specularLight;  
	float d = GetLinearisedDepth(depth);

	float heightFactorDepthFactor = clamp((d - FogHeightNear) / (FogHeightFar - FogHeightNear), 0, 1);
	float heightMapFactor = FogHeightMapFactor;
	if(depth < 0.0001)
	{
		depth = 1;
		d=1;
		heightFactorDepthFactor = 1;
		heightMapFactor=0;
	}

	// get the world position
	float3 wp = GetWorldPosition(input.uv, depth);
	
	// we need to use all 3 components of the worldPos or the compiler will simplify it down 
	// and break the worldPos calculation for some reason :/ 
	float heightMap = tex2D(HeightMapSampler, FogWindSpeed + float2(wp.x, wp.z)/(FogHeightDepth*3)).r * heightMapFactor;
	
	float heightFactor = 1 - (clamp(((wp.y + length(heightMap)*FogHeightDepth/2 + FogHeightDepth * ( 1 + e/2)) - FogHeight) / (FogHeightDepth), 0, 1));

	float fogDepthFactor = clamp((d - FogNear) / (FogFar - FogNear), 0, 1);
	float fogTotalFactor = saturate((fogDepthFactor + heightFactor * heightFactorDepthFactor * isFogDepthEnabled));
	
	litScene.rgb = lerp(litScene.rgb, FogColor, fogTotalFactor);

	return litScene;
}



technique Technique_Fog
{
    pass Pass1
    {
        //VertexShader = compile VS_SHADERMODEL SpriteVertexShader();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}
