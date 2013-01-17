//
//  DWDotGridAnchorGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWTTTileGameObject.h"

@implementation DWTTTileGameObject

@synthesize Position;
@synthesize Size;
@synthesize Disabled;
@synthesize Selected;
@synthesize selSprite;
@synthesize mySprite;
@synthesize ansSprite;
@synthesize myText;
@synthesize myXpos;
@synthesize myYpos;
@synthesize operatorType;
@synthesize isEndXPiece;
@synthesize isEndYPiece;
@synthesize isCornerPiece;

-(void)dealloc
{
    self.mySprite=nil;
    self.selSprite=nil;
    self.ansSprite=nil;
    self.myText=nil;
    
    [super dealloc];
}

@end
