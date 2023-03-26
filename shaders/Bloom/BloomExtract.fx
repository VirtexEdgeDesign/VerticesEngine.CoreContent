// Pixel shader extracts the brighter areas of an image.
// This is the first step in applying a bloom postprocess.

#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_4_0
	#define PS_SHADERMODEL ps_4_0
#endif

sampler TextureSampler : register(s0);

float BloomThreshold;

bool DoFullSceneBloom = true;

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

texture EmissiveMapTexture;
sampler EmissiveMapSampler = sampler_state//: register(s1) = sampler_state
{
	Texture = (EmissiveMapTexture);
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

float4 PixelShaderFunction(float2 texCoord : TEXCOORD0) : COLOR0
{
    // Look up the original image color.
    float4 c = tex2D(TextureSampler, texCoord);

        	// Now get the light map colour
        float4 light = tex2D(lightSampler, texCoord);

        float3 diffuseLight = light.rgb;
        float specularLight = light.a;

        float e = tex2D(EmissiveMapSampler, texCoord).g * 5;// + diffuseLight + specularLight;
        c *= e;

    // Adjust it to keep only values brighter than the specified threshold.
    return saturate((c - BloomThreshold) / (1 - BloomThreshold));
}


technique BloomExtract
{
    pass Pass1
    {
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}
