//
//  SGDtoolObjectProtocols.h
//  belugapad
//
//  Created by Dave Amphlett on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGDtoolBlockRender;

@protocol GameObject
-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel;
-(void)doUpdate:(ccTime)delta;

@end

@protocol Transform

@property CGPoint Position;
@property BOOL Visible;
@property (retain) CCLayer *RenderLayer;

@end

@protocol Moveable

@property CGPoint Position;
@property (retain) CCSprite *mySprite;

-(void)move;

@end


@protocol Selectable

@property BOOL Selected;
@property float HitProximity;

@end

@protocol Configurable

-(void)setup;

@end



