//
//  BPieSplitterSliceMount.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPieSplitterSliceGameObject;

@interface BPieSplitterSliceMount : DWBehaviour
{
    DWPieSplitterSliceGameObject *slice;
}

-(BPieSplitterSliceMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)mountMeToContainer;
-(void)unMountMeFromContainer;
@end
