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

@interface GooDrawBatchNode : CCNode
{
    ChipmunkSpace *cSpace;
    
}

-(GooDrawBatchNode*)initWithSpace:(ChipmunkSpace*)thespace;

@end
