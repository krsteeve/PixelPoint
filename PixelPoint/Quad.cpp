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
    return false;
}

std::vector<Quad> Quad::quads;

