/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	This shader is used for editor entities
*/

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

// -- Properties --


// the corrdinates of the mouse
float2 mouseCoords;

uniform float _handleID;
uniform float _isSelected = 0;
uniform float _isMouseUp = 0;
uniform float Alpha = 1;

// Selection State Colours
float4 NormalColour;
float4 HoverColour;
float4 SelectedColour;
float4 EntityIndexedColour;

// The index colour texture
texture IndexColourTexture;
sampler IndexColourSampler = sampler_state
{
	Texture = (IndexColourTexture);

	MinFilter = Linear;
	MagFilter = Linear;

	AddressU = Clamp;
	AddressV = Clamp;
};

struct VertexShaderInput
{
	float4 Position : POSITION0;
	float2 uv : TEXCOORD0;
};

struct VertexShaderOutput
{
	float4 Position : SV_POSITION;
	float2 uv : TEXCOORD0;
	//float2 screenPos : TEXCOORD0;
};



VertexShaderOutput MainVS(in VertexShaderInput i)
{
	VertexShaderOutput o = (VertexShaderOutput)0;

	o.Position = mul(i.Position, VX_MATRIX_WVP);

	o.uv = float2(0.5f, 0.5f) + float2(0.5f, -0.5f) * o.Position.xy / o.Position.w;// GetUVFromPosition();

	return o;
}

float4 MainPS(VertexShaderOutput i) : COLOR
{
	if (_isSelected == 1)
		return SelectedColour;


	float4 result = NormalColour;
	// only check mouse hovering iff we're not selected and the mouse is up
	if (_isMouseUp == 1)
	{
		float4 mouseIndexColour = tex2D(IndexColourSampler, mouseCoords.xy);

		//return float4(i.uv.x, i.uv.y, 0, 1);
		if (mouseIndexColour.r == EntityIndexedColour.r && mouseIndexColour.g == EntityIndexedColour.g && mouseIndexColour.b == EntityIndexedColour.b)
		{
			result = HoverColour;
		}
	}

	result.a = Alpha;
	return result;
}

technique Technique_Main
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL MainPS();
	}
};