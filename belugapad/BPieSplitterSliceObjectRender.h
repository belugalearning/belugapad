//
//  BPieSplitterSliceObjectRender.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPieSplitterSliceGameObject;

@interface BPieSplitterSliceObjectRender : DWBehaviour
{
    DWPieSplitterSliceGameObject *slice;
}

-(BPieSplitterSliceObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)moveSprite;
-(void)moveSpriteHome;
-(void)handleTap;


@end
