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


float FogNear = 25;
float FogFar = 250;
float FogHeight = 100;
float4 FogColor = 0.75f;




//Computes the Fog Factor
float ComputeFogFactor(float d, float y)
{
	float fogHeight = clamp((d - FogNear) / (FogFar - FogNear), 0, 1);
	return fogHeight * clamp((FogHeight-y) / (FogHeight - 0), 0, 1);
}


void SpriteVertexShader(inout float4 vColor : COLOR0,
	inout float2 texCoord : TEXCOORD0,
	inout float4 position : POSITION0)
{
	position = mul(position, MatrixTransform);
}

// Gets the 3D Position based on the UV and Depth Coorrdinates
float3 GetWorldPos(float2 uv, float depth)
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

float4 PixelShaderFunction(vx_v2f_img input) : COLOR0
{
	// This is the scene lit
    float4 litScene = tex2D(SceneTextureSampler, input.uv);
	
	float depth = tex2D(DepthSampler, input.uv);
	
		float3 worldPos = GetWorldPos(input.uv, depth);
		float y = worldPos.y;

		//return clamp(y / FogHeight, 0, 1);

	float z = depth;
	float n = VX_ProjectionParams.y;
	float f = VX_ProjectionParams.z;
	float dLin = n * (z + 1.0) / (f + n - z * (f - n));
	float d = dLin * f;
	float fogHeight = clamp((d - FogNear) / (FogFar - FogNear), 0, 1) * clamp((FogHeight-y) / (FogHeight - 0), 0, 1);
	
		litScene.rgb = lerp(litScene.rgb, FogColor, fogHeight);
	
	return litScene;
		float fog = ComputeFogFactor(length(worldPos - VX_CAMERA_POS), y);
		litScene.rgb = lerp(litScene.rgb, FogColor, fog);

	return litScene;
}



technique Technique_Fog
{
    pass Pass1
    {
        VertexShader = compile VS_SHADERMODEL SpriteVertexShader();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}
