// #if OPENGL
// 	#define SV_POSITION POSITION
// 	#define VS_SHADERMODEL vs_3_0
// 	#define PS_SHADERMODEL ps_3_0
// #else
// 	#define VS_SHADERMODEL vs_4_0_level_9_1
// 	#define PS_SHADERMODEL ps_4_0_level_9_1
// #endif

// float4x4 MatrixTransform;
// float2 HalfPixel;


#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

#define SAMPLE_COUNT 16


float3 RAND_SAMPLES[SAMPLE_COUNT] = 
{
      float3( 0.5381, 0.1856,-0.4319), 
	  float3( 0.1379, 0.2486, 0.4430),
      float3( 0.3371, 0.5679,-0.0057), 
	  float3(-0.6999,-0.0451,-0.0019),
      float3( 0.0689,-0.1598,-0.8547), 
	  float3( 0.0560, 0.0069,-0.1843),
      float3(-0.0146, 0.1402, 0.0762), 
	  float3( 0.0100,-0.1924,-0.0344),
      float3(-0.3577,-0.5301,-0.4358), 
	  float3(-0.3169, 0.1063, 0.0158),
      float3( 0.0103,-0.5869, 0.0046), 
	  float3(-0.0897,-0.4940, 0.3287),
      float3( 0.7119,-0.0154,-0.0918), 
	  float3(-0.0533, 0.0596,-0.5411),
      float3( 0.0352,-0.0631, 0.5460), 
	  float3(-0.4776, 0.2847,-0.0271)
  };
	
// The inverse View Projection
//float4x4 InverseViewProjection;

matrix ViewProjection;

matrix PrevViewProjection;
float2 BlurLength = float2(2,2);
float BlurFactor = 2;
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


texture MaskTexture;
sampler MaskSampler : register(s2) = sampler_state
{
	Texture = (MaskTexture);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	Mipfilter = LINEAR;
};


// Gets the 3D Position based on the UV and Depth Coorrdinates
// float3 GetWorldPosition(float2 uv, float depth)
// {
// 	float4 pos = 1.0f;

// 	// Convert the UV values.
// 	pos.x = (uv.x * 2.0f - 1.0f);
// 	pos.y = -(uv.y * 2.0f - 1.0f);

// 	pos.z = depth;

// 	//Transform Position from Homogenous Space to World Space 
// 	pos = mul(pos, InverseViewProjection);

// 	pos /= pos.w;

// 	return pos.xyz;
// }


// Converts a World Position into UV coordinates with a depth value.
float3 GetUVFromPosition(float3 position)
{
	// Convert Position into View Space
	float4 UVpos = mul(float4(position, 1.0f), ViewProjection);

	// Now convert the UVpos
	UVpos.xy = float2(0.5f, 0.5f) + float2(0.5f, -0.5f) * UVpos.xy / UVpos.w;

	// return the UV pos with the depth value at that location
	return float3(UVpos.xy, UVpos.z / UVpos.w);
}

// Returns the depth, given a UV texture coordinate
float GetDepth(float2 texCoord)
{
	return tex2Dlod(DepthSampler, float4(texCoord.xy, 0, 0)).r;
}
float GetMask(float2 texCoord)
{
	return tex2Dlod(MaskSampler, float4(texCoord, 0, 0)).g;
}

void SpriteVertexShader(inout float4 vColor : COLOR0,
	inout float2 texCoord : TEXCOORD0,
	inout float4 position : POSITION0)
{
	position = mul(position, MatrixTransform);
}

float4 PixelShaderFunction(float2 texCoord : TEXCOORD0) : COLOR0
{
	// Get the Current Colour
	float4 currentColor = tex2D(SceneTextureSampler, texCoord);

	// Get the mask value
	float mask = GetMask(texCoord);
	
	//Get initial Depth and 3d position
	float depth = GetDepth(texCoord);

	if(mask > 0 || depth == 0)
	{
		return currentColor;
	}

	//depth = depth > 0 ? depth : 1;
	//if(depth==0)
	//	return 1;
	//clip(depth-0.99);
	// Get the Initial World Position
	float3 position = GetWorldPosition(texCoord, depth);
	//return float4(position, 1);

	// Now find the UV Position of that World Position from the last Frame
	// Convert Position into View Space
	float4 UVpos = mul(float4(position, 1.0f), PrevViewProjection);

	// Now convert the UVpos
	UVpos.xy = float2(0.5f, 0.5f) + float2(0.5f, -0.5f) * UVpos.xy / UVpos.w;
	
	// return the UV pos with the depth value at that location
	float3 prevUVDepth = float3(UVpos.xy, UVpos.z / UVpos.w);
		
		//if (texCoord.y <= 0 || texCoord.x <= 0 || texCoord.y >= 1 || texCoord.x >= 1)
		//	return float4(1,0,0,1);
		//if (prevUVDepth.y <= 0 || prevUVDepth.x <= 0 || prevUVDepth.y >= 1 || prevUVDepth.x >= 1)
			//return float4(0,1,0,1);

	float2 midDelta = (texCoord-prevUVDepth.xy) * 2.5f;
	float4 prevColor = tex2D(SceneTextureSampler, texCoord + midDelta);

	float4 BlurredColor = currentColor;
	for (int i = 0; i < SAMPLE_COUNT; i++)
	{
		float2 txcrd = texCoord - length(RAND_SAMPLES[i].xy) * midDelta * BlurFactor;
		//txcrd.x = clamp(txcrd.x, 0, 1);
		//txcrd.y = clamp(txcrd.y, 0, 1);
		if (txcrd.y <= 0 || txcrd.x <= 0 || txcrd.y >= 1 || txcrd.x >= 1)
			txcrd = texCoord - length(RAND_SAMPLES[i].xy) * midDelta * 0.1f ;

		BlurredColor += lerp(tex2D(SceneTextureSampler, txcrd), currentColor, GetMask(txcrd));

		//if (txcrd.y <= 0 || txcrd.x <= 0 || txcrd.y >= 1 || txcrd.x >= 1)
		//	return float4(1,0,0,1);
	}

	BlurredColor /= (SAMPLE_COUNT + 1);
	return BlurredColor;

	float4 prevMidColor = tex2D(SceneTextureSampler, texCoord + midDelta/3);
	float4 prevMidColor2 = tex2D(SceneTextureSampler, texCoord + midDelta*2/3);

	// Now get the Colour from this frame and the next frame
	float4 FinalColor = (currentColor + prevMidColor + prevMidColor2 + prevColor)/4;
	return FinalColor;
}

technique Technique_CameraMotionBlur
{
	pass P0
	{
		//VertexShader = compile VS_SHADERMODEL SpriteVertexShader();
		PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
	}
};