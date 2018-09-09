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
    GenericImage(std::unique_ptr<unsigned char, deleter> data, size_t width, size_t height, int channels)
    : data(std::move(data)), width(width), height(height), channels(channels) {}
    
    std::unique_ptr<unsigned char, deleter> data;
    const size_t width;
    const size_t height;
    const int channels;
};

struct Image : public GenericImage<decltype(&std::free)>
{
    Image(std::unique_ptr<unsigned char, decltype(&std::free)> data, size_t width, size_t height, int channels)
    : GenericImage(std::move(data), width, height, channels)
    {
        
    }
    
    Image(Image &&other)
    : GenericImage(std::move(other.data), other.width, other.height, other.channels)
    {
        
    }
    
#if !defined(IOS)
    static Image loadImage(const char *filePath);
#endif
    static Image scaledFromSource(const Image &original);
    static Image scaledFromSource(unsigned char *image, size_t width, size_t height, int channels, size_t stride);
    
    // scales the image down and back up for saving to disk. out channels can be used to pad RGB to RGBA but the A isn't written to
    static Image scaledFromSourceForSaving(unsigned char *image, size_t width, size_t height, int channels, int outChannels, size_t stride);
    
private:
    static Image scaledFromSourceHelper(unsigned char *image, size_t width, size_t height, int channels, int outChannels, size_t stride, bool scaleUp);
};

#endif /* Image_hpp */
