//
//  DWSelectorGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWSelectorGameObject.h"

@implementation DWSelectorGameObject

@synthesize pos;
@synthesize BasePos;
@synthesize PopulateVariableNames;
@synthesize WatchRambler;

-(void)dealloc
{
    self.PopulateVariableNames=nil;
    self.WatchRambler=nil;

    [super dealloc];
}

@end
