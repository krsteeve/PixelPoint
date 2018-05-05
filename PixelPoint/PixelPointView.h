//
//  PixelPointView.h
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

@interface PixelPointView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
}

@end
