//
//  BFloatPickupTarget.h
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@interface BFloatPickupTarget : DWBehaviour
{
    NSMutableArray *lookupSpriteMatrix;
}


-(BFloatPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(NSMutableArray *)lookupSprites;


@end
