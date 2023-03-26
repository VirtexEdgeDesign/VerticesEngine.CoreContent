//-----------------------------------------------------------------------------
// Shadow.h
//
// Virtices Engine
// Collection of Common Cascade Shadow Mapping Code for use in 
// both the CascadeShadowShader.fx as well as in any other *.fx
// files which use it.
//
// It is adapted from theomader's source code here: http://dev.theomader.com/cascaded-shadow-mapping-2/
// It is released under the MIT License (https://opensource.org/licenses/mit-license.php)
//
// It has been modified for the Virtices Engine.
//-----------------------------------------------------------------------------


#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"


//			Shadow Properties
//*********************************************************************************************
float4x4 ViewProjection_Sdw;
float2 BlurStep_Sdw;
float2 DepthBias_Sdw;
bool ShadowDebug = false;



//**************************************************
//			Cascade Shadow Mapping Shader
//**************************************************

/*
	This Technique //TODO Description
*/

struct VertexShaderInput_Sdw
{
    float4 Position			: SV_POSITION;
};

struct VertexShaderOutput_Sdw
{
    float4 Position			: SV_POSITION;
	float  Depth			: COLOR0;
};

VertexShaderOutput_Sdw ShadowVS(VertexShaderInput_Sdw input, float4x4 worldTransform)
{
    VertexShaderOutput_Sdw output = (VertexShaderOutput_Sdw)0;

    float4 worldPosition = mul(input.Position, worldTransform);
    output.Position = mul(worldPosition, ViewProjection_Sdw);

    output.Depth = output.Position.z / output.Position.w;

    return output;
}

VertexShaderOutput_Sdw ShadowInstancedVS( VertexShaderInput_Sdw input, float4x4 instanceTransform : TEXCOORD2)
{
	float4x4 worldTransform = mul( transpose(instanceTransform), VX_MATRIX_WORLD);
	return ShadowVS(input, worldTransform); 
}

VertexShaderOutput_Sdw ShadowNonInstancedVS( VertexShaderInput_Sdw input )
{
	return ShadowVS(input, VX_MATRIX_WORLD);
}

float4 ShadowPS(VertexShaderOutput_Sdw input) : COLOR0
{
	float depthSlopeBias = max(
		abs(ddx(input.Depth)), 
		abs(ddy(input.Depth))
	);
	return float4( input.Depth + depthSlopeBias * DepthBias_Sdw.x + DepthBias_Sdw.y, input.Depth*input.Depth, 0, 0 );
}

technique Shadow
{
    pass Pass1
    {
		VertexShader = compile VS_SHADERMODEL ShadowNonInstancedVS();
        PixelShader = compile PS_SHADERMODEL ShadowPS();
    }
}