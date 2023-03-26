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

float4 _SkyColor2 = float4(0.89, 0.96, 1, 0);

float4 _SkyColor3 = float4(0.89, 0.89, 0.89, 0);

float _SkyExponent2 =3.0;

float _SkyIntensity =1.0;
// Sun Colour
float4 _SunColor = float4(1, 0.99, 0.87, 1);

float _SunIntensity =2.0;
float _SunAlpha =550;
float _SunBeta =1.0;

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

	return output;
}

float4 MainPS(VertexShaderOutput i) : COLOR
{		
	float3 v = normalize(i.uv);

    float p = v.y;
    float p1 = 1 - pow(min(1, 1 - p), _SkyExponent1);
    float p3 = 1 - pow(min(1, 1 + p), _SkyExponent2);
    float p2 = 1 - p1 - p3;

    half3 c_sky = _SkyColor1 * p1 + _SkyColor2 * p2 + _SkyColor3 * p3;
    half3 c_sun = _SunColor * min(pow(max(0, dot(v, _SunVector)), _SunAlpha) * _SunBeta, 1);

    half4 skyCol = half4(c_sky * _SkyIntensity + c_sun * _SunIntensity, 0);
	
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