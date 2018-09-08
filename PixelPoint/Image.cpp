//
//  Image.cpp
//  PixelPoint
//
//  Created by Kelsey Steeves on 2018-09-03.
//  Copyright © 2018 Kelsey Steeves. All rights reserved.
//

#include "Image.h"

#include "Color.h"

#if !defined (IOS)
#include "SOIL.h"
#endif

#include <algorithm>

// we always use RGB
static const int CHANNELS = 3;

#if !defined(IOS)
Image Image::loadImage(const char *filePath)
{
    int imageWidth = 0, imageHeight = 0, resultChannels = 0;
    unsigned char* image = SOIL_load_image(filePath, &imageWidth, &imageHeight, &resultChannels, SOIL_LOAD_RGB);
    
    return Image(std::unique_ptr<unsigned char, decltype(&std::free)>(image, &std::free), imageWidth, imageHeight);
}
#endif

Image Image::scaledFromSource(const Image &original)
{
    int imageWidth = original.width;
    int imageHeight = original.height;
    unsigned char *image = original.data.get();
    
    return scaledFromSource(image, imageWidth, imageHeight, CHANNELS, imageWidth * CHANNELS);
}


Image Image::scaledFromSource(unsigned char *image, int imageWidth, int imageHeight, int channels, int stride)
{
    // process the image
    int calculatedWidth = imageWidth, calculatedHeight = imageHeight;
    int numDivisions = 0;
    while (std::max(calculatedWidth, calculatedHeight) / 2 >=28 && std::min(calculatedWidth, calculatedHeight) / 2 >= 22)
    {
        calculatedWidth /= 2;
        calculatedHeight /= 2;
        numDivisions++;
    }
    
    long resultSize = (long)calculatedWidth * (long)calculatedHeight * channels;
    unsigned char *resultImage = (unsigned char *)malloc(resultSize * sizeof(unsigned char));
    int resultWidth = calculatedWidth;
    int resultHeight = calculatedHeight;
    long resultPixelSize = 1 << numDivisions;
    
    for (int i = 0; i < resultWidth; i++)
    {
        for (int j = 0; j < resultHeight; j++)
        {
            
            long targetPosition = (j * resultWidth + i) * CHANNELS;
            
            // sum the squares of each component
            long long redSum = 0, greenSum = 0, blueSum = 0;
            for (long x = 0; x < resultPixelSize; x++)
            {
                for (long y = 0; y < resultPixelSize; y++)
                {
                    long innerPos = (j * resultPixelSize + y) * stride + ((i * resultPixelSize) + x) * channels;
                    redSum += image[innerPos] * image[innerPos];
                    greenSum += image[innerPos + 1] * image[innerPos + 1];
                    blueSum += image[innerPos + 2] * image[innerPos + 2];
                }
            }
            
            // take sqrt of averages
            int avgBase = resultPixelSize * resultPixelSize;
            Color average(sqrt(redSum / avgBase), sqrt(greenSum / avgBase), sqrt(blueSum / avgBase));
            resultImage[targetPosition] = average.red;
            resultImage[targetPosition + 1] = average.green;
            resultImage[targetPosition + 2] = average.blue;
        }
    }
    
    return Image(std::unique_ptr<unsigned char, decltype(&std::free)>(resultImage, &std::free), resultWidth, resultHeight);
}
