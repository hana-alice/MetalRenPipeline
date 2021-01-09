//
//  viewController.mm
//  LearnMetal
//
//  Created by 李泽强 on 2020/12/6.
//

#import <Foundation/Foundation.h>
#import "customtypes.h"
#import "AppDelegate.h"
#import "viewController.h"
#import "utils/AAPLMesh.h"
#import "utils/AAPLRendererUtils.h"
#import "utils/AAPLShaderTypes.h"
#import <simd/simd.h>

constexpr unsigned int SAMPLE_COUNT = 8;


@interface TestViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView*  _view;
@property (nonatomic, assign) vector_uint2 _viewportSize;
@property (nonatomic, strong) id<MTLRenderPipelineState> _pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> _commandQueue;
@property (nonatomic, strong) id<MTLTexture> _texture;
@property (nonatomic, strong) id<MTLBuffer> _verts;
@property (nonatomic, strong) id<MTLBuffer> _indices;
@property (nonatomic, assign) NSUInteger _numIndices;
@property (nonatomic, assign) NSUInteger _numVerts;
@end

@implementation TestViewController
{
    Camera _camera;
    AAPLActorData* _actor;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self._view = [[MTKView alloc] initWithFrame:self.view.bounds];
    self._view.sampleCount = SAMPLE_COUNT;
    self._view.device = MTLCreateSystemDefaultDevice();
    self.view = self._view;
    self._view.delegate = self;
    self._viewportSize = (vector_uint2){(uint)self._view.drawableSize.width, (uint)self._view.drawableSize.height};
    
    
}

-(void) viewDidAppear
{
    [self customInit];
}

-(void) customInit
{
    [self setupPipeline];
    [self setupVerts];
    [self setupTexture];
    [self loadModel];
}

-(void)init
{
    [self customInit];
}

-(void)destroy
{
    //TODO;
}

-(void) setupPipeline
{
    id<MTLLibrary> defaultLibrary = [self._view.device newDefaultLibrary];
    id<MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertsShader"];
    id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"samplingShader"];
    
    MTLRenderPipelineDescriptor* pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.vertexFunction = vertexFunc;
    pipelineDesc.fragmentFunction = fragmentFunc;
    pipelineDesc.sampleCount = SAMPLE_COUNT;
    pipelineDesc.colorAttachments[0].pixelFormat = self._view.colorPixelFormat;
    self._pipelineState = [self._view.device newRenderPipelineStateWithDescriptor:pipelineDesc
                                                                            error:NULL];
    self._commandQueue = [self._view.device newCommandQueue];
}

-(void) setupVerts
{
    const Vertex quadVerts[] =
    {
        {{-0.5f, 0.5f, 0.0f, 1.0f},      {0.0f, 0.0f, 0.5f},       {0.0f, 1.0f}},//左上
        {{0.5f, 0.5f, 0.0f, 1.0f},       {0.0f, 0.5f, 0.0f},       {1.0f, 1.0f}},//右上
        {{-0.5f, -0.5f, 0.0f, 1.0f},     {0.5f, 0.0f, 1.0f},       {0.0f, 0.0f}},//左下
        {{0.5f, -0.5f, 0.0f, 1.0f},      {0.0f, 0.0f, 0.5f},       {1.0f, 0.0f}},//右下
        {{0.0f, 0.0f, 1.0f, 1.0f},       {1.0f, 1.0f, 1.0f},       {0.5f, 0.5f}},//顶点
    };
    
    const int indices[] = {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3
    };
    
    self._verts = [self._view.device newBufferWithBytes:quadVerts
                                                 length:sizeof(quadVerts)
                                                 options:MTLResourceStorageModeShared];
    
    self._indices = [self._view.device newBufferWithBytes:indices
                                                   length:sizeof(indices)
                                                  options:MTLResourceStorageModeShared];
    
    self._numVerts = sizeof(quadVerts) / sizeof(Vertex);
    self._numIndices = sizeof(indices) / sizeof(indices[0]);
}

-(void) setupTexture
{
    MTKTextureLoader* texLoader = [[MTKTextureLoader alloc] initWithDevice:self._view.device];
    NSDictionary* texLoadOption =
    @{
        MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
        MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate),
        MTKTextureLoaderOptionSRGB: @(false)
    };
    
    NSError* err;
    self._texture = [texLoader newTextureWithName:@"youma"
                                      scaleFactor:1.0
                                           bundle:nil
                                          options:texLoadOption
                                            error:&err];
    if(err)
    {
        NSLog(@"Error creating texture %@", err.localizedDescription);
    }
}

-(void) loadModel
{
    MTLVertexDescriptor* mtlVertexDesc = [[MTLVertexDescriptor alloc] init];
    //verts pos
    mtlVertexDesc.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
    mtlVertexDesc.attributes[VertexAttributePosition].offset = 0;
    mtlVertexDesc.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;//stage_in buffer index;
    
    //tex
    mtlVertexDesc.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    mtlVertexDesc.attributes[VertexAttributeTexcoord].offset = 0;
    mtlVertexDesc.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;
    
    //norm
    mtlVertexDesc.attributes[VertexAttributeNormal].format = MTLVertexFormatHalf4;
    mtlVertexDesc.attributes[VertexAttributeNormal].offset = sizeof(float) * 2;
    mtlVertexDesc.attributes[VertexAttributeNormal].bufferIndex = BufferIndexMeshGenerics;
    
    //pos buffer layout
    mtlVertexDesc.layouts[BufferIndexMeshPositions].stride = sizeof(float) * 3;
    mtlVertexDesc.layouts[BufferIndexMeshPositions].stepRate = 1;
    mtlVertexDesc.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;
    
    //general buffer layout
    mtlVertexDesc.layouts[BufferIndexMeshGenerics].stride = sizeof(float) * 2 + sizeof(float) * 2;//float *2 + half_float *4
    mtlVertexDesc.layouts[BufferIndexMeshGenerics].stepRate = 1;
    mtlVertexDesc.layouts[BufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;
    
    id<MTLLibrary> defaultLibrary = [self._view.device newDefaultLibrary];
    id<MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertsShader"];
    id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"samplingShader"];
    
    MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexDescriptor = mtlVertexDesc;
    pipelineDescriptor.inputPrimitiveTopology = MTLPrimitiveTopologyClassTriangle;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    pipelineDescriptor.sampleCount = self._view.sampleCount;
    pipelineDescriptor.depthAttachmentPixelFormat = self._view.depthStencilPixelFormat;
    pipelineDescriptor.label = @"Sponza!";
    
    NSError* error = nullptr;
    id<MTLRenderPipelineState> pipelineState = [self._view.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    NSAssert(pipelineState, @"%@", error);
    
    MDLVertexDescriptor* mdlVertexDesc = MTKModelIOVertexDescriptorFromMetal(mtlVertexDesc);
    mdlVertexDesc.attributes[VertexAttributePosition].name = MDLVertexAttributePosition;
    mdlVertexDesc.attributes[VertexAttributeTexcoord].name = MDLVertexAttributeTextureCoordinate;
    mdlVertexDesc.attributes[VertexAttributeNormal].name = MDLVertexAttributeNormal;
    
    NSURL* modelFileURL = [[NSBundle mainBundle] URLForResource:@"model/sponza" withExtension:@"obj"];
    NSAssert(modelFileURL, @"model load failed %@", modelFileURL.absoluteString);
    
    MDLAxisAlignedBoundingBox sponzaAABB;
    NSArray<AAPLMesh*>* sponzaMeshes = [AAPLMesh newMeshesFromUrl:modelFileURL
                                          modelIOVertexDescriptor:mdlVertexDesc
                                                      metalDevice:self._view.device
                                                            error:&error
                                                             aabb:sponzaAABB];
    NSAssert(sponzaMeshes, @"sponza model load failed %@", error);
    
    vector_float4 sponzaSphere;
    sponzaSphere.xyz = (sponzaAABB.maxBounds + sponzaAABB.minBounds) * 0.5f;
    sponzaSphere.w = vector_length((sponzaAABB.maxBounds - sponzaAABB.minBounds) * 0.5f);
    
    _actor = [AAPLActorData new];
    _actor.translation = (vector_float3){0.0f, 0.0f, 0.0f};
    _actor.diffuseMultiplier = (vector_float3){1.0f, 1.0f, 1.0f};
    _actor.bSphere = sponzaSphere;
    _actor.gpuProg = pipelineState;
    _actor.meshes = sponzaMeshes;
    _actor.passFlags = EPassFlags::ALL_PASS;
    
}

-(void) renderMesh:(id<MTLRenderCommandEncoder>) renderEncoder
{
    [renderEncoder pushDebugGroup:@"renderMesh"];
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setRenderPipelineState:_actor.gpuProg];
    [renderEncoder setFragmentTexture:self._texture atIndex:TextureIndexBaseColor];
    
    for (AAPLMesh* mesh in _actor.meshes) {
        MTKMesh* mtkMesh = mesh.metalKitMesh;
        for (uint32_t bufferIndex = 0; bufferIndex < mtkMesh.vertexBuffers.count; bufferIndex++) {
            MTKMeshBuffer* vertexBuffer = mtkMesh.vertexBuffers[bufferIndex];
            if (vertexBuffer) {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }
        
        for (AAPLSubmesh* subMesh in mesh.submeshes) {
            id<MTLTexture> tex;
            tex = subMesh.textures[TextureIndexBaseColor];
            [renderEncoder setFragmentTexture:tex atIndex:TextureIndexBaseColor];
            
            MTKSubmesh* mtkSubMesh = subMesh.metalKitSubmmesh;
            [renderEncoder drawIndexedPrimitives:mtkSubMesh.primitiveType
                                      indexCount:mtkSubMesh.indexCount
                                       indexType:mtkSubMesh.indexType
                                     indexBuffer:mtkSubMesh.indexBuffer.buffer
                               indexBufferOffset:mtkSubMesh.indexBuffer.offset];
        }
    }
    
    [renderEncoder popDebugGroup];
}

-(void) setupCamera
{
    //TODO: encapsulate camera later.
    struct Camera cam = _camera;
    cam.position = (vector_float3){3.0f, 3.0f, -1.0f};
    cam.target = (vector_float3){0.0f, 0.0f, 0.0f};
    cam.rotation = 0.0f;
    cam.aspectRatio = self._viewportSize.x / (float)self._viewportSize.y;
    cam.fovVert_Half = 5.0f * M_PI / 180.0f;
}

-(void) setupMatrix: (id<MTLRenderCommandEncoder>) renEncoder
{
    float aspect = self._viewportSize.x / (float)self._viewportSize.y;
    matrix_float4x4 modelMat = matrix_identity_float4x4;
    matrix_float4x4 viewMat = matrix_look_at_left_hand((vector_float3){3.0f, 3.0f, -1.0f}, (vector_float3){0.0f, 0.0f, 0.0f}, (vector_float3){0.0f, 1.0f, 0.0f});
    matrix_float4x4 projMat = matrix_perspective_left_hand(50.0f * M_PI / 180.0f, aspect, 0.1f, 100.0f);
    //matrix_float4x4 projMat = matrix4x4_translation(0.0f, 0.0f, 0.0f);
    static float rotation = 0.0f;
    rotation += M_PI/120.0f;
    
    UniformMatrix mat = {modelMat, viewMat, projMat};
    
    [renEncoder setVertexBytes:&mat
                        length:sizeof(UniformMatrix)
                       atIndex:MATRIX];
}

-(void) drawInMTKView:(MTKView *)view
{
    id<MTLCommandBuffer> cmdBuffer = [self._commandQueue commandBuffer];
    MTLRenderPassDescriptor* renderPassDesc = self._view.currentRenderPassDescriptor;
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 1.0, 1.0, 1.0);
    id<MTLRenderCommandEncoder> renEncoder = [cmdBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    [renEncoder setViewport:(MTLViewport){0.0, 0.0, (double)self._viewportSize.x, (double)self._viewportSize.y, 0.1f, 100.0f}];

    [self renderMesh:renEncoder];
    
    [renEncoder endEncoding];
    
    [cmdBuffer presentDrawable:self._view.currentDrawable];
    [cmdBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {

}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

@end
