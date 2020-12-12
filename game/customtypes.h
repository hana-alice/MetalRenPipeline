//
//  types.h
//  game
//
//  Created by 李泽强 on 2020/12/6.
//

#ifndef types_h
#define types_h

#import <simd/simd.h>

typedef struct
{
    vector_float4 pos;
    vector_float3 color;
    vector_float2 texCoords;
}Vertex;

typedef struct
{
    matrix_float4x4 projMat;
    matrix_float4x4 modelMat;
}UniformMatrix;

enum VertexInputIndex
{
    VERTEX = 0,
    MATRIX
};

enum FragmentInputIndex
{
    TEXTURE = 0
};

#endif /* types_h */
