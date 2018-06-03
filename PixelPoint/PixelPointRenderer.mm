//
//  PixelPointRenderer.m
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "PixelPointRenderer.h"
#import <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>
#include <vector>

#include "SOIL.h"

@implementation PixelPointRenderer

// Shader sources
const GLchar* vertexSource = R"glsl(
#version 150 core
in vec2 position;
in vec3 color;
in vec2 texcoord;
out vec3 Color;
out vec2 Texcoord;
void main()
{
    Color = color;
    Texcoord = texcoord;
    gl_Position = vec4(position, 0.0, 1.0);
}
)glsl";

const GLchar* fragmentSource = R"glsl(
#version 150 core
in vec3 Color;
in vec2 Texcoord;
out vec4 outColor;
uniform sampler2D tex;
void main()
{
    outColor = vec4(Color, 1.0);
}
)glsl";

static const int COMPONENTS_PER_VERTEX = 7;

std::vector<GLfloat> tile (unsigned char *texture, int width, int height) {
    std::vector<GLfloat> vertices;
    vertices.reserve(width * height * COMPONENTS_PER_VERTEX * 4);
    
    float elementWidth = 2.0f / width;
    float elementHeight = 2.0f / height;
    
    for (int i = 0; i < width; i++)
    {
        for (int j = 0; j < height; j++)
        {
            const float left = (i * elementWidth) - 1;
            const float right = left + elementWidth;
            
            const float top = 1 - (j * elementHeight);
            const float bottom = top - elementHeight;
            
            float red = texture[(j * width + i) * 3] / 255.0f;
            float green = texture[(j * width + i) * 3 + 1] / 255.0f;
            float blue = texture[(j * width + i) * 3 + 2] / 255.0f;
            
            vertices.insert(vertices.end(), {
            // Position (2)    Color (3)   Texcoords (2)
            left,  top, red, green, blue, 0.0f, 0.0f, // Top-left
            right,  top, red, green, blue, 1.0f, 0.0f, // Top-right
            right, bottom, red, green, blue, 1.0f, 1.0f, // Bottom-right
            left, bottom, red, green, blue, 0.0f, 1.0f  // Bottom-left
            });
        }
    }
    
    return vertices;
}

std::vector<GLuint> elementsForTiling(int width, int height)
{
    std::vector<GLuint> elements;
    elements.reserve(width * height * 6);
    
    for (int i = 0; i < width; i++)
    {
        for (int j = 0; j < height; j++)
        {
            const unsigned firstVertex = (i * 4) + (j * width * 4);
            elements.insert(elements.end(), {
                firstVertex, firstVertex + 1, firstVertex + 2,
                firstVertex + 2, firstVertex + 3, firstVertex
            });
        }
    }
    
    return elements;
}

- (instancetype) init {
    
    if((self = [super init]))
    {
        
        
    }
    
    return self;
}

static int windowWidth = 0;
static int windowHeight = 0;

- (void) loadTexture:(unsigned char *)texture withWidth:(int)width andHeight:(int)height {
    // Create Vertex Array Object
    GLuint vao;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    
    // Create a Vertex Buffer Object and copy the vertex data to it
    GLuint vbo;
    glGenBuffers(1, &vbo);
    
    static std::vector<GLfloat> verticesVector = tile(texture, width, height);
    GLfloat *vertices = verticesVector.data();
    const size_t vertexCount = verticesVector.size();
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, vertexCount * sizeof(GLfloat), vertices, GL_STATIC_DRAW);
    
    // Create an element array
    GLuint ebo;
    glGenBuffers(1, &ebo);
    
    static std::vector<GLuint> elementsVector = elementsForTiling(width, height);
    GLuint *elements = elementsVector.data();
    const size_t elementCount = elementsVector.size();
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementCount * sizeof(GLuint), elements, GL_STATIC_DRAW);
    
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
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, COMPONENTS_PER_VERTEX * sizeof(GLfloat), 0);
    
    GLint colAttrib = glGetAttribLocation(shaderProgram, "color");
    glEnableVertexAttribArray(colAttrib);
    glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE, COMPONENTS_PER_VERTEX * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat)));
    
    GLint texAttrib = glGetAttribLocation(shaderProgram, "texcoord");
    glEnableVertexAttribArray(texAttrib);
    glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, COMPONENTS_PER_VERTEX * sizeof(GLfloat), (void*)(5 * sizeof(GLfloat)));
    
    // Load texture
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    windowWidth = width;
    windowHeight = height;
}

- (void) render {
    // Clear the screen to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Draw a rectangle from the 2 triangles using 6 indices
    glDrawElements(GL_TRIANGLES, windowWidth * windowHeight * 6, GL_UNSIGNED_INT, 0);
}

- (void) dealloc {
    
}

@end
