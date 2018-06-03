//
//  PixelPointRenderer.h
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PixelPointRenderer : NSObject

- (instancetype) init;
- (void) render;
- (void) loadTexture:(unsigned char *)texture withWidth:(int)width andHeight:(int)height;
- (void) dealloc;

@end
