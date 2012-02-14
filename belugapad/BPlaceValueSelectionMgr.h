//
//  BPlaceValueSelectionMgr.h
//  belugapad
//
//  Created by David Amphlett on 13/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWBehaviour.h"

@interface BPlaceValueSelectionMgr : DWBehaviour

-(BPlaceValueSelectionMgr*)initWithGameObject:(DWGameObject *)aGameObject withData:(NSDictionary *)data;
-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload;
-(void)switchSelection;
-(void)deselect;
@end
