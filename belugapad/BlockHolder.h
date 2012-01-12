//
//  BlockHolder.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "DWGameWorld.h"

@interface BlockHolder : CCLayer
{
    float cx;
    float cy;
    
    DWGameWorld *gameWorld;
    
    NSInteger tapCount;
    
    BOOL touching;
}

+(CCScene *) scene;

-(void) setupBkgAndTitle;
-(void) setupAudio;
-(void) setupSprites;
-(void) setupGW;
-(void) populateGW;
-(void) doUpdate:(ccTime)delta;


@end
