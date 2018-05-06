//
//  PixelPointRenderer.m
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import "PixelPointRenderer.h"
#import <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>

@implementation PixelPointRenderer

// Shader sources
const GLchar* vertexSource = R"glsl(
#version 150 core
in vec2 position;
void main()
{
    gl_Position = vec4(position, 0.0, 1.0);
}
)glsl";
const GLchar* fragmentSource = R"glsl(
#version 150 core
out vec4 outColor;
void main()
{
    outColor = vec4(1.0, 1.0, 1.0, 1.0);
}
)glsl";

- (instancetype) init {
    
    if((self = [super init]))
    {
        // Create Vertex Array Object
        GLuint vao;
        glGenVertexArrays(1, &vao);
        
        glBindVertexArray(vao);
        
        
        // Create a Vertex Buffer Object and copy the vertex data to it
        GLuint vbo;
        glGenBuffers(1, &vbo);
        
        GLfloat vertices[] = {
            0.0f,  0.5f,
            0.5f, -0.5f,
            -0.5f, -0.5f
        };
        
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        
        // Create and compile the vertex shader
        GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertexShader, 1, &vertexSource, NULL);
        glCompileShader(vertexShader);
        
        // Create and compile the fragment shader
        GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragmentShader, 1, &fragmentSource, NULL);
        glCompileShader(fragmentShader);
        
        // Link the vertex and fragment shader into a shader program
        GLuint shaderProgram = glCreateProgram();
        glAttachShader(shaderProgram, vertexShader);
        glAttachShader(shaderProgram, fragmentShader);
        glBindFragDataLocation(shaderProgram, 0, "outColor");
        glLinkProgram(shaderProgram);
        glUseProgram(shaderProgram);
        
        // Specify the layout of the vertex data
        GLint posAttrib = glGetAttribLocation(shaderProgram, "position");
        glEnableVertexAttribArray(posAttrib);
        glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0);
    }
    
    return self;
}

- (void) render {
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void) dealloc {
    
}

@end
