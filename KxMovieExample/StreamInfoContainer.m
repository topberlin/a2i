//
//  StreamInfoContainer.m
//  kxmovie
//
//  Created by Philipp on 28.04.15.
//
//

#import <Foundation/Foundation.h>
#import "StreamInfoContainer.h"
static float _width = 0;
static float _height = 0;


@implementation StreamInfoContainer


+ (float) getWidth {
    return _width;
}

+ (void) setWidth:(float)Width {
    _width = Width;
}

+ (float) getHeight {
    return _height;
}

+ (void) setHeight:(float)Height {
    _height = Height;
}

+(void) test {
    NSLog(@"HAllo");
}
@end
