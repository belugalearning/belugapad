//
//  SGDtoolBlockPairing.m
//  belugapad
//
//  Created by David Amphlett on 06/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGDtoolBlockPairing.h"
#import "SGDtoolBlock.h"
#import "SGDtoolContainer.h"
#import "SGDtoolObjectProtocols.h"
#import "BLMath.h"

@interface SGDtoolBlockPairing()
{
    CCSprite *blockSprite;
}

@end

@implementation SGDtoolBlockPairing

-(SGDtoolBlockPairing*)initWithGameObject:(id<Pairable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}
@end

