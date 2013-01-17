//
//  SGGameObject.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGameWorld.h"

@class SGComponent;

@protocol GameObject
-(void)handleMessage:(SGMessageType)messageType;
-(void)doUpdate:(ccTime)delta;
@end

@interface SGGameObject : NSObject {
	SGGameWorld *gameWorld;
}

@property (nonatomic, assign) SGGameWorld *gameWorld;

-(SGGameObject *)initWithGameWorld:(SGGameWorld *)aGameWorld;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(SGMessageType)messageType;

-(void)cleanup;

@end
