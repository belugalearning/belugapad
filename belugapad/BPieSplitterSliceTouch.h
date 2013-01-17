//
//  BPieSplitterSliceTouch.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPieSplitterSliceGameObject;

@interface BPieSplitterSliceTouch : DWBehaviour
{
    
    DWPieSplitterSliceGameObject *slice;
    
}

-(BPieSplitterSliceTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)checkTouch:(CGPoint)hitLoc;

@end
