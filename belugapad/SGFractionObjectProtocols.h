//
//  SGDtoolObjectProtocols.h
//  belugapad
//
//  Created by Dave Amphlett on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class SGDtoolBlockRender;
@class SGDtoolBlockPairing;

@protocol Configurable

typedef enum
{
    kFractionInput=0,
    kFractionOutput=1
} FractionMode;

@property (retain) CCLayer *RenderLayer;
@property BOOL HasSlider;
@property BOOL CreateChunksOnInit;
@property BOOL CreateChunks;
@property FractionMode FractionMode;
@property CGPoint Position;
@property (retain) CCSprite *FractionSprite;
@property (retain) CCSprite *SliderSprite;
@property (retain) CCSprite *SliderMarkerSprite;
@property (retain) CCNode *BaseNode;
@property int MarkerStartPosition;

-(void)setup;


@end

@protocol ConfigurableChunk

@property (retain) CCLayer *RenderLayer;
@property (retain) id MyParent;
@property (retain) id CurrentHost;
@property CGPoint Position;
@property float Value;
@property (retain) CCSprite *MySprite;

-(void)setup;

@end

@protocol Interactive

@property int Divisions;
@property float Value;
@property (retain) NSMutableArray *Chunks;
@property (retain) NSMutableArray *GhostChunks;
@property int MarkerPosition;
@property int Tag;

-(void)snapToNearestPos;
-(void)ghostChunk;
-(void)createChunk;
-(void)removeChunks;

@end


@protocol Moveable

@property CGPoint Position;

-(BOOL)amIProximateTo:(CGPoint)location;
-(void)moveMarkerTo:(CGPoint)location;

@end

@protocol MoveableChunk

@property CGPoint Position;

-(BOOL)amIProximateTo:(CGPoint)location;
-(void)moveChunkTo:(CGPoint)location;

@end

