//
//  Color.hpp
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-06-05.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#ifndef Color_hpp
#define Color_hpp

#include <stdio.h>
#include <cmath>

struct Color
{
    Color (unsigned char *values)
    {
        red = values[0];
        green = values[1];
        blue = values[2];
    }
    
    Color (int red, int green, int blue)
    : red(red), green(green), blue(blue)
    {
    }
    
    Color ()
    {
        red = 0;
        blue = 0;
        green = 0;
    }
    
    long red;
    long green;
    long blue;
    
    static Color average(Color a, Color b, Color c, Color d)
    {
        Color result;
        result.red = sqrt((a.red * a.red + b.red * b.red + c.red * c.red + d.red * d.red) / 4.0);
        result.green = sqrt((a.green * a.green + b.green * b.green + c.green * c.green + d.green * d.green) / 4.0);
        result.blue = sqrt((a.blue * a.blue + b.blue * b.blue + c.blue * c.blue + d.blue * d.blue) / 4.0);
        
        return result;
    }
};

#endif /* Color_hpp */
