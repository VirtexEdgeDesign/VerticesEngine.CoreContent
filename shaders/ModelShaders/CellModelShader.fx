
//			Main Properties
//*********************************************************************************************

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

float Alpha = 1;

// The light direction is shared between the Lambert and Toon lighting techniques.
//float3 LightDirection = normalize(float3(1, 1, 1));
float4 AmbientLight = float4(0.5, 0.5, 0.5, 1);
float4 EvissiveColour = float4(0, 0, 0, 0);

// Toon Cut off Variables
float ToonThresholds[2] = { 0.8, 0.4 };
float ToonBrightnessLevels[3] = {  0.9, 0.5, 0.2 };


texture Texture;
sampler diffuseSampler = sampler_state
{
    Texture = (Texture);
    MAGFILTER = LINEAR;
    MINFILTER = LINEAR;
    MIPFILTER = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};
texture DiffuseMap;
sampler diffuseMapSampler = sampler_state
{
	Texture = (DiffuseMap);
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	Mipfilter = LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

texture SpecularMap;
sampler specularSampler = sampler_state
{
    Texture = (SpecularMap);
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

texture NormalMap;
sampler normalSampler = sampler_state
{
    Texture = (NormalMap);
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};



//**************************************************
//					Main Shader
//**************************************************

/*
This Technique draws the rendertargets which are used
in other techniques later on, such as Normal and Depth
Calculations, Mask for God Rays. It performs all of
this in one pass rendering to multiple render targets
at once.
*/

// Vertex shader input structure.
struct MainVSInput
{
	float4 Position : POSITION0;
	float3 Normal 	: NORMAL0;
	float2 TexCoord	: TEXCOORD0;
	float3 Binormal	: BINORMAL0;
	float3 Tangent	: TANGENT0;
};

struct MainVSOutput
{
	float4 Position : POSITION0;
	float2 TexCoord : TEXCOORD0;
	float3x3 tangentToWorld : TEXCOORD1;
};


MainVSOutput MainVSFunction(MainVSInput input, float4x4 worldTransform)
{
	MainVSOutput output;

	float4 worldPosition = mul(float4(input.Position.xyz, 1), worldTransform);
	float4 viewPosition = mul(worldPosition, VX_CAMERA_VIEW);
	output.Position = mul(viewPosition, VX_CAMERA_PROJ);

	output.TexCoord = input.TexCoord + VX_UV0_OFFSET;

	// calculate tangent space to world space matrix using the world space tangent,
	// binormal, and normal as basis vectors
	output.tangentToWorld[0] = mul(input.Tangent, worldTransform);
	output.tangentToWorld[1] = mul(input.Binormal, worldTransform);
	output.tangentToWorld[2] = mul(input.Normal, worldTransform);

	return output;
}


MainVSOutput MainVSFunctionInstancedVS(MainVSInput input, float4x4 instanceTransform : TEXCOORD2)
{
	float4x4 worldTransform = mul(transpose(instanceTransform), VX_MATRIX_WORLD);
	return MainVSFunction(input, worldTransform);
}

MainVSOutput MainVSFunctionNonInstVS(MainVSInput input)
{
	return MainVSFunction(input, VX_MATRIX_WORLD);
}


// Pixel shader applies a cartoon shading algorithm.
float4 MainPSFunction(MainVSOutput input) : COLOR0
{
	//First, Get the Diffuse Colour of from the Texture
	//*********************************************************************************************
	float4 diffusecolor = tex2D(diffuseSampler, input.TexCoord);
	float diffuseMap = tex2D(diffuseMapSampler, input.TexCoord).a;

	//Set Colour From the Diffuse Sampler Colour and the Shadow Factor
	float4 Color = diffusecolor;


	float LightAmount = dot(input.tangentToWorld[0], LightDirection);

	float light;

	if (LightAmount > ToonThresholds[0])
		light = ToonBrightnessLevels[0];
	else if (LightAmount > ToonThresholds[1])
		light = ToonBrightnessLevels[1];
	else
		light = ToonBrightnessLevels[2];

	Color.rgb *= light + AmbientLight;

	if (diffuseMap < 0.5)
		return diffusecolor;

	return Color + float4(0, 0, 0, Alpha) + EvissiveColour;

}

technique Technique_Main
{
	pass Pass0
	{
		VertexShader = compile VS_SHADERMODEL MainVSFunctionNonInstVS();
		PixelShader = compile PS_SHADERMODEL MainPSFunction();
	}
}

technique Technique_Main_Instanced
{
	pass Pass0
	{
		VertexShader = compile VS_SHADERMODEL MainVSFunctionInstancedVS();
		PixelShader = compile PS_SHADERMODEL MainPSFunction();
	}
}