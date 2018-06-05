//
//  Quad.hpp
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-06-05.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#ifndef Quad_hpp
#define Quad_hpp

#include "Color.h"

#include <stdio.h>
#include <vector>

struct Quad
{
    Quad (float topLeft[2], float bottomRight[2], Color);
    
    float topLeft[2];
    float bottomRight[2];
    
    Color color;
    
    static bool isPointInQuad(const Quad &quad, float point[2]);
    
    static std::vector<Quad> quads;
};

#endif /* Quad_hpp */
