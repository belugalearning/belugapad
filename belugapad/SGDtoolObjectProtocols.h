//
//  SGDtoolObjectProtocols.h
//  belugapad
//
//  Created by Dave Amphlett on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGDtoolBlockRender;
@class SGDtoolBlockPairing;

@protocol Transform

@property CGPoint Position;
@property BOOL Visible;
@property (retain) CCLayer *RenderLayer;

@end

@protocol Moveable

@property CGPoint Position;
@property (retain) CCSprite *mySprite;

-(void)move;
-(BOOL)amIProximateTo:(CGPoint)location;
-(void)resetTint;

@end


@protocol Selectable

@property BOOL Selected;
@property float HitProximity;

@end

@protocol Pairable

@property CGPoint Position;
@property (retain) NSMutableArray *PairedObjects;

-(void)pairMeWith:(id)thisObject;
-(void)unpairMeFrom:(id)thisObject;

@end

@protocol Configurable

-(void)setup;

@end



