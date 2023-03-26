
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0

float4x4 VX_MATRIX_WORLD;
float4x4 VX_CAMERA_VIEW;
float4x4 VX_CAMERA_PROJ;

float3 VX_CAMERA_POS;

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
	float3 TextureCoordinate : TEXCOORD0;
};

VertexShaderOutput MainVS(in VertexShaderInput input)
{
	VertexShaderOutput output;

	float4 worldPosition = mul(input.Position, VX_MATRIX_WORLD);
	float4 viewPosition = mul(worldPosition, VX_CAMERA_VIEW);
	output.Position = mul(viewPosition, VX_CAMERA_PROJ);

	float4 VertexPosition = mul(input.Position, VX_MATRIX_WORLD);
	output.TextureCoordinate = VertexPosition - VX_CAMERA_POS;

	return output;
}

float4 MainPS(VertexShaderOutput input) : COLOR
{
	float4 color = texCUBE(SkyBoxSampler, normalize(input.TextureCoordinate));// + float4(0,0,1,1);
	return saturate(color);
}

technique Skybox
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL MainPS();
	}
};