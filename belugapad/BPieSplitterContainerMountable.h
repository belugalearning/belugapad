//
//  BPieSplitterContainerMountable.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPieSplitterContainerGameObject;

@interface BPieSplitterContainerMountable : DWBehaviour
{
    DWPieSplitterContainerGameObject *cont;
}

-(BPieSplitterContainerMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)checkDropTarget:(CGPoint)hitLoc;
-(void)mountObjectToMe;
-(void)unMountObjectFromMe;
-(void)unMountAllMountedObjectsFromMe;
-(void)scaleMidSection;
@end
