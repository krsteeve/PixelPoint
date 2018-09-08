//
//  Quad.cpp
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-06-05.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#include "Quad.h"

#include "PixelPointRenderer.h"

Quad::Quad(float topLeft[2], float bottomRight[2], Color color)
: vertexOffset(PixelPointRenderer::vertices.size()),
elementOffset(PixelPointRenderer::elements.size())
{
    const float red = color.red / 255.0f;
    const float green = color.green / 255.0f;
    const float blue = color.blue / 255.0f;
    
    std::vector<GLfloat> *vertices = &PixelPointRenderer::vertices;
    
    vertices->insert(vertices->end(), {topLeft[0], topLeft[1], red, green, blue});
    vertices->insert(vertices->end(), {bottomRight[0], topLeft[1], red, green, blue});
    vertices->insert(vertices->end(), {bottomRight[0], bottomRight[1], red, green, blue});
    vertices->insert(vertices->end(), {topLeft[0], bottomRight[1], red, green, blue});
    
    std::vector<GLuint> *elements = &PixelPointRenderer::elements;
    const unsigned firstVertex = (unsigned)vertexOffset / 5;
    elements->insert(elements->end(), {firstVertex, firstVertex + 1, firstVertex + 2, firstVertex + 2, firstVertex + 3, firstVertex});

}

Quad::~Quad()
{
    //so far we are never deleting quads, worry about this later...
}

bool Quad::isPointInQuad(const Quad &quad, float point[2])
{
    std::vector<GLfloat> *vertices = &PixelPointRenderer::vertices;
    
    const float left = vertices->at(quad.vertexOffset);
    const float top = vertices->at(quad.vertexOffset + 1);
    const float right = vertices->at(quad.vertexOffset + 5);
    const float bottom = vertices->at(quad.vertexOffset + 11);
    
    
    
    return left <= point[0] && right >= point[0] && bottom <= point[1] && top >= point[1];
}

void Quad::setColorToBlack()
{
    std::vector<GLfloat> *vertices = &PixelPointRenderer::vertices;
    vertices->at(vertexOffset + 2) = 0.0f;
    vertices->at(vertexOffset + 3) = 0.0f;
    vertices->at(vertexOffset + 4) = 0.0f;
    
    vertices->at(vertexOffset + 7) = 0.0f;
    vertices->at(vertexOffset + 8) = 0.0f;
    vertices->at(vertexOffset + 9) = 0.0f;
    
    vertices->at(vertexOffset + 12) = 0.0f;
    vertices->at(vertexOffset + 13) = 0.0f;
    vertices->at(vertexOffset + 14) = 0.0f;
    
    vertices->at(vertexOffset + 17) = 0.0f;
    vertices->at(vertexOffset + 18) = 0.0f;
    vertices->at(vertexOffset + 19) = 0.0f;
    
    GLenum error = glGetError();
    printf("error %i", error);
    
    glBindBuffer(GL_ARRAY_BUFFER, 1);
    //glBufferData(GL_ARRAY_BUFFER, vertices->size() * sizeof(GLfloat), vertices->data(), GL_DYNAMIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, vertexOffset * sizeof(GLfloat), 20 * sizeof(GLfloat), &PixelPointRenderer::vertices[vertexOffset]);
    
    error = glGetError();
    printf("error %i", error);
}

void Quad::clear()
{
    quads.clear();
    PixelPointRenderer::elements.clear();
    PixelPointRenderer::vertices.clear();
}

std::vector<Quad> Quad::quads;

