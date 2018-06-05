//
//  PixelPointRenderer.h
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>

#include <vector>

class PixelPointRenderer
{
public:
    PixelPointRenderer();
    ~PixelPointRenderer();
    
    void render();
    void loadTexture(unsigned char *texture, int width, int height);
    
    static std::vector<GLfloat> vertices;
    static std::vector<GLuint> elements;
};
