//
//  PixelPointView.m
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import "PixelPointView.h"
#import "PixelPointRenderer.h"
#import <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>
#include "SOIL.h"

#define SUPPORT_RETINA_RESOLUTION 1

@interface PixelPointView ()
{
    PixelPointRenderer* _renderer;
}
@end

@implementation PixelPointView

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
    // There is no autorelease pool when this method is called
    // because it will be called from a background thread.
    // It's important to create one or app can leak objects.
    @autoreleasepool {
        [self drawView];
    }
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext)
{
    CVReturn result = [(__bridge PixelPointView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

struct Color
{
    Color (unsigned char *values)
    {
        red = values[0];
        green = values[1];
        blue = values[2];
    }
    
    Color ()
    {
        red = 0;
        blue = 0;
        green = 0;
    }
    
    long red;
    long green;
    long blue;
    
    static Color average(Color a, Color b, Color c, Color d)
    {
        Color result;
        result.red = sqrt((a.red * a.red + b.red * b.red + c.red * c.red + d.red * d.red) / 4.0);
        result.green = sqrt((a.green * a.green + b.green * b.green + c.green * c.green + d.green * d.green) / 4.0);
        result.blue = sqrt((a.blue * a.blue + b.blue * b.blue + c.blue * c.blue + d.blue * d.blue) / 4.0);
        
        return result;
    }
};

- (void) awakeFromNib
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        // Must specify the 3.2 Core Profile to use OpenGL 3.2
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    
    if (!pf)
    {
        NSLog(@"No OpenGL pixel format");
    }
    
    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    
#if defined(DEBUG)
    // When we're using a CoreProfile context, crash if we call a legacy OpenGL function
    // This will make it much more obvious where and when such a function call is made so
    // that we can remove such calls.
    // Without this we'd simply get GL_INVALID_OPERATION error for calling legacy functions
    // but it would be more difficult to see where that function was called.
    CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
#endif
    
    [self setPixelFormat:pf];
    
    [self setOpenGLContext:context];
    
#if SUPPORT_RETINA_RESOLUTION
    // Opt-In to Retina resolution
    [self setWantsBestResolutionOpenGLSurface:YES];
#endif // SUPPORT_RETINA_RESOLUTION
    
    unsigned char *resultImage = 0;
    int resultWidth = 0;
    int resultHeight = 0;
    int resultChannels = 0;
    
    NSArray *fileTypes = [NSImage imageTypes];
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setFloatingPanel:YES];
    [panel setAllowedFileTypes:fileTypes];
    NSInteger result = [panel runModal];
    if(result == NSModalResponseOK)
    {
        NSURL *imageUrl = [[panel URLs] objectAtIndex:0];
        
        int imageWidth = 0, imageHeight = 0;
        NSString *filePath = [imageUrl relativePath];
        unsigned char* image = SOIL_load_image([filePath UTF8String], &imageWidth, &imageHeight, &resultChannels, SOIL_LOAD_RGB);
        
        // process the image
        
        // down to 28x22 or 22x28
        // half the image combining each 4 pixels into one
        // do this once for now
        while (imageWidth / 2 >=28 && imageHeight / 2 >= 22)
        
        {
            long resultSize = ((long)(imageWidth / 2) * (long)(imageHeight / 2)) * resultChannels;
            resultImage = (unsigned char *)malloc(resultSize * sizeof(unsigned char));
            resultWidth = imageWidth / 2;
            resultHeight = imageHeight / 2;
            for (int i = 0; i < resultWidth; i++)
            {
                for (int j = 0; j < resultHeight; j++)
                {
                    long position = (j * 2 * imageWidth + i * 2) * resultChannels;
                    long nextRowPosition = ((j * 2 + 1) * imageWidth + i * 2) * resultChannels;
                    long targetPosition = (j * resultWidth + i) * resultChannels;
                    
                    Color color1(&image[position]);
                    Color color2(&image[position + resultChannels]);
                    Color color3(&image[nextRowPosition]);
                    Color color4(&image[nextRowPosition + resultChannels]);
                    
                    Color average = Color::average(color1, color2, color3, color4);
                    
                    resultImage[targetPosition] = average.red;
                    resultImage[targetPosition + 1] = average.green;
                    resultImage[targetPosition + 2] = average.blue;
                }
            }
            
            // just free - can do it on our own malloc
            SOIL_free_image_data(image);
            
            image = resultImage;
            imageWidth = resultWidth;
            imageHeight = resultHeight;
        }
        
        [_renderer loadTexture:image withWidth:imageWidth andHeight:imageHeight];
        
        NSRect viewFrame = self.frame;
        viewFrame.size.width = imageWidth * 16;
        viewFrame.size.height = imageHeight * 16;
        
        [self setFrame:viewFrame];
        [_window setFrame:viewFrame display:YES];
        
    }
    
    /*NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:@"Chiko-2.tga"];
    long saveResult = [savePanel runModal];
    if (saveResult == NSModalResponseOK)
    {
        NSURL *savePath = [savePanel URL];
        SOIL_save_image([[savePath relativePath] UTF8String], SOIL_SAVE_TYPE_TGA, resultWidth, resultHeight, resultChannels, resultImage);
    }*/
    
    free(resultImage);
}

- (void) prepareOpenGL
{
    [super prepareOpenGL];
    
    // Make all the OpenGL calls to setup rendering
    //  and build the necessary rendering objects
    [self initGL];
    
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
    
    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    
    // Activate the display link
    CVDisplayLinkStart(displayLink);
    
    // Register to be notified when the window closes so we can stop the displaylink
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];
}

- (void) windowWillClose:(NSNotification*)notification
{
    // Stop the display link when the window is closing because default
    // OpenGL render buffers will be destroyed.  If display link continues to
    // fire without renderbuffers, OpenGL draw calls will set errors.
    
    CVDisplayLinkStop(displayLink);
}

- (void)reshape
{
    [super reshape];
    
    // We draw on a secondary thread through the display link. However, when
    // resizing the view, -drawRect is called on the main thread.
    // Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing.
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    // Get the view size in Points
    NSRect viewRectPoints = [self bounds];
    
#if SUPPORT_RETINA_RESOLUTION
    
    // Rendering at retina resolutions will reduce aliasing, but at the potential
    // cost of framerate and battery life due to the GPU needing to render more
    // pixels.
    
    // Any calculations the renderer does which use pixel dimentions, must be
    // in "retina" space.  [NSView convertRectToBacking] converts point sizes
    // to pixel sizes.  Thus the renderer gets the size in pixels, not points,
    // so that it can set it's viewport and perform and other pixel based
    // calculations appropriately.
    // viewRectPixels will be larger than viewRectPoints for retina displays.
    // viewRectPixels will be the same as viewRectPoints for non-retina displays
    NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
    
#else //if !SUPPORT_RETINA_RESOLUTION
    
    // App will typically render faster and use less power rendering at
    // non-retina resolutions since the GPU needs to render less pixels.
    // There is the cost of more aliasing, but it will be no-worse than
    // on a Mac without a retina display.
    
    // Points:Pixels is always 1:1 when not supporting retina resolutions
    NSRect viewRectPixels = viewRectPoints;
    
#endif // !SUPPORT_RETINA_RESOLUTION
    
    // Set the new dimensions in our renderer
   // [_renderer resizeWithWidth:viewRectPixels.size.width
      //               AndHeight:viewRectPixels.size.height];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


- (void)renewGState
{
    // Called whenever graphics state updated (such as window resize)
    
    // OpenGL rendering is not synchronous with other rendering on the OSX.
    // Therefore, call disableScreenUpdatesUntilFlush so the window server
    // doesn't render non-OpenGL content in the window asynchronously from
    // OpenGL content, which could cause flickering.  (non-OpenGL content
    // includes the title bar and drawing done by the app with other APIs)
    [[self window] disableScreenUpdatesUntilFlush];
    
    [super renewGState];
}

- (void) drawRect: (NSRect) theRect
{
    // Called during resize operations
    
    // Avoid flickering during resize by drawiing
    [self drawView];
}

- (void) drawView
{
    [[self openGLContext] makeCurrentContext];
    
    // We draw on a secondary thread through the display link
    // When resizing the view, -reshape is called automatically on the main
    // thread. Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    [_renderer render];
    
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) dealloc
{
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been release
    CVDisplayLinkStop(displayLink);
    
    CVDisplayLinkRelease(displayLink);
}



- (void) initGL
{
    // The reshape function may have changed the thread to which our OpenGL
    // context is attached before prepareOpenGL and initGL are called.  So call
    // makeCurrentContext to ensure that our OpenGL context current to this
    // thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
    // to [self openGLContext])
    [[self openGLContext] makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
    
    _renderer = [[PixelPointRenderer alloc] init];
}

@end
