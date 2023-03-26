/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	This shader is used for temp entities in the editor before they are added to the scene
*/

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

// -- Properties --
float4 NormalColour;
float Alpha;

// The color to draw the lines in.  Black is a good default.
float4 LineColor = float4(0, 0, 0, 1);

// The thickness of the lines.  This may need to change, depending on the scale of
// the objects you are drawing.
float LineThickness = .03;

struct VertexShaderInput
{
	float4 Position : POSITION0;
	float3 Normal : NORMAL0;                // The vertex's normal
};

struct VertexShaderOutput
{
	float4 Position : SV_POSITION;
};

VertexShaderOutput MainVS(in VertexShaderInput i)
{
	VertexShaderOutput o = (VertexShaderOutput)0;

	// Calculate where the vertex ought to be.  This line is equivalent
	// to the transformations in the CelVertexShader.
	float4 original = mul(i.Position, VX_MATRIX_WVP);

	// Calculates the normal of the vertex like it ought to be.
	float4 normal = mul(i.Normal, VX_MATRIX_WVP);

	// Take the correct "original" location and translate the vertex a little
	// bit in the direction of the normal to draw a slightly expanded object.
	// Later, we will draw over most of this with the right color, except the expanded
	// part, which will leave the outline that we want.
	o.Position = original + (mul(LineThickness, normal));

	return o;
}

float4 MainPS(VertexShaderOutput i) : COLOR
{
	float4 result = NormalColour;	
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