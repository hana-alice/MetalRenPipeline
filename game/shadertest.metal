//
//  shader.metal
//  LearnMetal
//
//  Created by 李泽强 on 2020/12/6.
//

#include <metal_stdlib>
#import "customtypes.h"

using namespace metal;

struct RasterizeData
{
    float4 clipSpacePos[ [position] ];
    float3 color;
    float2 texCoords;
};

vertex RasterizeData vertsShader(uint vertexID[[vertex_id]],
                                 constant Vertex* vertsArr[[buffer(VERTEX)]],
                                 constant UniformMatrix* matrix[ [buffer(MATRIX)] ] )
{
    RasterizeData out;
    out.clipSpacePos = matrix->projMat * matrix->modelMat * vertsArr[vertexID].pos;
    out.texCoords = vertsArr[vertexID].texCoords;
    out.color = vertsArr[vertexID].color;
    return out;
}

fragment float4 samplingShader(RasterizeData input [[stage_in]], texture2d<half> colorTex[[texture(0)]])
{
    constexpr sampler texSampler (mag_filter::linear, min_filter::linear);
    //half4 color = colorTex.sample(texSampler, input.texCoords);
    half4 color = half4(input.color[0], input.color[1], input.color[2], 1);
    return float4(color);
}
