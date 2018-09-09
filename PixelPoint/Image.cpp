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
static const int TARGET_SMALL_DIMENSION = 22;
static const int TARGET_LARGE_DIMENSION = 28;

#if !defined(IOS)
Image Image::loadImage(const char *filePath)
{
    int imageWidth = 0, imageHeight = 0, resultChannels = 0;
    unsigned char* image = SOIL_load_image(filePath, &imageWidth, &imageHeight, &resultChannels, SOIL_LOAD_RGB);
    
    return Image(std::unique_ptr<unsigned char, decltype(&std::free)>(image, &std::free), imageWidth, imageHeight, CHANNELS);
}
#endif

Image Image::scaledFromSource(const Image &original)
{
    size_t imageWidth = original.width;
    size_t imageHeight = original.height;
    unsigned char *image = original.data.get();
    
    return scaledFromSource(image, imageWidth, imageHeight, CHANNELS, imageWidth * CHANNELS);
}

Image Image::scaledFromSourceHelper(unsigned char *image, size_t width, size_t height, int channels, int outChannels, size_t stride, bool scaleUp)
{
    // process the image
    size_t calculatedWidth = width, calculatedHeight = height;
    int numDivisions = 0;
    while (std::max(calculatedWidth, calculatedHeight) / 2 >= TARGET_LARGE_DIMENSION && std::min(calculatedWidth, calculatedHeight) / 2 >= TARGET_SMALL_DIMENSION)
    {
        calculatedWidth /= 2;
        calculatedHeight /= 2;
        numDivisions++;
    }
    
    const long sizeToAverage = 1 << numDivisions;
    const long resultSize = (long)calculatedWidth * (long)calculatedHeight * outChannels * (scaleUp ? sizeToAverage * sizeToAverage : 1);
    unsigned char *resultImage = (unsigned char *)malloc(resultSize * sizeof(unsigned char));
    const size_t resultWidth = calculatedWidth;
    const size_t resultHeight = calculatedHeight;
    
    for (int i = 0; i < resultWidth; i++)
    {
        for (int j = 0; j < resultHeight; j++)
        {
            // sum the squares of each component
            long long redSum = 0, greenSum = 0, blueSum = 0;
            for (long x = 0; x < sizeToAverage; x++)
            {
                for (long y = 0; y < sizeToAverage; y++)
                {
                    long innerPos = (j * sizeToAverage + y) * stride + ((i * sizeToAverage) + x) * channels;
                    redSum += image[innerPos] * image[innerPos];
                    greenSum += image[innerPos + 1] * image[innerPos + 1];
                    blueSum += image[innerPos + 2] * image[innerPos + 2];
                }
            }
            
            // take sqrt of averages
            int avgBase = sizeToAverage * sizeToAverage;
            Color average(sqrt(redSum / avgBase), sqrt(greenSum / avgBase), sqrt(blueSum / avgBase));
            
            if (scaleUp)
            {
                for (long x = 0; x < sizeToAverage; x++)
                {
                    for (long y = 0; y < sizeToAverage; y++)
                    {
                        long innerPos = (j * sizeToAverage + y) * (resultWidth * sizeToAverage * outChannels) + ((i * sizeToAverage) + x) * outChannels;
                        resultImage[innerPos] = average.red;
                        resultImage[innerPos + 1] = average.green;
                        resultImage[innerPos + 2] = average.blue;
                        
                        if (outChannels == 4)
                        {
                            resultImage[innerPos + 3] = 255; //full alpha
                        }
                    }
                }
            }
            else
            {
                long targetPosition = (j * resultWidth + i) * outChannels;
                
                resultImage[targetPosition] = average.red;
                resultImage[targetPosition + 1] = average.green;
                resultImage[targetPosition + 2] = average.blue;
                
                if (outChannels == 4)
                {
                    resultImage[targetPosition + 3] = 255; //full alpha
                }
            }
        }
    }
    
    return Image(std::unique_ptr<unsigned char, decltype(&std::free)>(resultImage, &std::free), (scaleUp ? resultWidth * sizeToAverage : resultWidth), (scaleUp ? resultHeight * sizeToAverage : resultHeight), outChannels);
}

Image Image::scaledFromSource(unsigned char *image, size_t width, size_t height, int channels, size_t stride)
{
    return scaledFromSourceHelper(image, width, height, channels, CHANNELS, stride, false);
}

Image Image::scaledFromSourceForSaving(unsigned char *image, size_t width, size_t height, int channels, int outChannels, size_t stride)
{
    return scaledFromSourceHelper(image, width, height, channels, outChannels, stride, true);
}
