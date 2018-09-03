//
//  Image.hpp
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-09-03.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#ifndef Image_hpp
#define Image_hpp

#include <memory>

// images are all RGB
template <typename deleter>
struct GenericImage
{
    GenericImage(std::unique_ptr<unsigned char, deleter> data, int width, int height)
    : data(std::move(data)), width(width), height(height) {}
    
    std::unique_ptr<unsigned char, deleter> data;
    const int width;
    const int height;
};

struct Image : public GenericImage<decltype(&std::free)>
{
    Image(std::unique_ptr<unsigned char, decltype(&std::free)> data, int width, int height)
    : GenericImage(std::move(data), width, height)
    {
        
    }
    
    Image(Image &&other)
    : GenericImage(std::move(other.data), other.width, other.height)
    {
        
    }
    
#if !defined(IOS)
    static Image loadImage(const char *filePath);
#endif
    static Image scaledFromSource(const Image &original);
};

#endif /* Image_hpp */
