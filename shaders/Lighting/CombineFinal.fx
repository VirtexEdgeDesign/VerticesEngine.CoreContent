#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	#define VS_SHADERMODEL vs_4_0
	#define PS_SHADERMODEL ps_4_0
#endif


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

// normals, and specularPower in the alpha channel
texture normalMap;
sampler normalSampler = sampler_state
{
	Texture = (normalMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};


// This texture contains the Depth Value.
texture DepthMap;
sampler DepthSampler : register(s2) = sampler_state
{
	Texture = (DepthMap);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	Mipfilter = POINT;
};

// This texture contains the Depth Value.
texture ReflectionMap;
sampler ReflectionMapSampler = sampler_state
{
	Texture = (ReflectionMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
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


// This is the Sun Mask Texture which holds the image of the sun.
texture2D FogVolumeTexture;
sampler FogVolumeSampler = sampler_state
{
	Texture = <FogVolumeTexture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = wrap;
	AddressV = wrap;
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

float2 HalfPixel;
VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output;
    output.Position = float4(input.Position,1);
    output.TexCoord = input.TexCoord + HalfPixel;
    return output;
}



bool DoFog = false;

float FogNear = 25;
float FogFar = 250;
float FogHeight = 100;
float4 FogColor = 0.75f;




//Computes the Fog Factor
float ComputeFogFactor(float d, float y)
{
	float fogHeight = clamp((d - FogNear) / (FogFar - FogNear), 0, 1);
	return fogHeight * clamp((FogHeight-y) / (FogHeight - 0), 0, 1);
}

// The inverse View Projection
float4x4 InverseViewProjection;

float3 VX_CAMERA_POS;


// Gets the 3D Position based on the UV and Depth Coorrdinates
float3 GetWorldPosition(float2 uv, float depth)
{
	float4 pos = 1.0f;

	// Convert the UV values.
	pos.x = (uv.x * 2.0f - 1.0f);
	pos.y = -(uv.y * 2.0f - 1.0f);

	pos.z = depth;

	//Transform Position from Homogenous Space to World Space 
	pos = mul(pos, InverseViewProjection);

	pos /= pos.w;

	return pos.xyz;
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
	// Get the Colour of the Scene Currently
    float3 diffuseColor = tex2D(SceneMapSampler,input.TexCoord).rgb;

	float4 reflColor = tex2D(ReflectionMapSampler, input.TexCoord);

	diffuseColor = lerp(diffuseColor, reflColor.rgb, reflColor.a);

	// Now get the light map colour
    float4 light = tex2D(lightSampler,input.TexCoord);

	// Finally get the defferred rendering map data
	float4 defferred = tex2D(SurfaceDataSampler, input.TexCoord);

    float3 diffuseLight = light.rgb;
    float specularLight = light.a;
	
	// This is the scene lit
    float4 litScene = float4((diffuseColor * defferred.r + diffuseLight/1 + specularLight), 1);


	if(DoFog==true)
	{
		// get the depth
		float depth = tex2D(DepthSampler, input.TexCoord);

		float3 worldPos = GetWorldPosition(input.TexCoord, depth);
		float y = worldPos.y;
		//float2 xy = worldPos.xz / 50;
		//float fog = ComputeFogFactor(length(worldPos - VX_CAMERA_POS), y) * (1 - tex2D(FogVolumeSampler, xy).r);
		float fog = ComputeFogFactor(length(worldPos - VX_CAMERA_POS), y);
		litScene.rgb = lerp(litScene.rgb, FogColor, fog);
	}

	return litScene;
}




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

// Pass in the current screen resolution.
float2 ScreenResolution;

bool DoEdgeDetect = false;
// Pixel shader applies the edge detection and/or sketch filter postprocessing.
// It is compiled several times using different settings for the uniform boolean
// parameters, producing different optimized versions of the shader depending on
// which combination of processing effects is desired.
float4 PS_ApplyEdgeDetec(VertexShaderOutput input) : COLOR0
{
	if (DoEdgeDetect==true)
	{
		

		// Look up the original color from the main scene.
		//float3 scene = tex2D(SceneSampler, intput.TexCoord);

		float2 texCoord = input.TexCoord + HalfPixel;
		// Look up four values from the normal/depth texture, offset along the
		// four diagonals from the pixel we are currently shading.
		float2 edgeOffset = EdgeWidth / ScreenResolution;

		float4 n1 = tex2D(normalSampler, texCoord + float2(-1, -1) * edgeOffset);
		float4 n2 = tex2D(normalSampler, texCoord + float2(1,  1) * edgeOffset);
		float4 n3 = tex2D(normalSampler, texCoord + float2(-1,  1) * edgeOffset);
		float4 n4 = tex2D(normalSampler, texCoord + float2(1, -1) * edgeOffset);

		n1.a = tex2D(DepthSampler, texCoord + float2(-1, -1) * edgeOffset);
		n2.a = tex2D(DepthSampler, texCoord + float2(1, 1) * edgeOffset);
		n3.a = tex2D(DepthSampler, texCoord + float2(-1, 1) * edgeOffset);
		n4.a = tex2D(DepthSampler, texCoord + float2(1, -1) * edgeOffset);

		// Work out how much the normal and depth values are changing.
		float4 diagonalDelta = abs(n1 - n2) + abs(n3 - n4);

		float normalDelta = dot(diagonalDelta.xyz, 1);
		float depthDelta = diagonalDelta.w;

		// Filter out very small changes, in order to produce nice clean results.
		normalDelta = 0.25 * saturate((normalDelta - NormalThreshold) * NormalSensitivity);
		depthDelta = saturate((depthDelta - DepthThreshold) * DepthSensitivity);

		// Does this pixel lie on an edge?
		float edgeAmount = saturate(normalDelta + depthDelta) * EdgeIntensity;

		// Apply the edge detection result to the main scene color.
		//scene *= (1 - edgeAmount);
		float3 factor = 0;// float3(0, 0.5, 1);// lerp(1, 0, edgeAmount);

		if(DoFog==true)
		{
			// get the depth
			float depth = tex2D(DepthSampler, texCoord);

			float3 worldPos = GetWorldPosition(texCoord, depth);

			factor = lerp(factor, FogColor, ComputeFogFactor(length(worldPos - VX_CAMERA_POS), worldPos.y));
		}

		////				  // get the depth
		//float depth = tex2D(DepthSampler, input.TexCoord);

		//float3 worldPos = GetWorldPosition(input.TexCoord, depth);
		//factor = lerp(factor, FogColor, ComputeFogFactor(length(worldPos - VX_CAMERA_POS)));

		return float4(factor * edgeAmount, edgeAmount);
		}
	else
	{
		return 0;
 }
}




// God Rays
// ****************************************************************************

#define NUM_SAMPLES 25

float2 lightScreenPosition;

//float2 TextureScale = float2(4, 4);
//
//float2 TextureSize = float2(1, 1);

float Density = .5f;
float Decay = .95f;
float Weight = 1.0f;
float Exposure = .15f;

bool DoGodRays = true;



// God Ray Mask Generation
// ****************************************************************************

// This is the Sun Mask Texture which holds the image of the sun.
texture2D SunTexture;
sampler SunSampler = sampler_state
{
	Texture = <SunTexture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = clamp;
	AddressV = clamp;
};

float2 TextureScale = float2(4, 4);

float2 TextureSize = float2(1, 1);


float4 PS_GenerateSun(VertexShaderOutput input) : COLOR0
{
	float2 texCoord = (input.TexCoord - lightScreenPosition + TextureSize) * TextureScale;
	return tex2D(DepthSampler, input.TexCoord).r > 0 ? float4 (0, 0, 0, 1) : tex2D(SunSampler, texCoord);
}

technique GenerateSunMaskTechnique
{
	pass Pass1
	{
		VertexShader = compile VS_SHADERMODEL VertexShaderFunction();
		PixelShader = compile PS_SHADERMODEL PS_GenerateSun();
	}
}



float4 PS_ApplyGodRays(VertexShaderOutput input) : COLOR0
{
	if (DoGodRays==true)
	{
		float4 SunColor = tex2D(SunMaskSampler, input.TexCoord);

		// Look up the bloom and original base image colors.
		//float4 base = tex2D(TextureSampler, texCoord);
		//float3 col = tex2D(TextureSampler, texCoord);

		float IlluminationDecay = 0.75f;
		float3 Sample;

		float2 texCoord = input.TexCoord - HalfPixel;

		float2 DeltaTexCoord = (texCoord - lightScreenPosition) * (1.0f / (NUM_SAMPLES)* Density);

		for (int i = 0; i < NUM_SAMPLES; ++i)
		{
			texCoord -= DeltaTexCoord;
			Sample = tex2D(SunMaskSampler, texCoord);
			Sample *= IlluminationDecay * Weight;
			SunColor.rgb += Sample;
			IlluminationDecay *= Decay;
		}

		return float4(SunColor.rgb, SunColor.r);
	}
	else
	{
		return 0;
	}
}



technique Technique_Combine
{
    pass Pass1
    {
        VertexShader = compile VS_SHADERMODEL VertexShaderFunction();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }


	// Apply Edge Detection
	pass Pass2
	{
		VertexShader = compile VS_SHADERMODEL VertexShaderFunction();
		PixelShader = compile PS_SHADERMODEL PS_ApplyEdgeDetec();
	}

	// Apply God Rays
	pass Pass3
	{
		VertexShader = compile VS_SHADERMODEL VertexShaderFunction();
		PixelShader = compile PS_SHADERMODEL PS_ApplyGodRays();
	}
}
