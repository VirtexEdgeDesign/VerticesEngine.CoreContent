/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	This is a generic hologram shader that takes two images and two colours that allow for different image types
*/

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

// Main Properties
//**********************************

float4 _SkyColor1 = float4 (0.37, 0.52, 0.73, 0);
float _SkyExponent1 = 8.5;
float _SkyColorStrength1 = 0.01;

float4 _SkyColor2 = float4(0.89, 0.96, 1, 0);
float _SkyExponent2 = 3.0;
float _SkyColorStrength2 = 1.0;

float4 _SkyColor3 = float4(0.89, 0.89, 0.89, 0);
float _SkyIntensity = 1.0;
float _SkyColorStrength3 = 1.0;

bool _flipX = false;
bool _flipY = false;

// Sun Colour
// float4 _SunColor = float4(1, 0.99, 0.87, 1);

// float _SunIntensity =2.0;
// float _SunAlpha =550;
// float _SunBeta =1.0;

float4 _SunVector = float4(0.269, 0.615, 0.740, 0);
		
Texture SkyBoxTexture;
samplerCUBE SkyBoxSampler = sampler_state
{
	texture = (SkyBoxTexture);
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = Mirror;
	AddressV = Mirror;
};



struct VertexShaderInput
{
	float4 Position : SV_POSITION;
};

struct VertexShaderOutput
{
	float4 Position : SV_POSITION;
	float3 uv : TEXCOORD0;
};

VertexShaderOutput MainVS(in VertexShaderInput input)
{
	VertexShaderOutput output;
	
	output.Position =  mul(input.Position, VX_MATRIX_WVP);
	
	float4 VertexPosition = mul(input.Position, VX_MATRIX_WORLD);	
	output.uv = VertexPosition - VX_CAMERA_POS;

	output.uv.z = _flipX == true ?  output.uv.z : 1 -  output.uv.z;
	output.uv.y = _flipY == true ? 1 - output.uv.y : output.uv.y;

	return output;
}

float4 MainPS(VertexShaderOutput i) : COLOR
{	
	float3 v = normalize(i.uv);

	//return 1;
	
    float p = v.y;
    float p1 = 1 - pow(min(1, 1 - p), _SkyExponent1);
    float p3 = 1 - pow(min(1, 1 + p), _SkyExponent2);
    float p2 = 1 - p1 - p3;

	// Get the cube sky colour
	// TODO: Add dynamic projected skyboxes instead of just static cube maps
	float4 cubeSkyColour = texCUBE(SkyBoxSampler, normalize(i.uv)); 

	//cubeSkyColour = pow(cubeSkyColour, 2.2);

	// get the lerp colour between the cube colour and sky colour
	float3 skyColour1 = lerp(cubeSkyColour, _SkyColor1, _SkyColorStrength1);
	float3 skyColour2 = lerp(cubeSkyColour, _SkyColor2, _SkyColorStrength2);
	float3 skyColour3 = lerp(cubeSkyColour, _SkyColor3, _SkyColorStrength3);

	// sky colour
    half3 c_sky = skyColour1 * p1 + skyColour2 * p2 + skyColour3 * p3;
    //half3 c_sun = _SunColor * min(pow(max(0, dot(v, _SunVector)), _SunAlpha) * _SunBeta, 1);

    //half4 skyCol = half4(c_sky * _SkyIntensity + c_sun * _SunIntensity, 0);
    half4 skyCol = half4(c_sky * _SkyIntensity, 0);
	
	//float4 color = texCUBE(SkyBoxSampler, normalize(i.uv));// + float4(0,0,1,1);
	//float3 grayScale = rgb2grayscale(color.rgb);
	//skyCol.rgb *= grayScale;
	//skyCol.rgb = lerp(color.rgb, skyCol.rgb, 1-grayScale.r);
	return skyCol;
}

technique Technique_Main
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL MainPS();
	}
};