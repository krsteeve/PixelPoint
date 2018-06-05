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

// Shader sources
const GLchar* vertexSource = R"glsl(
#version 150 core
in vec2 position;
in vec3 color;
out vec3 Color;
void main()
{
    Color = color;
    gl_Position = vec4(position, 0.0, 1.0);
}
)glsl";

const GLchar* fragmentSource = R"glsl(
#version 150 core
in vec3 Color;
out vec4 outColor;
void main()
{
    outColor = vec4(Color, 1.0);
}
)glsl";

static const int COMPONENTS_PER_VERTEX = 5;

#include "Quad.h"

void tile (unsigned char *texture, int width, int height) {
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
            
            float topLeft[] = {left, top};
            float bottomRight[] = {right, bottom};
            
            int red = texture[(j * width + i) * 3];
            int green = texture[(j * width + i) * 3 + 1];
            int blue = texture[(j * width + i) * 3 + 2];
            
            Quad quad(topLeft, bottomRight, Color(red, green, blue));
            Quad::quads.push_back(quad);
        }
    }
}

std::vector<GLfloat> PixelPointRenderer::vertices;
std::vector<GLuint> PixelPointRenderer::elements;

PixelPointRenderer::PixelPointRenderer()
{
    
}

PixelPointRenderer::~PixelPointRenderer()
{
    
}

void PixelPointRenderer::loadTexture(unsigned char *texture, int width, int height)
{
    // Create Vertex Array Object
    GLuint vao;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    
    // Create a Vertex Buffer Object and copy the vertex data to it
    GLuint vbo;
    glGenBuffers(1, &vbo);
    
    tile(texture, width, height);
    
    GLfloat *vertexData = vertices.data();
    const size_t vertexCount = vertices.size();
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, vertexCount * sizeof(GLfloat), vertexData, GL_DYNAMIC_DRAW);
    
    // Create an element array
    GLuint ebo;
    glGenBuffers(1, &ebo);
    
    //elements = elementsForTiling(width, height);
    GLuint *elementData = elements.data();
    const size_t elementCount = elements.size();
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementCount * sizeof(GLuint), elementData, GL_STATIC_DRAW);
    
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
    
    //GLint texAttrib = glGetAttribLocation(shaderProgram, "texcoord");
    //glEnableVertexAttribArray(texAttrib);
    //glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, COMPONENTS_PER_VERTEX * sizeof(GLfloat), (void*)(5 * sizeof(GLfloat)));
    
    // Load texture
    //GLuint tex;
    //glGenTextures(1, &tex);
    //glBindTexture(GL_TEXTURE_2D, tex);
    
    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, texture);
    
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

void PixelPointRenderer::render()
{
    // Clear the screen to white
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Draw a rectangle from the 2 triangles using 6 indices
    glDrawElements(GL_TRIANGLES, (int)vertices.size(), GL_UNSIGNED_INT, 0);
}
