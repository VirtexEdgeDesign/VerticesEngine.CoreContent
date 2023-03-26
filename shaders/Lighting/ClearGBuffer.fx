
#include "../include/vx_core.cginc"
#include "../include/vx_util.cginc"

float4 SkyColour = float4(0.25,0.55,0.9,0);


struct PixelShaderOutput
{
    float4 Color : COLOR0;
    float4 Normal : COLOR1;
    float4 Depth : COLOR2;
	float4 Dist : COLOR3;
};

PixelShaderOutput PixelShaderFunction(vx_v2f_img input)
{
    PixelShaderOutput output;
    //black color
    output.Color = float4(1.0, 0.0, 1, 1);
    //output.Color.a = 1.0f;
    //when transforming 0.5f into [-1,1], we will get 0.0f
    output.Normal.rgb = 0.5f;
    //no specular power
    output.Normal.a = 0.0f;
    //max depth
    output.Depth = 0.0f;

	output.Dist = 0.0f;
    return output;
}

technique Technique1
{
    pass Pass1
    {
		VertexShader = compile VS_SHADERMODEL VXImageVertexShaderFunction();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}