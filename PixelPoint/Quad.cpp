//
//  Quad.cpp
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-06-05.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#include "Quad.h"

Quad::Quad (float topLeft[2], float bottomRight[2], Color color)
: topLeft{topLeft[0], topLeft[1]},
bottomRight{bottomRight[0], bottomRight[1]},
color(color)
{
    
}

bool Quad::isPointInQuad(const Quad &quad, float point[2])
{
    return false;
}

std::vector<Quad> Quad::quads;

