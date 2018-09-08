//
//  PixelPointRenderer.m
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-05-04.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#import "PixelPointRenderer.h"

#include <vector>

// Shader sources
#if IOS
const GLchar* vertexSource = R"glsl(
#version 300 es
in vec2 position;
in vec3 color;
uniform mat2 transformation;
out vec3 Color;
void main()
{
    Color = color.bgr;
    gl_Position = vec4(transformation * position, 0.0, 1.0);
}
)glsl";

const GLchar* fragmentSource = R"glsl(
#version 300 es
precision highp float;
in vec3 Color;
out vec4 outColor;
void main()
{
    outColor = vec4(Color, 1.0);
}
)glsl";

#else

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
#endif

static const int COMPONENTS_PER_VERTEX = 5;

#include "Quad.h"

void tile (unsigned char *texture, int width, int height) {
    std::vector<GLfloat> vertices;
    vertices.reserve(width * height * COMPONENTS_PER_VERTEX * 4);
    
    float elementWidth = 2.0f / width;
    float elementHeight = 2.0f / height;
    
    Quad::clear();
    
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
:   viewport{0.0f, 0.0f, 0.0f, 0.0f},
    rotation(0.0f),
    flip{false, false},
    scale {1.0f, 1.0f}
{
    // Create Vertex Array Object
    glGenVertexArrays(1, &vao);
    
    // Create a Vertex Buffer Object and copy the vertex data to it
    glGenBuffers(1, &vbo);
    
    // Create an element array
    glGenBuffers(1, &ebo);
    
    // Create and compile the vertex shader
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexSource, NULL);
    glCompileShader(vertexShader);
    
    // Create and compile the fragment shader
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentSource, NULL);
    glCompileShader(fragmentShader);
    
    // Link the vertex and fragment shader into a shader program
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    
    posAttrib = glGetAttribLocation(shaderProgram, "position");
    colAttrib = glGetAttribLocation(shaderProgram, "color");
}

PixelPointRenderer::~PixelPointRenderer()
{
    
}

void PixelPointRenderer::loadTexture(const Image &image)
{
    unsigned char *texture = image.data.get();
    int width = image.width;
    int height = image.height;
    
    glBindVertexArray(vao);
    
    tile(texture, width, height);
    
    GLfloat *vertexData = vertices.data();
    const size_t vertexCount = vertices.size();
    
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, vertexCount * sizeof(GLfloat), vertexData, GL_DYNAMIC_DRAW);
    
    //elements = elementsForTiling(width, height);
    GLuint *elementData = elements.data();
    const size_t elementCount = elements.size();
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementCount * sizeof(GLuint), elementData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(posAttrib);
    glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, COMPONENTS_PER_VERTEX * sizeof(GLfloat), 0);
    
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

void PixelPointRenderer::clear()
{
    Quad::clear();
}

void PixelPointRenderer::render()
{
    glUseProgram(shaderProgram);
    glBindVertexArray(vao);
    
    float xScale = flip[0] ? -1.0f : 1.0f;
    float yScale = flip[1] ? -1.0f : 1.0f;
    float flip [] = { xScale, 0, 0, yScale };
    float rotate [] = { std::cos(rotation), -std::sin(rotation), sin(rotation), std::cos(rotation)};
    float transform[] = {flip[0]*rotate[0] + flip[1]*rotate[2], flip[0]*rotate[1] + flip[1]*rotate[3], flip[2]*rotate[0] + flip[3]*rotate[2], flip[2]*rotate[1] + flip[3]*rotate[3]};
    
    GLuint transformID = glGetUniformLocation(shaderProgram, "transformation");
    glUniformMatrix2fv(transformID, 1, GL_FALSE, &transform[0]);
    
    // Clear the screen to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Draw a rectangle from the 2 triangles using 6 indices
    glDrawElements(GL_TRIANGLES, (int)elements.size(), GL_UNSIGNED_INT, 0);
}
