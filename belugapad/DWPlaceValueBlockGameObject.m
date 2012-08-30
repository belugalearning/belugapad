//
//  DWPlaceValueBlockGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueNetGameObject.h"

@implementation DWPlaceValueBlockGameObject

//@synthesize Mount;
@synthesize Mount=Mount1;
@synthesize LastMount;
@synthesize ObjectValue;
@synthesize PickupSprite;
@synthesize mySprite;
@synthesize SpriteFilename;
@synthesize PosX;
@synthesize PosY;
@synthesize AnimateMe;
@synthesize Selected;
@synthesize lastZIndex;

-(DWGameObject*)Mount
{
    return Mount1;
}

-(void)setMount:(DWGameObject *)newMount
{
    if(Mount1!=newMount)
    {
        [Mount1 release];
        Mount1=[newMount retain];
    }
}

-(void)dealloc
{
    self.Mount=nil;
    self.LastMount=nil;
    self.PickupSprite=nil;
    self.mySprite=nil;
    self.SpriteFilename=nil;
    
    [super dealloc];
}

@end
