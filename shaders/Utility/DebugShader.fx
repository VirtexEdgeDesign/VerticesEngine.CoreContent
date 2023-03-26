#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_4_0_level_9_1
	#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

float4x4 VX_MATRIX_WORLD;

matrix VX_MATRIX_WVP;

// Should it show the texture
bool DoTexture = false;

// Should it Render Wireframe
bool DoWireFrame = false;

// Should the Shadows be rendered
bool DoShadows = false;

// Diffuse Colour
float3 DiffuseLight = 0.5;

// WireColor
float4 WireColour = float4(0.1, 0.1, 0.1, 1);

// Texture UV Coordinate Offset
float2 VX_UV0_OFFSET = float2(0, 0);

// Show Block Textures
bool DoBlockTexture = false;

float3 LightDirection = normalize(float3(1, 1, 1));
float4 AmbientLight = float4(0.5, 0.5, 0.5, 1);


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


struct VertexShaderInput
{
	float4 Position : POSITION0;
	float3 Normal : NORMAL0;
	float2 TextureCoordinate : TEXCOORD0;
};

struct VertexShaderOutput
{
	float4 Position : SV_POSITION;
	float2 TextureCoordinate : TEXCOORD0;
	float LightAmount : TEXCOORD1;
	float3 WorldNormal : TEXCOORD2;
};

VertexShaderOutput MainVS(in VertexShaderInput input)
{
	VertexShaderOutput output = (VertexShaderOutput)0;

	// Apply camera matrices to the input position.
	output.Position = mul(input.Position, VX_MATRIX_WVP);

	// Copy across the input texture coordinate.
	output.TextureCoordinate = input.TextureCoordinate + VX_UV0_OFFSET;

	// Compute the overall lighting brightness.
	float3 worldNormal = mul(input.Normal, VX_MATRIX_WORLD);

	output.LightAmount = dot(worldNormal, LightDirection);
	output.WorldNormal = worldNormal;// input.Normal;


	if (DoWireFrame == true)
	{
		// Calculate where the vertex ought to be.  This line is equivalent
		// to the transformations in the CelVertexShader.
		float4 original = mul(input.Position, VX_MATRIX_WVP);

		// Calculates the normal of the vertex like it ought to be.
		float4 normal = mul(input.Normal, VX_MATRIX_WVP);

		// Take the correct "original" location and translate the vertex a little
		// bit in the direction of the normal to draw a slightly expanded object.
		// Later, we will draw over most of this with the right color, except the expanded
		// part, which will leave the outline that we want.
		output.Position = original + (mul(.0015, normal));
	}

	return output;
}

float4 MainPS(VertexShaderOutput input) : COLOR
{
	// Return Texture
	if (DoTexture==true)
		return tex2D(diffuseSampler, input.TextureCoordinate);

	// If it's just Wireframe, Return the Colour
	if(DoWireFrame==true)
		return WireColour;
	
	// Finally do this.
	return float4(0.1,0.1,0.1,1);
}

technique Technique_Debug
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL MainPS();
	}
};



