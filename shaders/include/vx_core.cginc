/*
@Title: Vertices Engine - Core Shader variables and functions
@autor: Robert Roe
@brief:	This holds the core Vertices Engine shader functions used in Vertices Engine Shaders
*/
#ifndef VX_CORE
#define VX_CORE

#if OPENGL
	#define SV_POSITION POSITION
	#define VS_SHADERMODEL vs_3_0
	#define PS_SHADERMODEL ps_3_0
#else
	//#define SV_POSITION POSITION0
	#define VS_SHADERMODEL vs_4_0
	#define PS_SHADERMODEL ps_4_0
#endif

// GLOBAL CONSTANTS
//**********************************
#define VX_PI            3.14159265359f
#define VX_TWO_PI        6.28318530718f
#define VX_FOUR_PI       12.56637061436f
#define VX_INV_PI        0.31830988618f
#define VX_INV_TWO_PI    0.15915494309f
#define VX_INV_FOUR_PI   0.07957747155f
#define VX_HALF_PI       1.57079632679f
#define VX_INV_HALF_PI   0.636619772367f


// GLOBAL PROPERTIES
//**********************************

// World Transform
matrix VX_MATRIX_WORLD;

// World*View*Projection single matrix computed on the CPU for each entity
float4x4 VX_MATRIX_WVP;

// World inverse transpose
float4x4 VX_MATRIX_W_INV_T;

// The Camera position
float3 VX_CAMERA_POS;

// The camera view matrix
matrix VX_CAMERA_VIEW;

// The camera projection matrix
matrix VX_CAMERA_PROJ;

// the camera's inverse view-projection matrix
matrix VX_CAMERA_INV_VP;

// The main light direction
float3 VX_MAINLIGHTDIR;

float4 VX_ProjectionParams;

float2 VX_UV0_OFFSET;
float2 VX_UV1_OFFSET;

// Time (t = time since current level load) values from Vertices Engine
float4 _Time; // (t/20, t, t*2, t*3)
float4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)
float4 _CosTime; // cos(t/8), cos(t/4), cos(t/2), cos(t)
float4 VX_DeltaTime; // dt, 1/dt, smoothdt, 1/smoothdt

// The light direction is shared between the Lambert and Toon lighting techniques.
float3 LightDirection = normalize(float3(1, 1, 1));

// Image Effect Properties
float2 HalfPixel;
float4x4 MatrixTransform;

// STRUCTS
// ******************************************

/*
struct appdata_base: vertex shader input with position, normal, one texture coordinate.
struct appdata_tan: vertex shader input with position, normal, tangent, one texture coordinate.
struct appdata_full: vertex shader input with position, normal, tangent, vertex color and two texture coordinates.
struct appdata_img: vertex shader input with position and one texture coordinate.
*/


// vertex shader input with position, normal, one texture coordinate.
struct vx_a2v_base
{
	float4 vertex : POSITION0;
	float3 normal : NORMAL0;
	float2 uv : TEXCOORD0;
};

// vertex shader input with position, normal, tangent, one texture coordinate.
struct vx_a2v_tan
{
	float4 vertex : POSITION0;
	float3 normal : NORMAL0;
	float2 uv : TEXCOORD0;
	float3 binormal	: BINORMAL0;
	float3 tangent	: TANGENT0;
};

// vertex shader input with position, normal, tangent, vertex color and two texture coordinates.
struct vx_a2v_full
{
	float4 vertex : POSITION0;
	float3 normal : NORMAL0;
	float2 uv : TEXCOORD0;
	//float2 uv1 : TEXCOORD1;
	float3 binormal	: BINORMAL0;
	float3 tangent	: TANGENT0;
};

// vertex shader input with position and one texture coordinate.
struct vx_a2v_img
{
	float3 vertex : POSITION0;
	float2 uv : TEXCOORD0;
};

// vertex shader input with position and one texture coordinate.
struct vx_v2f_img
{
	float4 position : POSITION0;
	float2 uv : TEXCOORD0;
};

// the intial vertex input declaration.
struct vx_v2f_base
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
};

// the full VS to PS data struct
struct vx_v2f_full
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
	//float2 uv1 : TEXCOORD1;
	float LightAmount : TEXCOORD1;
	float3 WorldNormal : TEXCOORD2;
	float4x4 tangentToWorld : TEXCOORD3;
};




//The RMA map that's applied to this entity. The only difference
texture maps_RMA;
sampler RMASampler = sampler_state
{
	Texture = (maps_RMA);

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;

	AddressU = Wrap;
	AddressV = Wrap;
};

// emissive map
texture EmissiveMap;
sampler emissiveSampler = sampler_state
{
	Texture = (EmissiveMap);
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	Mipfilter = LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

float EmissiveIntensity = 1;

float4 EmissiveColour = float4(1, 1, 1, 1);

texture AlphaMaskTexture;
sampler AlphaMaskSampler = sampler_state
{
	Texture = (AlphaMaskTexture);

	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;

	AddressU = Wrap;
	AddressV = Wrap;
};
float AlphaMaskCutoff = 0;



// DEFAULT SHADER PROGRAMS
// ******************************************

vx_v2f_img VXImageVertexShaderFunction(vx_a2v_img input)
{
    vx_v2f_img output;
    output.position = float4(input.vertex,1);
    output.uv = input.uv;
    return output;
}

// Default Vertex Shader which should be used for normal mapping
vx_v2f_base VXBasicVertexShader(vx_a2v_base input)
{
	vx_v2f_base output = (vx_v2f_base)0;

	// Apply camera matrices to the input position.
	output.vertex = mul(input.vertex, VX_MATRIX_WVP);

	// Copy across the input texture coordinate.
	output.uv = input.uv + VX_UV0_OFFSET;
	
	return output;
}

// Default Vertex Shader which should be used for normal mapping
vx_v2f_full VXFullVertexShader(vx_a2v_full input)
{
	vx_v2f_full output = (vx_v2f_full)0;

	// Apply camera matrices to the input position.
	output.vertex = mul(input.vertex, VX_MATRIX_WVP);

	// Copy across the input texture coordinate.
	output.uv = input.uv + VX_UV0_OFFSET;
	//output.uv1 = input.uv1 + VX_UV1_OFFSET;
	output.LightAmount = 1;
	// calculate tangent space to world space matrix using the world space tangent,
	// binormal, and normal as basis vectors
	output.tangentToWorld[0] = mul(input.tangent, VX_MATRIX_WORLD);
	output.tangentToWorld[1] = mul(input.binormal, VX_MATRIX_WORLD);
	output.tangentToWorld[2] = mul(input.normal, VX_MATRIX_WORLD);
	output.tangentToWorld[3] = mul(input.vertex, VX_MATRIX_WORLD);

	// Compute the overall lighting brightness.
	output.WorldNormal = mul((input.normal), VX_MATRIX_WORLD);
	output.LightAmount = abs(dot(output.WorldNormal, LightDirection));
	//output.WorldNormal =  worldNormal;
	return output;
}

#endif