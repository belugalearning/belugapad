//
//  SGDtoolBlockRender.h
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGComponent.h"
#import "SGDtoolObjectProtocols.h"

@interface SGDtoolBlockRender : SGComponent
{
    id<Transform,Moveable,Pairable,Configurable, Selectable> ParentGO;
}

-(void)setup;
-(void)move;
-(void)animateToPosition;
-(BOOL)amIProximateTo:(CGPoint)location;
-(void)selectMe;
-(void)drawProximateLines:(CGPoint)location;
-(void)drawNotProximateLines:(CGPoint)location;
-(void)destroyThisObject;

@end