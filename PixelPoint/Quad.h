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
    Quad()
    {
        vertexOffset = -1;
        elementOffset = -1;
    }
    Quad (float topLeft[2], float bottomRight[2], Color);
    ~Quad();
    
    float topLeft() const;
    float bottomRight() const;
    
    Color color() const;
    
    static bool isPointInQuad(const Quad &quad, float point[2]);
    
    void setColorToBlack();
    
    static std::vector<Quad> quads;
    
    friend bool operator==(const Quad &lhs, const Quad &rhs)
    {
        return lhs.vertexOffset == rhs.vertexOffset;
    }
    
    static void clear();
    
private:
    size_t vertexOffset;
    size_t elementOffset;
};

#endif /* Quad_hpp */
