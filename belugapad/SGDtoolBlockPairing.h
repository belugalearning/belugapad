//
//  SGDtoolBlockPairing.h
//  belugapad
//
//  Created by David Amphlett on 06/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGComponent.h"
#import "SGDtoolObjectProtocols.h"

@interface SGDtoolBlockPairing : SGComponent
{
    id<Pairable> ParentGO;
}

-(void)draw:(int)z;
-(void)pairMeWith:(id)thisObject;
-(void)pairPickupObjectToMe:(id)pickupObject;
-(void)unpairMeFrom:(id)thisObject;
-(void)unpairPickupObjectFromMe:(id)pickupObject;

@end