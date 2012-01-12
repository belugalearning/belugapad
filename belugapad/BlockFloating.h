//
//  BlockFloating.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "chipmunk.h"
#import "DWGameWorld.h"

@interface BlockFloating : CCLayer
{
    float cx;
    float cy;
    
    DWGameWorld *gameWorld;
    
    BOOL touching;
    
    cpSpace *space;
}

+(CCScene *) scene;

-(void) setupBkgAndTitle;
-(void) setupAudio;
-(void) setupSprites;
-(void) setupGW;
-(void) populateGW;
-(void)setupChSpace;
-(void) doUpdate:(ccTime)delta;
-(void) attachBodyToGO:(DWGameObject *)attachGO atPositionPayload:(NSDictionary *)positionPayload;

@end
