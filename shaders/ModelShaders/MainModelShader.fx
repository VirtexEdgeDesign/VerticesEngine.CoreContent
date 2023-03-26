
//			Main Properties
//*********************************************************************************************
#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

// Main Properties
//**********************************

// Is texturing enabled?
bool IsTextureEnabled;


// The main texture applied to the object, and a sampler for reading it.
texture Texture;

sampler Sampler = sampler_state
{
	Texture = (Texture);

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;

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


// In metric racer there is always a main directional light which all toon shading needs
// to be calcaulted against
float3 ToonLightDirection = normalize(float3(1, 1, 1));

// Settings controlling the Toon lighting technique.
float ToonColourThresholds[2] = { 0.8, 0.4 };
float ToonBrightnessLevels[3] = { 1.3, 0.9, 0.5 };


// Gets the toon shaded colour
float3 GetToonColour(float4 color, float3 WorldNormal)
{    
    float light;

	float LightAmount = 3 * dot(WorldNormal, ToonLightDirection);

    	if (LightAmount > ToonColourThresholds[0])
		light = ToonBrightnessLevels[0];
	else if (LightAmount > ToonColourThresholds[1])
		light = ToonBrightnessLevels[1];
	else
		light = ToonBrightnessLevels[2];
	
    return color.rgb * light;
}

// Pixel shader applies a cartoon shading algorithm.
float4 MainPSFunction(vx_v2f_full input) : COLOR0
{
	
	float4 color = IsTextureEnabled ? tex2D(Sampler, input.uv) : 0;
	
	float light;

	float3 normalFromMap = input.tangentToWorld[2];

		//Thirdly, get the Normal from both the Gemoetry and any supplied Normal Maps.
		//*********************************************************************************************
		// read the normal from the normal map
		normalFromMap = tex2D(normalSampler, input.uv);
		//tranform to [-1,1]
		normalFromMap = 2.0f * normalFromMap - 1.0f;
		//transform into world space
		normalFromMap = mul(normalFromMap, input.tangentToWorld);

		// get the rma map
		float4 rma = tex2D(RMASampler, input.uv).a;
		
    	float lightIntensity = 5 * saturate(dot(normalFromMap, LightDirection));

		color.rgb = color.rgb * saturate(lightIntensity + 0.5);
	
		//color.rgb = lerp(color.rgb, GetToonColour(color , normalFromMap), rma.a);

		// emissive map is an addition of all colours
		//float4 emsv = GetEmissiveTexture(input.uv);
		//color.rgb = lerp(color.rgb, emsv.rgb, emsv.a);

	return color * color.a;

	// //First, Get the Diffuse Colour of from the Texture
	// //*********************************************************************************************
	// float4 DiffuseColor = IsTextureEnabled ? tex2D(diffuseSampler, input.TexCoord) : float4(0.75,0.75,0.75,1);

	// float4 SurfaceMap = tex2D(surfaceMapSampler, input.TexCoord.xy);

	// float3 normalFromMap = 1 - tex2D(normalSampler, input.TexCoord).rgb * 2.0;
    // normalFromMap = mul(normalFromMap, input.tangentToWorld);
	// //float3 normalMap = 2.0 *(tex2D(normalSampler, input.TexCoord)) - 1.0;
    // //normalMap = normalize(mul(normalMap, input.WorldToTangentSpace));
    // //float4 normal = float4(normalMap,1.0);

	// //float lightAmount = saturate(dot(-LightDirection, normalFromMap));
	// //float4 Color = diffusecolor * (input.LightAmount.x) * DiffuseIntensity;// * input.LightAmount;// diffusecolor * saturate(dot(LightDirection, input.tangentToWorld[2]));
	// //float4 Color = diffusecolor * (lightAmount + AmbientIntensity) * DiffuseIntensity;

    // float4 diffuse = HasNormalMap ? saturate(dot(-LightDirection,normalFromMap)) : input.LightAmount.x;

	// float4 Color = DiffuseColor * AmbientLight * AmbientIntensity + 
    //         DiffuseColor * DiffuseIntensity * (0.5 + diffuse * 0.5);

	// // Get the Reflection Colour
	// float4 refCol = texCUBE(ReflectionSampler, normalize(input.Reflection));

	// // Now get the Relection Amount
	// float refFactor = HasReflectionMap ? SurfaceMap.b * ReflectionIntensity : 0;

	// Color = lerp(Color, refCol, refFactor * input.LightAmount.y);
	// Color = lerp(Color, FogColor, input.LightAmount.z);

	// return Color + float4(0, 0, 0, Alpha) + EmissiveColour * EmissiveIntensity + SelectionColour;
}

technique Technique_Main
{
	pass Pass0
	{
		VertexShader = compile VS_SHADERMODEL VXFullVertexShader();
		PixelShader = compile PS_SHADERMODEL MainPSFunction();
	}
}