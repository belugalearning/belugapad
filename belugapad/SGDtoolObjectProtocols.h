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
@property (retain) id MyContainer;

-(void)move;
-(void)animateToPosition;
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
@property BOOL SeekingPair;

-(void)pairMeWith:(id)thisObject;
-(void)unpairMeFrom:(id)thisObject;
-(void)draw:(int)z;

@end

@protocol Configurable

-(void)setup;

@end

@protocol Container

@property (retain) NSMutableArray *BlocksInShape;
@property (retain) CCLabelTTF *Label;
@property (retain) CCNode *BaseNode;

-(void)addBlockToMe:(id)thisBlock;
-(void)removeBlockFromMe:(id)thisBlock;
-(int)blocksInShape;

@end


