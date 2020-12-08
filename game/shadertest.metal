//
//  shader.metal
//  LearnMetal
//
//  Created by 李泽强 on 2020/12/6.
//

#include <metal_stdlib>
#import "shaderTypes.h"

using namespace metal;

struct RasterizeData
{
    float4 clipSpacePos[ [position] ];
    
    float2 texCoords;
};

vertex RasterizeData vertsShader(uint vertexID[[vertex_id]], constant Vertex* vertsArr[[buffer(0)]])
{
    return {vertsArr[vertexID].pos, vertsArr[vertexID].texCoords};
}

fragment float4 samplingShader(RasterizeData input [[stage_in]], texture2d<half> colorTex[[texture(0)]])
{
    constexpr sampler texSampler (mag_filter::linear, min_filter::linear);
    half4 color = colorTex.sample(texSampler, input.texCoords);
    return float4(color);
}
