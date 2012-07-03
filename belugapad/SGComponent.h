//
//  SGComponent.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "SGGameObject.h"

@interface SGComponent : NSObject
{
	@public SGGameObject *gameObject;
	@public SGGameWorld *gameWorld;
	
}

-(SGComponent *)initWithGameObject:(SGGameObject *)aGameObject;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(SGMessageType)messageType;
-(SGGameObject *)parentGameObject;
-(void)cleanup;

@end
