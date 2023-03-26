/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	The SSAO Implmentation
*/

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



//float4x4 MatrixTransform;
//float2 HalfPixel;


// The inverse View Projection
float4x4 InverseViewProjection;


// The Camera's View Projection
float4x4 ViewProjection;


float2 Radius = float2(0.02, 0.5);

float Bias = 0.00001;
float RangeCutOff = 1;
float Intensity = 1.25;

float Tiles = 100;


// This texture contains normals (in the color channels) and depth (in alpha)
// for the main scene image. Differences in the normal and depth data are used
// to detect where the edges of the model are.
texture NormalMap;

sampler NormalSampler : register(s1) = sampler_state
{
	Texture = (NormalMap);

	MinFilter = Linear;
	MagFilter = Linear;

	AddressU = Clamp;
	AddressV = Clamp;
};


// This texture contains the Depth Value.
texture DepthMap;

sampler DepthSampler : register(s2) = sampler_state
{
	Texture = (DepthMap);

	MinFilter = Point;
	MagFilter = Point;

	AddressU = Clamp;
	AddressV = Clamp;
};


texture RandomMap;
sampler2D randomSampler : register(s3) = sampler_state
{
	Texture = (RandomMap);
	MipFilter = NONE;
	MagFilter = POINT;
	MinFilter = POINT;
	AddressU = Wrap;
	AddressV = Wrap;
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

half3 DecodeNormal (half4 enc)
{
	return enc.xyz * 2.0 - 1.0;

	float kScale = 1.7777;
	float3 nn = enc.xyz*float3(2*kScale,2*kScale,0) + float3(-kScale,-kScale,1);
	float g = 2.0 / dot(nn.xyz,nn.xyz);
	float3 n;
	n.xy = g*nn.xy;
	n.z = g-1;
	return n;
}

void SpriteVertexShader(inout float4 vColor : COLOR0,
	inout float2 texCoord : TEXCOORD0,
	inout float4 position : POSITION0)
{
	position = mul(position, MatrixTransform);
}

float4 PixelShaderFunction(float2 texCoord : TEXCOORD0) : COLOR0
{

		//Get initial Depth and 3d position
	float depth = GetDepth(texCoord);

	clip(depth-0.8);

	// get the world position
	float3 origin = GetWorldPosition(texCoord, depth);
	float3 samplePos = GetUVFromPosition(origin + float3(0.1,0,0));
	float2 newCoord = samplePos.xy + HalfPixel * 2;
	
	// Get Depth at New Coord
	float smplDepth = GetDepth(newCoord);

	//Now check difference in depth value
	float delta = smplDepth - samplePos.z;
	//return float4(delta * 10000,0,0, 1);

	// total occlusion
	float totalOcclusion = 0;

	
	//prevent near 0 divisions
	float scale = min(Radius.y,Radius.x / max(1,depth));
	//float scale = lerp(Radius.x, Radius.y , depth);
		

	half3 normal = DecodeNormal(tex2D(NormalSampler, texCoord));
    normal = normalize(normal);
	//normal.y = -normal.y;

	//this will be used to avoid self-shadowing		  
	half3 normalScaled = normal * 0.25f;
	//pick a random normal, to add some "noise" to the output
	half3 randNormal = (tex2D(randomSampler, texCoord * Tiles * length(origin)).rgb * 2.0 - 1.0);

	float sampleDepth = 1;
	//reflect(RAND_SAMPLES[i], randNormal);
	for (int i = 0; i < SAMPLE_COUNT; i++)
	{
		// get the offset from the Sample Kernel
		//float3 norm = RAND_SAMPLES[i] * randNormal.rgb;

		//half3 randomDirection = reflect(RAND_SAMPLES[i], randNormal);
		half3 randomDirection = reflect(RAND_SAMPLES[i], randNormal);
		//half3 randomDirection = normalize(RAND_SAMPLES[i] * randNormal);
			
		// Prevent it pointing inside the geometry
		randomDirection *= sign( dot(normal , randomDirection) );

		// add that scaled normal
		randomDirection += normalScaled;
		

		float3 wPos = origin + randomDirection * scale;

		samplePos = GetUVFromPosition(wPos);
		// now check in the vicinity of this 
		sampleDepth = GetDepth(samplePos.xy);
		float3 newNormal = DecodeNormal(tex2D(NormalSampler, samplePos.xy));

		//we only care about samples in front of our original-modifies 
		float deltaDepth = saturate(samplePos.z-sampleDepth);
		float rangeCheck = deltaDepth < RangeCutOff ? 1-deltaDepth/RangeCutOff * 1 - dot(newNormal, normal) : 0.0;
		totalOcclusion += (sampleDepth <= samplePos.z ? 1.0 : 0.0) * rangeCheck * (deltaDepth > Bias);
	}
	//return newDepth;
	totalOcclusion /= SAMPLE_COUNT;

    return 1 - totalOcclusion * Intensity;
}

technique Technique1
{
    pass Pass0
    {
		VertexShader = compile VS_SHADERMODEL SpriteVertexShader();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}
