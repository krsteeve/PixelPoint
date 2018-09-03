//
//  PixelPointRenderer.h
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#include "Image.h"

#if IOS
#include <OpenGLES/ES3/gl.h>
#else
#import <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>
#endif

#include <vector>

class PixelPointRenderer
{
public:
    PixelPointRenderer();
    ~PixelPointRenderer();
    
    void render();
    void loadTexture(const Image &image);
    
    static std::vector<GLfloat> vertices;
    static std::vector<GLuint> elements;
};
