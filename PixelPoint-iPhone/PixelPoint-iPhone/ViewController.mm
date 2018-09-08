//
//  ViewController.m
//  PixelPoint-iPhone
//
//  Created by Kelsey Steeves on 2018-09-01.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import "ViewController.h"

#include "PixelPointRenderer.h"

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *camerasControl;
@property (weak, nonatomic) IBOutlet GLKView *glkView;



@end

@implementation ViewController

AVCaptureVideoPreviewLayer *previewLayer;
AVCaptureVideoDataOutput *videoDataOutput;
BOOL shouldPixelize;
dispatch_queue_t videoDataOutputQueue;
AVCaptureStillImageOutput *stillImageOutput;
UIView *flashView;
BOOL isUsingFrontFacingCamera;
CIDetector *faceDetector;
CGFloat beginGestureScale;
CGFloat effectiveScale;
PixelPointRenderer *renderer;
CGSize imageSize;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupAVCapture];
    
    [_glkView setContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]];
    [_glkView setNeedsDisplay];
    [_glkView setOpaque:NO];
    [_glkView setUserInteractionEnabled:NO];
    
    [EAGLContext setCurrentContext: _glkView.context];
    renderer = new PixelPointRenderer();
}

- (IBAction)pixelize:(id)sender {
    shouldPixelize = [(UISwitch *)sender isOn];
    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:shouldPixelize];
    renderer->clear();
    [_glkView setNeedsDisplay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reorientOutput: (AVCaptureVideoOrientation) newOrientation {
    switch (newOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            //exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            if (isUsingFrontFacingCamera)
            {
                renderer->rotation = M_PI;
                renderer->flip[0] = true;
                renderer->flip[1] = false;
            }
            else
            {
                renderer->rotation = 0.0f;
                renderer->flip[0] = false;
                renderer->flip[1] = false;
            }
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            if (isUsingFrontFacingCamera)
            {
                renderer->rotation = M_PI;
                renderer->flip[0] = false;
                renderer->flip[1] = true;
            }
            else
            {
                renderer->rotation = M_PI;
                renderer->flip[0] = false;
                renderer->flip[1] = false;
            }
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
            if (isUsingFrontFacingCamera)
            {
                renderer->rotation = -M_PI / 2.0f;
                renderer->flip[0] = true;
                renderer->flip[1] = false;
            }
            else
            {
                renderer->rotation = M_PI / 2.0f;
                renderer->flip[0] = false;
                renderer->flip[1] = false;
            }
            break;
        default:
            break;
    }
}

- (void)viewDidLayoutSubviews
{
    // get the new orientation from device
    AVCaptureVideoOrientation newOrientation = [self avOrientationForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    // set the orientation of preview layer :( which will be displayed in the device )
    [previewLayer.connection setVideoOrientation:newOrientation];
    
    // set the orientation of the connection: which will take care of capture
    [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:newOrientation];
    
    [previewLayer setFrame:_previewView.bounds];
    
    [self reorientOutput:newOrientation];
}

- (void)setupAVCapture
{
    NSError *error = nil;
    
    AVCaptureSession *session = [AVCaptureSession new];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // Select a video device, make an input
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (error == nil)
    {
        isUsingFrontFacingCamera = NO;
        if ( [session canAddInput:deviceInput] )
        {
            [session addInput:deviceInput];
        }
        
        // Make a still image output
        stillImageOutput = [AVCaptureStillImageOutput new];
        [stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(void *)[AVCaptureStillImageIsCapturingStillImageContext UTF8String]];
        if ( [session canAddOutput:stillImageOutput] )
            [session addOutput:stillImageOutput];
        
        // Make a video data output
        videoDataOutput = [AVCaptureVideoDataOutput new];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [videoDataOutput setVideoSettings:rgbOutputSettings];
        [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
        
        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        
        if ( [session canAddOutput:videoDataOutput] )
            [session addOutput:videoDataOutput];
        [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
        
        effectiveScale = 1.0;
        previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        CALayer *rootLayer = [_previewView layer];
        //[rootLayer setMasksToBounds:YES];
        [previewLayer setFrame:_previewView.bounds];
        [previewLayer setNeedsDisplayOnBoundsChange:YES];
        [rootLayer addSublayer:previewLayer];
        [session startRunning];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
        [self teardownAVCapture];
    }
}

// clean up capture setup
- (void)teardownAVCapture
{
    [stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
    [previewLayer removeFromSuperlayer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        beginGestureScale = effectiveScale;
    }
    return YES;
}

// use front/back camera
- (IBAction)switchCameras:(id)sender
{
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera)
        desiredPosition = AVCaptureDevicePositionBack;
    else
        desiredPosition = AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [[previewLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
                [[previewLayer session] removeInput:oldInput];
            }
            [[previewLayer session] addInput:input];
            [[previewLayer session] commitConfiguration];
            break;
        }
    }
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
    
    AVCaptureVideoOrientation orientation = [self avOrientationForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [self reorientOutput:orientation];
}

// scale image depending on users pinch gesture
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:_previewView];
        CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
        if ( ! [previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        effectiveScale = beginGestureScale * recognizer.scale;
        if (effectiveScale < 1.0)
            effectiveScale = 1.0;
        CGFloat maxScaleAndCropFactor = [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        if (effectiveScale > maxScaleAndCropFactor)
            effectiveScale = maxScaleAndCropFactor;
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
        [CATransaction commit];
    }
}

// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)interfaceOrientation;
    return result;
}

// utility routine to display error aleart if takePicture fails
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (IBAction)takePicture:(id)sender {
    // Find out the current orientation and tell the still image output.
    AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:effectiveScale];
    
    [stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG
                                                                    forKey:AVVideoCodecKey]];
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                      if (error) {
                                                          [self displayErrorOnMainQueue:error withMessage:@"Take picture failed"];
                                                      }
                                                      else {
                                                          // trivial simple JPEG case
                                                          NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                          CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                                                                      imageDataSampleBuffer,
                                                                                                                      kCMAttachmentMode_ShouldPropagate);
                                                          ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                                                          [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge NSDictionary*)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
                                                              if (error) {
                                                                  [self displayErrorOnMainQueue:error withMessage:@"Save to camera roll failed"];
                                                              }
                                                          }];
                                                          
                                                          if (attachments)
                                                              CFRelease(attachments);
                                                      }
                                                  }];
}

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == [AVCaptureStillImageIsCapturingStillImageContext UTF8String] ) {
        BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            // do flash bulb like animation
            flashView = [[UIView alloc] initWithFrame:[_previewView frame]];
            [flashView setBackgroundColor:[UIColor whiteColor]];
            [flashView setAlpha:0.f];
            [[[self view] window] addSubview:flashView];
            
            [UIView animateWithDuration:.4f
                             animations:^{
                                 [flashView setAlpha:1.f];
                             }
             ];
        }
        else {
            [UIView animateWithDuration:.4f
                             animations:^{
                                 [flashView setAlpha:0.f];
                             }
                             completion:^(BOOL finished){
                                 [flashView removeFromSuperview];
                                 flashView = nil;
                             }
             ];
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //NSLog(@"Got frame!");
    // need to get an Image out of this data
    //downscale it and pass it to the renderer
    AVCaptureVideoDataOutput *output = videoDataOutput;
    NSDictionary* outputSettings = [output videoSettings];
    
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    unsigned char *baseAddress = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    [EAGLContext setCurrentContext: _glkView.context];
    
    Image scaledImage = Image::scaledFromSource(baseAddress, width, height, 4, bytesPerRow);
    renderer->loadTexture(scaledImage);
    
    if (UIInterfaceOrientationIsPortrait((UIInterfaceOrientation)[self avOrientationForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]]))
    {
        imageSize = CGSizeMake(height, width);
    }
    else
    {
        imageSize = CGSizeMake(width, height);
    }

    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [_glkView setNeedsDisplay];
    });
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [EAGLContext setCurrentContext: _glkView.context];
    
    if (shouldPixelize)
    {
        const CGSize viewSize = CGSizeMake(rect.size.width * [[UIScreen mainScreen] scale], rect.size.height * [[UIScreen mainScreen] scale]);
        
        CGSize viewportSize = imageSize;
        if (imageSize.width > viewSize.width)
        {
            viewportSize.width = viewSize.width;
            viewportSize.height = (viewSize.width / imageSize.width) * imageSize.height;
        }
        else if (imageSize.height > viewSize.height)
        {
            viewportSize.width = (viewSize.height / imageSize.height) * imageSize.width;
            viewportSize.height = viewSize.height;
        }
        
        glViewport((viewSize.width - viewportSize.width) / 2, (viewSize.height - viewportSize.height) / 2, viewportSize.width, viewportSize.height);
        renderer->render();
    }
    else
    {
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
}

@end
