//
//  SCGIFConverter.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LNGIFConverter : NSObject

+ (LNGIFConverter*)instance;
- (void)convertFileAtPath:(NSURL*)filePath;

@end
