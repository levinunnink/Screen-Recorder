//
//  LNWindowInspector.h
//  Screen Capture
//
//  Created by Levi Nunnink on 2/27/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LNWindowInspector : NSObject

- (NSArray<NSDictionary*>*)getWindows;
- (NSDictionary*)getFrontWindow;

@end

NS_ASSUME_NONNULL_END
