//
//  LNWindowInspector.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/27/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNWindowInspector.h"

static NSString *kAppNameKey = @"applicationName";    // Application Name & PID
static NSString *kWindowProcessID = @"processID";    // Window Origin as a string
static NSString *kWindowOriginKey = @"windowOrigin";    // Window Origin as a string
static NSString *kWindowSizeKey = @"windowSize";        // Window Size as a string
static NSString *kWindowIDKey = @"windowID";            // Window ID
static NSString *kWindowLevelKey = @"windowLevel";    // Window Level
static NSString *kWindowOrderKey = @"windowOrder";    // The overall front-to-back ordering of the windows as returned by the window server

@interface WindowListApplierData : NSObject

@property (strong, nonatomic) NSMutableArray * outputArray;
@property int order;

@end

@implementation WindowListApplierData
- (instancetype)initWindowListData:(NSMutableArray *)array
{
    self = [super init];
    
    self.outputArray = array;
    self.order = 0;
    
    return self;
}
@end

@interface LNWindowInspector ()

@property (strong) WindowListApplierData *windowListData;
@property (assign) CGWindowListOption listOptions;
@property (assign) CGWindowImageOption imageOptions;
@property (strong) NSArrayController *arrayController;

@end

@implementation LNWindowInspector

// Simple helper to twiddle bits in a uint32_t.
uint32_t ChangeBits(uint32_t currentBits, uint32_t flagsToChange, BOOL setFlags);
inline uint32_t ChangeBits(uint32_t currentBits, uint32_t flagsToChange, BOOL setFlags)
{
    if(setFlags)
    {    // Set Bits
        return currentBits | flagsToChange;
    }
    else
    {    // Clear Bits
        return currentBits & ~flagsToChange;
    }
}

void WindowListApplierFunction(const void *inputDictionary, void *context);
void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    WindowListApplierData *data = (__bridge WindowListApplierData*)context;
    
    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [entry[(id)kCGWindowSharingState] intValue];
    if(sharingState != kCGWindowSharingNone)
    {
        NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];
        
        // Grab the application name, but since it's optional we need to check before we can use it.
        NSString *applicationName = entry[(id)kCGWindowOwnerName];
        if(applicationName != NULL)
        {
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"%@ (%@)", applicationName, entry[(id)kCGWindowOwnerPID]];
            outputEntry[kAppNameKey] = nameAndPID;
        }
        else
        {
            // The application name was not provided, so we use a fake application name to designate this.
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", entry[(id)kCGWindowOwnerPID]];
            outputEntry[kAppNameKey] = nameAndPID;
        }
        
        NSString *pid = [NSString stringWithFormat:@"%@", entry[(id)kCGWindowOwnerPID]];
        outputEntry[kWindowProcessID] = pid;
        
        outputEntry[@"windowIsOnScreen"] = entry[(id)kCGWindowIsOnscreen];
        outputEntry[@"windowAlpha"] = entry[(id)kCGWindowAlpha];

        // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as a string
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)entry[(id)kCGWindowBounds], &bounds);
        NSString *originString = [NSString stringWithFormat:@"%.0f/%.0f", bounds.origin.x, bounds.origin.y];
        outputEntry[kWindowOriginKey] = originString;
        NSString *sizeString = [NSString stringWithFormat:@"%.0f*%.0f", bounds.size.width, bounds.size.height];
        outputEntry[kWindowSizeKey] = sizeString;
        
        // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
        outputEntry[kWindowIDKey] = entry[(id)kCGWindowNumber];
        outputEntry[kWindowLevelKey] = entry[(id)kCGWindowLayer];
        
        // Finally, we are passed the windows in order from front to back by the window server
        // Should the user sort the window list we want to retain that order so that screen shots
        // look correct no matter what selection they make, or what order the items are in. We do this
        // by maintaining a window order key that we'll apply later.
        outputEntry[kWindowOrderKey] = @(data.order);
        data.order++;
        
        [data.outputArray addObject:outputEntry];
    }
}

- (id)init
{
    self = [super init];
    if(self){
        // Set the initial list options to match the UI.
        self.listOptions = kCGWindowListOptionAll;
        self.listOptions = ChangeBits(self.listOptions, kCGWindowListOptionOnScreenOnly, YES);
        self.listOptions = ChangeBits(self.listOptions, kCGWindowListExcludeDesktopElements, YES);
        
        // Set the initial image options to match the UI.
        self.imageOptions = kCGWindowImageDefault;
        self.imageOptions = ChangeBits(self.imageOptions, kCGWindowImageBoundsIgnoreFraming, YES);
        self.imageOptions = ChangeBits(self.imageOptions, kCGWindowImageShouldBeOpaque, YES);
        self.imageOptions = ChangeBits(self.imageOptions, kCGWindowImageOnlyShadows, NO);
        self.arrayController = [NSArrayController new];
        [self updateWindowList];
    }
    return self;
}

-(void)updateWindowList
{
    // Ask the window server for the list of windows.
    CFArrayRef windowList = CGWindowListCopyWindowInfo(self.listOptions, kCGNullWindowID);
    
    // Copy the returned list, further pruned, to another list. This also adds some bookkeeping
    // information to the list as well as
    NSMutableArray * prunedWindowList = [NSMutableArray array];
    self.windowListData = [[WindowListApplierData alloc] initWindowListData:prunedWindowList];
    
    CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, (__bridge void *)(self.windowListData));
    CFRelease(windowList);
    
    // Set the new window list
    [self.arrayController setContent:prunedWindowList];
}

#pragma mark - Public

- (NSArray<NSDictionary*>*)getWindows
{
    [self updateWindowList];
    return self.arrayController.arrangedObjects;
}

- (NSDictionary*)getFrontWindow
{
    NSArray<NSDictionary*>*windows = [self getWindows];
    NSRunningApplication *frontmostApplication = [NSWorkspace sharedWorkspace].frontmostApplication;
    NSDictionary *frontWindow;
    for(NSDictionary *window in [[windows reverseObjectEnumerator] allObjects]) {
        if([window[kWindowProcessID] intValue] == frontmostApplication.processIdentifier) {
            frontWindow = window;
        }
    }
    return frontWindow;
}

@end
