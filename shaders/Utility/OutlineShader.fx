#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_4_0_level_9_1
	#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

// The World*View*Projection Multiplcate
matrix VX_MATRIX_WVP;

// Selection Colour 
float4 SelectionColour = float4(0, 0, 0, 0);

// The color to draw the lines in.  Black is a good default.
float4 LineColor = float4(0, 0, 0, 1);

// The thickness of the lines.  This may need to change, depending on the scale of
// the objects you are drawing.
float LineThickness = .03;

struct OutlineVertexShaderInput
{
	float4 Position : POSITION0;            // The position of the vertex
	float3 Normal : NORMAL0;                // The vertex's normal
	float2 TextureCoordinate : TEXCOORD0;    // The texture coordinate of the vertex
};

struct OutlineVertexShaderOutput
{
	float4 Position : POSITION0;
	float2 TextureCoordinate : TEXCOORD0;
	float3 Normal : TEXCOORD1;
};

OutlineVertexShaderOutput OutlineMainVS(in OutlineVertexShaderInput input)
{
	OutlineVertexShaderOutput output = (OutlineVertexShaderOutput)0;

	// Calculate where the vertex ought to be.  This line is equivalent
	// to the transformations in the CelVertexShader.
	float4 original = mul(input.Position, VX_MATRIX_WVP);

	// Calculates the normal of the vertex like it ought to be.
	float4 normal = mul(input.Normal, VX_MATRIX_WVP);

	// Take the correct "original" location and translate the vertex a little
	// bit in the direction of the normal to draw a slightly expanded object.
	// Later, we will draw over most of this with the right color, except the expanded
	// part, which will leave the outline that we want.
	output.Position = original + (mul(LineThickness, normal));

	return output;
}

float4 OutlineMainPS(OutlineVertexShaderOutput input) : COLOR
{
	return SelectionColour;
}

technique Technique_Outline
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL OutlineMainVS();
		PixelShader = compile PS_SHADERMODEL OutlineMainPS();
	}
};