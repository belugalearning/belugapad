//
//  BPieSplitterContainerTouch.h
//  belugapad
//
//  Created by David Amphlett on 07/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPieSplitterContainerGameObject;

@interface BPieSplitterContainerTouch : DWBehaviour
{
    
    DWPieSplitterContainerGameObject *cont;
    
}

-(BPieSplitterContainerTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)checkTouch:(CGPoint)hitLoc;

@end
