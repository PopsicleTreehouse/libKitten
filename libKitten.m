#import "public/libKitten.h"

@interface libKitten (private)
+ (UIColor *)getColors:(UIImage *)arg1 dimension:(float)arg2 flexibility:(float)arg3 range:(float)arg4;
@end

@implementation libKitten
// https://stackoverflow.com/a/13695592
+ (UIColor *)backgroundColor:(UIImage *)image {

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char rgba[4];
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), [image CGImage]);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    if (rgba[3] > 0) {
        CGFloat alpha = ((CGFloat)rgba[3])/255.0;
        CGFloat multiplier = alpha/255.0;
        return [UIColor colorWithRed:((CGFloat)rgba[0])*multiplier green:((CGFloat)rgba[1])*multiplier blue:((CGFloat)rgba[2])*multiplier alpha:alpha];
    } else {
        return [UIColor colorWithRed:((CGFloat)rgba[0])/255.0 green:((CGFloat)rgba[1])/255.0 blue:((CGFloat)rgba[2])/255.0 alpha:((CGFloat)rgba[3])/255.0];
    }

}

// https://stackoverflow.com/a/29266983
+ (UIColor *)getColors:(UIImage *)arg1 dimension:(float)arg2 flexibility:(float)arg3 range:(float)arg4 {
    NSMutableArray* colors = [NSMutableArray new];
    CGImageRef imageRef = [arg1 CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char* rawData = (unsigned char *) calloc(arg2 * arg2 * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * arg2;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, arg2, arg2, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, arg2, arg2), imageRef);
    CGContextRelease(context);

    float x = 0;
    float y = 0;

    for (int n = 0; n < (arg2 * arg2); n++) {
        int index = (bytesPerRow * y) + x * bytesPerPixel;
        int red   = rawData[index];
        int green = rawData[index + 1];
        int blue  = rawData[index + 2];
        int alpha = rawData[index + 3];
        NSArray* a = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%i", red], [NSString stringWithFormat:@"%i", green], [NSString stringWithFormat:@"%i", blue], [NSString stringWithFormat:@"%i", alpha], nil];
        [colors addObject:a];
        y++;
        if (y == arg2){
            y = 0;
            x++;
        }
    }
    free(rawData);

    NSArray* copycolors = [NSArray arrayWithArray:colors];
    NSMutableArray* flexiblecolors = [NSMutableArray new];

    float flexFactor = arg3 * 2 + 1;
    float factor = flexFactor * flexFactor * 3;

    for (int n = 0; n < (arg2 * arg2); n++){
        NSArray* pixelcolors = copycolors[n];
        NSMutableArray* reds = [NSMutableArray new];
        NSMutableArray* greens = [NSMutableArray new];
        NSMutableArray* blues = [NSMutableArray new];

        for (int p = 0; p < 3; p++){
            NSString* rgbStr = pixelcolors[p];
            int rgb = [rgbStr intValue];
            for (int f = - arg3; f < arg3 + 1; f++){
                int newRGB = rgb + f;
                if (newRGB < 0)
                    newRGB = 0;
                if (p == 0)
                    [reds addObject:[NSString stringWithFormat:@"%i", newRGB]];
                else if (p == 1)
                    [greens addObject:[NSString stringWithFormat:@"%i", newRGB]];
                else if (p == 2)
                    [blues addObject:[NSString stringWithFormat:@"%i", newRGB]];
            }
        }

        int r = 0;
        int g = 0;
        int b = 0;

        for (int k = 0; k < factor; k++) {
            int red = [reds[r] intValue];
            int green = [greens[g] intValue];
            int blue = [blues[b] intValue];

            NSString* rgbString = [NSString stringWithFormat:@"%i, %i, %i", red, green, blue];
            [flexiblecolors addObject:rgbString];

            b++;
            if (b == flexFactor) {
                b = 0;
                g++;
            }
            if (g == flexFactor) {
                g = 0;
                r++;
            }
        }
    }

    NSMutableDictionary* colorCounter = [NSMutableDictionary new];

    NSCountedSet* countedSet = [[NSCountedSet alloc] initWithArray:flexiblecolors];
    for (NSString* item in countedSet) {
        NSUInteger count = [countedSet countForObject:item];
        [colorCounter setValue:[NSNumber numberWithInteger:count] forKey:item];
    }

    NSArray* orderedKeys = [colorCounter keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2){
        return [obj2 compare:obj1];
    }];

    NSMutableArray* ranges = [NSMutableArray new];
    for (NSString* key in orderedKeys){
        NSArray* rgb = [key componentsSeparatedByString:@","];
        int r = [rgb[0] intValue];
        int g = [rgb[1] intValue];
        int b = [rgb[2] intValue];
        bool exclude = false;
        for (NSString* ranged_key in ranges){
            NSArray* ranged_rgb = [ranged_key componentsSeparatedByString:@","];

            int ranged_r = [ranged_rgb[0] intValue];
            int ranged_g = [ranged_rgb[1] intValue];
            int ranged_b = [ranged_rgb[2] intValue];

            if (r >= ranged_r - arg4 && r <= ranged_r + arg4)
                if (g >= ranged_g - arg4 && g <= ranged_g + arg4)
                    if (b >= ranged_b - arg4 && b <= ranged_b + arg4)
                        exclude = true;
        }
        if (!exclude) [ranges addObject:key];
    }

    NSMutableArray* colorArray = [NSMutableArray new];
    UIColor* color;
    for (NSString* key in ranges){
        NSArray* rgb = [key componentsSeparatedByString:@","];
        float r = [rgb[0] floatValue];
        float g = [rgb[1] floatValue];
        float b = [rgb[2] floatValue];
        color = [UIColor colorWithRed:(r/255.0f) green:(g/255.0f) blue:(b/255.0f) alpha:1.0f];
        [colorArray addObject:color];
    }

    return color;
}

+ (UIColor *)primaryColor:(UIImage *)image {
    return [self getColors:image dimension:4.0f flexibility:1.0f range:100.0f];
}
+ (UIColor *)secondaryColor:(UIImage *)image {
    return [self getColors:image dimension:9.0f flexibility:3.0f range:90.0f];
}

// https://gist.github.com/justinHowlett/4611988
+ (BOOL)isDarkImage:(UIImage *)image {

    BOOL isDark = FALSE;

    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider([image CGImage]));
    const UInt8* pixels = CFDataGetBytePtr(imageData);
    int darkPixels = 0;
    int length = CFDataGetLength(imageData);
    int const darkPixelThreshold = (image.size.width * image.size.height) * .45;

    for (int i = 0; i < length; i += 4) {
        int r = pixels[i];
        int g = pixels[i + 1];
        int b = pixels[i + 2];
        float luminance = (0.299 * r + 0.587 * g + 0.114 * b);
        if (luminance < 150) darkPixels++;
    }

    if (darkPixels >= darkPixelThreshold)
        isDark = YES;

    CFRelease(imageData);

    return isDark;

}

@end
