// This Shader is used to apply a number of differen passes which each apply a different post process.

// First is SSR application and blurring.

// Second is God Rays Blending.

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

#define SAMPLE_COUNT 16

float3 RAND_SAMPLES[SAMPLE_COUNT] = 
{
      float3( 0.5381, 0.1856,-0.4319), 
	  float3( 0.1379, 0.2486, 0.4430),
      float3( 0.3371, 0.5679,-0.0057), 
	  float3(-0.6999,-0.0451,-0.0019),
      float3( 0.0689,-0.1598,-0.8547), 
	  float3( 0.0560, 0.0069,-0.1843),
      float3(-0.0146, 0.1402, 0.0762), 
	  float3( 0.0100,-0.1924,-0.0344),
      float3(-0.3577,-0.5301,-0.4358), 
	  float3(-0.3169, 0.1063, 0.0158),
      float3( 0.0103,-0.5869, 0.0046), 
	  float3(-0.0897,-0.4940, 0.3287),
      float3( 0.7119,-0.0154,-0.0918), 
	  float3(-0.0533, 0.0596,-0.5411),
      float3( 0.0352,-0.0631, 0.5460), 
	  float3(-0.4776, 0.2847,-0.0271)
  };
	

// The Scene, lit with Fog, Shadows and Lighting. 
// Essentially Everything which will be reflected.
texture SceneTexture;
sampler SceneTextureSampler = sampler_state
{
    Texture = (SceneTexture);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};



texture BlurredSceneTexture;
sampler BlurredSceneSampler = sampler_state
{
	Texture = (BlurredSceneTexture);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	Mipfilter = LINEAR;
};


// The SSR Reflection UV Coordinates.
texture SSRUVs;
sampler SSRUVSampler = sampler_state
{
	Texture = (SSRUVs);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};

texture SSAOMap;
sampler SSAOSampler = sampler_state
{
	Texture = (SSAOMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
};

// This is the Sun Mask Texture which holds the image of the sun.
texture2D SunMaskTexture;
sampler SunMaskSampler = sampler_state
{
	Texture = <SunMaskTexture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = wrap;
	AddressV = wrap;
};

texture2D DepthMap;
sampler DepthMapSampler : register(s2) = sampler_state
{
	texture = <DepthMap>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};


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


float2 lightScreenPosition;

//float2 HalfPixel;
VertexShaderOutput VS_Main(VertexShaderInput input)
{
    VertexShaderOutput output;
    output.Position = float4(input.Position,1);
    output.TexCoord = input.TexCoord + HalfPixel;

    return output;
}



float SSRQuality = 0;
float BlurFactor = 100;

// Blend in Screenspace Reflections
// ****************************************************************************

float4 PS_ApplySSR(VertexShaderOutput input) : COLOR0
{
	// Get the Colour of the Scene Currently
    float3 SceneColor = tex2D(SceneTextureSampler,input.TexCoord).rgb;

	// Take the SSR Result,
	// If there's no colour, then try and get the reflection cube map as a last resort.

	// Handle SSR Quality
	if(SSRQuality > 0)
	{
		float4 reflUV = tex2D(SSRUVSampler, input.TexCoord);
		// Is there even a Ray in this location
		if (reflUV.a > 0)
		{
			// Get the Reflection Amount
			float reflAmount = reflUV.a;

			// get the difference between the current and reflected UVs
			float blurAmount = length(reflUV - input.TexCoord);
			
			float3 ssrblur = 0;//tex2D(SceneTextureSampler, reflUV.xy).rgb;

			// Handle High and Ultra Settings
			if(SSRQuality > 2)
			{
				for (int i = 0; i < SAMPLE_COUNT; i++)
				{
					// Find the reflection UV coordinates of surrounding items
					reflUV = tex2D(SSRUVSampler, input.TexCoord + RAND_SAMPLES[i].xy * (HalfPixel * blurAmount * BlurFactor));
					ssrblur += tex2D(SceneTextureSampler, reflUV.xy).rgb;
				}
				ssrblur /= SAMPLE_COUNT;
			}
			else
			{
				//float3 ssrScene = tex2D(SceneTextureSampler, reflUV.xy).rgb;
				ssrblur = tex2D(BlurredSceneSampler, reflUV.xy).rgb;
				//ssrblur = lerp
			}
			SceneColor =  float4(lerp(SceneColor, ssrblur * reflAmount, reflAmount), 1);
		}
	}
	float ssao = 0;
	//reflect(RAND_SAMPLES[i], randNormal);
	for (int i = 0; i < SAMPLE_COUNT; i++)
	{
		ssao += tex2D(SSAOSampler, input.TexCoord + RAND_SAMPLES[i].xy * HalfPixel * 20).r;
	}
	
	ssao /= SAMPLE_COUNT;
	
	SceneColor = lerp(0, SceneColor, ssao); 

	return float4(SceneColor, 1);
}









// God Rays
// ****************************************************************************

//#define NUM_SAMPLES 25
//
////float2 HalfPixel;
//
//float Density = .5f;
//float Decay = .95f;
//float Weight = 1.0f;
//float Exposure = .15f;
//
//bool DoGodRays = true;
//
//float4 PS_ApplyGodRays(VertexShaderOutput input) : COLOR0
//{
//	if (DoGodRays==true)
//	{
//	float4 SunColor = tex2D(SunMaskSampler, input.TexCoord);
//
//	// Look up the bloom and original base image colors.
//	//float4 base = tex2D(TextureSampler, texCoord);
//	//float3 col = tex2D(TextureSampler, texCoord);
//
//	float IlluminationDecay = 0.75f;
//	float3 Sample;
//
//	float2 texCoord = input.TexCoord - HalfPixel;
//
//	float2 DeltaTexCoord = (texCoord - lightScreenPosition) * (1.0f / (NUM_SAMPLES)* Density);
//
//	for (int i = 0; i < NUM_SAMPLES; ++i)
//	{
//		texCoord -= DeltaTexCoord;
//		Sample = tex2D(SunMaskSampler, texCoord);
//		Sample *= IlluminationDecay * Weight;
//		SunColor.rgb += Sample;
//		IlluminationDecay *= Decay;
//	}
//
//	return float4(SunColor.rgb, SunColor.r);
//	}
//	else
//	{
//		return 0;
// }
//}







// This texture contains normals (in the color channels) and depth (in alpha)
// for the main scene image. Differences in the normal and depth data are used
// to detect where the edges of the model are.
//texture NormalTexture;
//
//sampler NormalSampler = sampler_state
//{
//	Texture = (NormalTexture);
//
//	MinFilter = Linear;
//	MagFilter = Linear;
//
//	AddressU = Clamp;
//	AddressV = Clamp;
//};



//// Settings controlling the edge detection filter.
//float EdgeWidth = 1;
//float EdgeIntensity = 1;
//
//// How sensitive should the edge detection be to tiny variations in the input data?
//// Smaller settings will make it pick up more subtle edges, while larger values get
//// rid of unwanted noise.
//float NormalThreshold = 0.5;
//float DepthThreshold = 0.1;
//
//// How dark should the edges get in response to changes in the input data?
//float NormalSensitivity = 1;
//float DepthSensitivity = 10;
//
//// How should the sketch effect respond to changes of brightness in the input scene?
//float SketchThreshold = 0.1;
//float SketchBrightness = 0.333;
//
//// Randomly offsets the sketch overlay pattern to create a hand-drawn animation effect.
//float2 SketchJitter;
//
//// Pass in the current screen resolution.
//float2 ScreenResolution;
//
//
//
//
//// Pixel shader applies the edge detection and/or sketch filter postprocessing.
//// It is compiled several times using different settings for the uniform boolean
//// parameters, producing different optimized versions of the shader depending on
//// which combination of processing effects is desired.
//float4 PS_ApplyEdgeDetec(VertexShaderOutput input) : COLOR0
//{
//	// Look up the original color from the main scene.
//	//float3 scene = tex2D(SceneSampler, intput.TexCoord);
//
//	float2 texCoord = input.TexCoord - HalfPixel;
//	// Look up four values from the normal/depth texture, offset along the
//	// four diagonals from the pixel we are currently shading.
//	float2 edgeOffset = EdgeWidth / ScreenResolution;
//
//	float4 n1 = tex2D(NormalSampler, texCoord + float2(-1, -1) * edgeOffset);
//	float4 n2 = tex2D(NormalSampler, texCoord + float2(1,  1) * edgeOffset);
//	float4 n3 = tex2D(NormalSampler, texCoord + float2(-1,  1) * edgeOffset);
//	float4 n4 = tex2D(NormalSampler, texCoord + float2(1, -1) * edgeOffset);
//
//	n1.a = tex2D(DepthMapSampler, texCoord + float2(-1, -1) * edgeOffset);
//	n2.a = tex2D(DepthMapSampler, texCoord + float2(1, 1) * edgeOffset);
//	n3.a = tex2D(DepthMapSampler, texCoord + float2(-1, 1) * edgeOffset);
//	n4.a = tex2D(DepthMapSampler, texCoord + float2(1, -1) * edgeOffset);
//
//	// Work out how much the normal and depth values are changing.
//	float4 diagonalDelta = abs(n1 - n2) + abs(n3 - n4);
//
//	float normalDelta = dot(diagonalDelta.xyz, 1);
//	float depthDelta = diagonalDelta.w;
//
//	// Filter out very small changes, in order to produce nice clean results.
//	normalDelta = 0.25 * saturate((normalDelta - NormalThreshold) * NormalSensitivity);
//	depthDelta = saturate((depthDelta - DepthThreshold) * DepthSensitivity);
//
//	// Does this pixel lie on an edge?
//	float edgeAmount = saturate(normalDelta + depthDelta) * EdgeIntensity;
//
//	// Apply the edge detection result to the main scene color.
//	//scene *= (1 - edgeAmount);
//	float3 factor = 0;// lerp(1, 0, edgeAmount);
//
//	return float4(factor, edgeAmount);
//}



technique Technique_ApplyPostLighting
{
	// Apply SSR
    pass Pass1
    {
        VertexShader = compile VS_SHADERMODEL VS_Main();
        PixelShader = compile PS_SHADERMODEL PS_ApplySSR();
    }
}







