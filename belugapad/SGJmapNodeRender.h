//
//  SGJmapNodeRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"
#import "SGJmapObjectProtocols.h"

@class SGJmapNode;

@interface SGJmapNodeRender : SGComponent
{
    SGJmapNode *ParentGO;
    
    CGPoint positionAsOffset;
}

-(void)draw:(int)z;
-(void)setup;
-(void)updatePosition:(CGPoint)pos;
-(void)setupArtefact;
-(void)flipSprite;

@end
