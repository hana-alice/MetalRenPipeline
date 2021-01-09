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
    AAPLActorData* actor;
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
    
    [self customInit];
}

-(void) customInit
{
    [self setupPipeline];
    [self setupVerts];
    [self setupTexture];
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
    [renEncoder setRenderPipelineState: self._pipelineState];
    
    [self setupMatrix:renEncoder];
    
    [renEncoder setVertexBuffer:self._verts
                         offset:0
                        atIndex:VERTEX];
    [renEncoder setFragmentTexture:self._texture
                           atIndex:TEXTURE];
    [renEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:self._numIndices
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self._indices
                    indexBufferOffset:0];
    [renEncoder endEncoding];
    [cmdBuffer presentDrawable:self._view.currentDrawable];
    [cmdBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {

}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

@end
