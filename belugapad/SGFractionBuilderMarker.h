//
//  SGFractionBuilderMarker.h
//  belugapad
//
//  Created by David Amphlett on 23/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGComponent.h"
#import "SGFractionObjectProtocols.h"

@interface SGFractionBuilderMarker : SGComponent
{
    id<Configurable,Moveable,Interactive> ParentGO;
}

-(BOOL)amIProximateTo:(CGPoint)location;
-(void)moveMarkerTo:(CGPoint)location;
-(void)snapToNearestPos;

@end
