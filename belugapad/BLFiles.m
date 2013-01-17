//
//  BLFiles.m
//  belugapad
//
//  Created by Gareth Jenkins on 28/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BLFiles.h"

@implementation BLFiles

// return a new autoreleased UUID string
+ (NSString *)generateUuidString
{
    // create a new UUID which you own
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    
    // create a new CFStringRef (toll-free bridged to NSString)
    // that you own
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    
    // transfer ownership of the string
    // to the autorelease pool
    [uuidString autorelease];
    
    // release the UUID
    CFRelease(uuid);
    
    return uuidString;
}

@end
