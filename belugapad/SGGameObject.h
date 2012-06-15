//
//  SGGameObject.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGameWorld.h"

@class SGComponent;

@interface SGGameObject : NSObject {
	SGGameWorld *gameWorld;
}

@property (nonatomic, retain) SGGameWorld *gameWorld;

-(SGGameObject *)initWithGameWorld:(SGGameWorld *)aGameWorld;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel;
-(void)handleMessage:(SGMessageType)messageType;
-(void)initComplete;

-(void)cleanup;

@end
