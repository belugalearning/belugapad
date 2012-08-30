//
//  BNLineRamblerRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@class DWRamblerGameObject;

@interface BNLineRamblerRender : DWBehaviour
{
    DWRamblerGameObject *ramblerGameObject;
    
    NSMutableArray *assBlankSegments;
    NSMutableArray *assLineSegments;
    NSMutableArray *assIndicators;
    
    CCSprite *assStartTerminator;
    CCSprite *assEndTerminator;
    
    NSMutableDictionary *assLabels;
    CCLayer *labelLayer;
    
    NSMutableArray *markerSprites;
}

-(BNLineRamblerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;


@end



