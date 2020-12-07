//
//  viewController.m
//  LearnMetal
//
//  Created by 李泽强 on 2020/12/6.
//

#import <Foundation/Foundation.h>
#import "customtypes.h"
#import "AppDelegate.h"
#import "viewController.h"

@interface TestViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView*  _view;
@property (nonatomic, assign) vector_uint2 _viewportSize;
@property (nonatomic, strong) id<MTLRenderPipelineState> _pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> _commandQueue;
@property (nonatomic, strong) id<MTLTexture> _texture;
@property (nonatomic, strong) id<MTLBuffer> _verts;
@property (nonatomic, assign) NSUInteger _numVerts;

@end

@implementation TestViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self._view = [[MTKView alloc] initWithFrame:self.view.bounds];
    self._view.device = MTLCreateSystemDefaultDevice();
    self.view = self._view;
    self._view.delegate = self;
    self._viewportSize = (vector_uint2){self._view.drawableSize.width, self._view.drawableSize.height};
    
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
    pipelineDesc.colorAttachments[0].pixelFormat = self._view.colorPixelFormat;
    self._pipelineState = [self._view.device newRenderPipelineStateWithDescriptor:pipelineDesc
                                                                            error:NULL];
    self._commandQueue = [self._view.device newCommandQueue];
}

-(void) setupVerts
{
    const Vertex quadVerts[] =
    {
        { {  0.5, -0.5, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -0.5, -0.5, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -0.5,  0.5, 0.0, 1.0 },  { 0.f, 0.f } },

        { {  0.5, -0.5, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -0.5,  0.5, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  0.5,  0.5, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    
    self._verts = [self._view.device newBufferWithBytes:quadVerts
                                                 length:sizeof(quadVerts)
                                                 options:MTLResourceStorageModeShared];
    self._numVerts = sizeof(quadVerts) / sizeof(Vertex);
}

-(void) setupTexture
{
    MTKTextureLoader* texLoader = [[MTKTextureLoader alloc] initWithDevice:self._view.device];
    NSDictionary* texLoadOption =
    @{
        MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
        MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
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

-(void) drawInMTKView:(MTKView *)view
{
    id<MTLCommandBuffer> cmdBuffer = [self._commandQueue commandBuffer];
    MTLRenderPassDescriptor* renderPassDesc = self._view.currentRenderPassDescriptor;
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 1.0, 1.0, 1.0);
    id<MTLRenderCommandEncoder> renEncoder = [cmdBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    [renEncoder setViewport:(MTLViewport){0.0, 0.0, self._viewportSize.x, self._viewportSize.y, -1.0, 1.0}];
    [renEncoder setRenderPipelineState: self._pipelineState];
    [renEncoder setVertexBuffer:self._verts
                         offset:0
                        atIndex:0];
    [renEncoder setFragmentTexture:self._texture
                           atIndex:0];
    [renEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                   vertexStart:0
                   vertexCount:self._numVerts];
    [renEncoder endEncoding];
    [cmdBuffer presentDrawable:self._view.currentDrawable];
    [cmdBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {

}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

@end
