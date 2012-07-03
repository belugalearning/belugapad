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
@property (retain) CCSpriteBatchNode *RenderBatch;

@end


@protocol Selectable

@property BOOL Selected;
@property (retain) SGDtoolBlockRender *BlockSelectComponent;
@property float HitProximity;

@end

@protocol Configurable

-(void) setup;

@end



