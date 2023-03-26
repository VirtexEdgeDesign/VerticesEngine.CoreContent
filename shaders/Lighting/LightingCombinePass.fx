#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_4_0_level_9_1
	#define PS_SHADERMODEL ps_4_0_level_9_1
#endif


// The Scene Map
texture SceneMap;
sampler SceneMapSampler = sampler_state
{
    Texture = (SceneMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

// The light map which holds all point light data
texture lightMap;
sampler lightSampler = sampler_state
{
    Texture = (lightMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

// the RMA map which holds all shadows
texture SurfaceDataMap;
sampler SurfaceDataSampler = sampler_state
{
	Texture = (SurfaceDataMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};

texture EntityMaskMap;
sampler EntityMaskSampler = sampler_state
{
    Texture = (EntityMaskMap);

    MinFilter = Linear;
    MagFilter = Linear;
    
    AddressU = Clamp;
    AddressV = Clamp;
};

float4x4 MatrixTransform;
float2 HalfPixel;

struct VertexShaderInput
{
    float3 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;

};

VertexShaderOutput MainVS(VertexShaderInput input)
{
    VertexShaderOutput output;
    output.Position = float4(input.Position,1);
    output.TexCoord = input.TexCoord + HalfPixel;
    return output;
}


float4 MainPS(VertexShaderOutput input) : COLOR0
{
	//return 0.5;
	
	// Get the Colour of the Scene Currently
    float3 diffuseColor = tex2D(SceneMapSampler,input.TexCoord).rgb;
	
	// Now get the light map colour
    float4 light = tex2D(lightSampler,input.TexCoord);

	// Finally get the defferred rendering map data
	float4 defferred = tex2D(SurfaceDataSampler, input.TexCoord);
    float3 mask = tex2D(EntityMaskSampler, input.TexCoord);

	// just return the shaded scene for now
    return float4(diffuseColor * defferred.r, 1);
    return lerp(float4(diffuseColor * defferred.r, 1), float4(diffuseColor, 1), mask.r);

    float3 diffuseLight = light.rgb;
    float specularLight = light.a;
	
	// This is the scene lit
    float4 litScene = float4((diffuseColor * defferred.r + diffuseLight + specularLight), 1);

	return litScene;
}

technique BasicColorDrawing
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL MainPS();
	}
};