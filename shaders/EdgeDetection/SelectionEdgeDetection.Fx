/*
@Title: Vertices Engine
@autor: Robert Roe
@brief:	Cartoon edge detection
*/

#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"


// Settings controlling the edge detection filter.
float EdgeWidth = 1;
float EdgeIntensity = 1;

// How sensitive should the edge detection be to tiny variations in the input data?
// Smaller settings will make it pick up more subtle edges, while larger values get
// rid of unwanted noise.
float NormalThreshold = 0.5;
float DepthThreshold = 0.1;

// How dark should the edges get in response to changes in the input data?
float NormalSensitivity = 1;
float DepthSensitivity = 10;

// How should the sketch effect respond to changes of brightness in the input scene?
float SketchThreshold = 0.1;
float SketchBrightness = 0.333;

// Randomly offsets the sketch overlay pattern to create a hand-drawn animation effect.
float2 SketchJitter;

// Pass in the current screen resolution.
float2 ScreenResolution;

// the edge colour
float4 EdgeColour;

// This texture contains the main scene image, which the edge detection
// and/or sketch filter are being applied over the top of.
texture SceneTexture;

sampler SceneSampler : register(s0) = sampler_state
{
    Texture = (SceneTexture);
    
    MinFilter = Linear;
    MagFilter = Linear;
    
    AddressU = Clamp;
    AddressV = Clamp;
};


// This texture contains normals (in the color channels) and depth (in alpha)
// for the main scene image. Differences in the normal and depth data are used
// to detect where the edges of the model are.
texture NormalTexture;

sampler NormalSampler : register(s1) = sampler_state
{
    Texture = (NormalTexture);
    
    MinFilter = Linear;
    MagFilter = Linear;
    
    AddressU = Clamp;
    AddressV = Clamp;
};


// This texture contains the Depth Value.
texture DepthTexture;

sampler DepthSampler : register(s2) = sampler_state
{
    Texture = (DepthTexture);

	MinFilter = Point;
	MagFilter = Point;

	AddressU = Clamp;
	AddressV = Clamp;
};

// texture EntityMaskMap;
// sampler EntityMaskSampler : register(s3) = sampler_state
// {
//     Texture = (EntityMaskMap);

//     MinFilter = Linear;
//     MagFilter = Linear;
    
//     AddressU = Clamp;
//     AddressV = Clamp;
// };

texture SceneDepthTexture;

sampler SceneDepthSampler : register(s3) = sampler_state
{
    Texture = (SceneDepthTexture);

	MinFilter = Point;
	MagFilter = Point;

	AddressU = Clamp;
	AddressV = Clamp;
};

// Pixel shader applies the edge detection and/or sketch filter postprocessing.
// It is compiled several times using different settings for the uniform boolean
// parameters, producing different optimized versions of the shader depending on
// which combination of processing effects is desired.
float4 MainPS(vx_v2f_img input) : COLOR0
{    
	float2 uv = input.uv;
    // Look up the original color from the main scene.
    float3 scene = tex2D(SceneSampler, uv);
    
    // float3 mask = tex2D(EntityMaskSampler, uv);

    float3 rma = tex2D(RMASampler, uv);
    
    float pxlDepth = tex2D(DepthSampler, uv).r;
    float sceneDepth = tex2D(SceneDepthSampler, uv).r;

	uv = uv - HalfPixel;

    // Look up four values from the normal/depth texture, offset along the
    // four diagonals from the pixel we are currently shading.
    float2 edgeOffset = EdgeWidth / ScreenResolution;
    
    float4 n1 = tex2D(NormalSampler, uv + float2(-1, -1) * edgeOffset);
    float4 n2 = tex2D(NormalSampler, uv + float2( 1,  1) * edgeOffset);
    float4 n3 = tex2D(NormalSampler, uv + float2(-1,  1) * edgeOffset);
    float4 n4 = tex2D(NormalSampler, uv + float2( 1, -1) * edgeOffset);

	n1.a = tex2D(DepthSampler, uv + float2(-1, -1) * edgeOffset);
	n2.a = tex2D(DepthSampler, uv + float2(1, 1) * edgeOffset);
	n3.a = tex2D(DepthSampler, uv + float2(-1, 1) * edgeOffset);
	n4.a = tex2D(DepthSampler, uv + float2(1, -1) * edgeOffset);

    // Work out how much the normal and depth values are changing.
    float4 diagonalDelta = abs(n1 - n2) + abs(n3 - n4);

    float normalDelta = dot(diagonalDelta.xyz, 1);
    float depthDelta = diagonalDelta.w;
    
    // Filter out very small changes, in order to produce nice clean results.
	normalDelta = 0.25 * saturate((normalDelta - NormalThreshold) * NormalSensitivity);
    depthDelta = saturate((depthDelta - DepthThreshold) * DepthSensitivity);

    // Does this pixel lie on an edge?
    float edgeAmount = saturate(normalDelta + depthDelta) * EdgeIntensity * saturate(1 - rma.g);
        
    // Apply the edge detection result to the main scene color.
    //float3 finalscene = scene * (1 - edgeAmount);
    float3 finalscene = lerp(scene, EdgeColour.rgb, edgeAmount);
    
    return float4(finalscene, 1);
    //return lerp(float4(finalscene, 1), float4(scene, 1), mask.r);
}


// Compile the pixel shader for doing edge detection without any sketch effect.
technique EdgeDetect
{
    pass P0
    {
		//VertexShader = compile VS_SHADERMODEL VXImageVertexShaderFunction();
		PixelShader = compile PS_SHADERMODEL MainPS();
    }
}