//
//  BPieSplitterContainerObjectRender.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWBehaviour.h"

@interface BPieSplitterContainerObjectRender : DWBehaviour
{
    
}

-(BPieSplitterContainerObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)handleTap;


@end
