//
//  SCGIFConverter.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kLNNotificationGIFCreationBegan;
extern NSString* const kLNNotificationGIFCreationProgress;
extern NSString* const kLNNotificationGIFCreationComplete;
extern NSString* const kLNGIFCreationProgressValueKey;
extern NSString* const kLNGIFCreationProgressMinValueKey;
extern NSString* const kLNGIFCreationProgressMaxValueKey;


@interface LNGIFConverter : NSObject

+ (LNGIFConverter*)instance;
- (NSURL*)convertFileAtPath:(NSURL*)filePath withName:(NSString*)fileName;
- (NSString*)saveImageSequenceAsGIF:(NSArray*)images withName:(NSString*)fileName;

@end
