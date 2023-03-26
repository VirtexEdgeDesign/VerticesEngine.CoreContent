/*
@Title: Terrain Shader - Vertices Engine
@autor: Robert Roe
@brief:	This shader applies a screenspace fog post process to the scene
*/


#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"


float maxHeight = 92;

// Texture UV Scale
float TxtrUVScale = 16;

bool IsEditMode = false;


float textureSize = 256.0f;
float2 CursorPosition;
float CursorScale = 1;

float4 CursorColour = float4(0, 0.25, 1, 1);


// Settings controlling the Toon lighting technique.
float TnThresholds[2] = { 0.8, 0.4 };
float TnBrightnessLevels[3] = { 1.3, 0.9, 0.5 };

texture displacementMap;
sampler displacementSampler = sampler_state
{
    Texture   = <displacementMap>;
    MipFilter = Point;
    MinFilter = Point;
    MagFilter = Point;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

texture textureWeightMap;
sampler textureWeightSampler = sampler_state
{
	Texture = <textureWeightMap>;
	MipFilter = Point;
	MinFilter = Point;
	MagFilter = Point;
	AddressU = Clamp;
	AddressV = Clamp;
};

texture CursorMap;
sampler CursorMapSampler = sampler_state
{
	Texture = <CursorMap>;
	MipFilter = Linear;
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

texture randomMap;
sampler RandomMapSampler = sampler_state
{
Texture = <randomMap>;
MipFilter = Point;
MinFilter = Point;
MagFilter = Point;
	AddressU = Clamp;
	AddressV = Clamp;
};




texture Texture01;
sampler sandSampler = sampler_state
{
	Texture = <Texture01>;
	MipFilter = Linear;
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

texture Texture02;
sampler grassSampler = sampler_state
{
	Texture = <Texture02>;
	MipFilter = Linear;
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

texture Texture03;
sampler rockSampler = sampler_state
{
	Texture = <Texture03>;
	MipFilter = Linear;
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};

texture Texture04;
sampler snowSampler = sampler_state
{
	Texture = <Texture04>;
	MipFilter = Linear;
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};





struct VS_INPUT {
    float4 position	: POSITION;
	float3 Normal : NORMAL0;                // The vertex's normal
    float4 uv : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 position  : POSITION;
    float4 uv : TEXCOORD0;
    float4 worldPos : TEXCOORD1;
    float4 textureWeights : TEXCOORD2;
    float LightAmount : TEXCOORD3;
	float3 WorldNormal : TEXCOORD4;
};





 
VS_OUTPUT TerrainVS(VS_INPUT In)
{
	//initialize the output structure
	VS_OUTPUT Out = (VS_OUTPUT)0;  

	// Calculate World Position
	float4 worldPosition = mul(float4(In.position.xyz, 1), VX_MATRIX_WORLD);
										
	Out.position = mul(float4(In.position.xyz, 1), VX_MATRIX_WVP);
	
	Out.WorldNormal = normalize(mul((In.Normal), VX_MATRIX_WORLD));

	Out.LightAmount = In.Normal;// abs(dot(worldNormal, LightDirection));
	
	// with the newly read height, we compute the new value of the Y coordinate
	// we multiply the height, which is in the (0,1) range by a value representing the Maximum Height of the Terrain
	//In.position.y = height * maxHeight;

	//Pass the world position the the Pixel Shader
	Out.worldPos = worldPosition;// mul(In.position, world);

	//Compute the final projected position by multiplying with the world, view and projection matrices                                                      
	//Out.position = mul(In.position, worldViewProj);
	Out.uv = In.uv;


	// this instruction reads from the heightmap, the value at the corresponding texture coordinate
	// Note: we selected level 0 for the mipmap parameter of tex2Dlod, since we want to read data exactly as it appears in the heightmap
	float height = 1;// tex2Dlod(displacementSampler, float4(In.uv.xy, 0, 0));
	height = Out.worldPos.y / maxHeight;

	//height = tex2Dlod(textureWeightSampler, float4(In.uv.xy, 0, 0)).r;
	//height = tex2D(textureWeightSampler, In.uv.xy).r;

	float4 TexWeights = 0;

	TexWeights.x = saturate(1.0f - abs(height - 0) / 0.25f);
	TexWeights.y = saturate(1.0f - abs(height - 0.25) / 0.25f);
	TexWeights.z = saturate(1.0f - abs(height - 0.5) / 0.25f);
	TexWeights.w = min(1, saturate(1.0f - abs(height - 0.75) / 0.25f));

	// handle edge cases
	TexWeights = Out.worldPos.y < 0 ? float4(1, 0, 0, 0) : TexWeights;
	TexWeights = Out.worldPos.y > maxHeight ? float4(0, 0, 0, 1) : TexWeights;

	float totalWeight = TexWeights.x + TexWeights.y + TexWeights.z + TexWeights.w;
	TexWeights /= totalWeight;
	Out.textureWeights = saturate(TexWeights);
	
	return Out;
}

float2 rotateUV(float2 uv, float rotation)
{
    float mid = 0.5;
    return float2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

float4 TerrainPS(VS_OUTPUT input) : COLOR0
{ 
	float cursorFactor = IsEditMode == false ? 0 : tex2D(CursorMapSampler, (input.uv.xy * textureSize - (CursorPosition - float2(CursorScale / 2, CursorScale / 2))) / CursorScale).a;
	float4 color = IsEditMode == false ? 0 : lerp(1, CursorColour, cursorFactor);
	
	float4 weights = input.textureWeights;
	
	// Get the UV Scale
	float2 uv = input.uv.xy * TxtrUVScale * 4;
	float rand = tex2D(RandomMapSampler, input.uv.xy).g * 5;
	uv = rotateUV(uv, rand);

	float4 sand = weights.x > 0 ? tex2D(sandSampler,uv) : 0;
	float4 grass = weights.y > 0 ? tex2D(grassSampler,uv) : 0;
	float4 rock = weights.z > 0 ? tex2D(rockSampler,uv) : 0;
	float4 snow = weights.w > 0 ? tex2D(snowSampler,uv) : 0;

	color = sand * weights.x + grass * weights.y + rock * weights.z + snow * weights.w;

		float light;

	float LightAmount = dot(input.WorldNormal, normalize(LightDirection));

	if (LightAmount > TnThresholds[0])
		light = TnBrightnessLevels[0];
	else if (LightAmount > TnThresholds[1])
		light = TnBrightnessLevels[1];
	else
		light = TnBrightnessLevels[2];

	color.rgb *= light;
	color.a = 1;

	//  color = 1;

	//  float dt = dot(input.WorldNormal, float3(0, 1, 0));
	//  dt = 1 - pow(dt, 10);
	//  dt = saturate(dt);
	//  color.rgb *= dt;

	//  color = lerp(tex2D(grassSampler,uv), tex2D(rockSampler,uv), dt) * (LightAmount + 0.3) ;
	// color.a = 1;

	return  lerp(color, CursorColour, cursorFactor);	
}

technique Terrain
{

    pass P0
    {
        VertexShader = compile VS_SHADERMODEL TerrainVS();
        PixelShader  = compile PS_SHADERMODEL TerrainPS();
    }
}
