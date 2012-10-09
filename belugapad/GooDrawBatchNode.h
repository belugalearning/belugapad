//
//  GooDrawBatchNode.h
//  belugapad
//
//  Created by gareth on 07/10/2012.
//
//

#import "CCNode.h"
#import "cocos2d.h"
#import "ObjectiveChipmunk.h"
#import "GooProtocols.h"

@interface GooDrawBatchNode : CCNode
{
    ChipmunkSpace *cSpace;
    
}

@property (retain) NSArray *gooShapes;

@property (retain) NSArray *springShapes;

-(GooDrawBatchNode*)initWithSpace:(ChipmunkSpace*)thespace;

@end
