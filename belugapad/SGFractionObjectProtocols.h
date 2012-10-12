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
@property BOOL AutoShadeNewChunks;
@property BOOL ShowEquivalentFractions;
@property BOOL ShowCurrentFraction;
@property (retain) CCLabelTTF *CurrentFraction;

-(void)setup;
-(void)showFraction;
-(void)hideFraction;


@end

@protocol Interactive

@property (readonly) int Divisions;
@property float Value;
@property (retain) NSMutableArray *Chunks;
@property (retain) NSMutableArray *GhostChunks;
@property int MarkerPosition;
@property int Tag;

-(void)snapToNearestPos;
-(void)ghostChunk;
-(id)createChunk;
-(void)removeChunks;

@end

@protocol ConfigurableChunk

@property (retain) CCLayer *RenderLayer;
@property (retain) id MyParent;
@property (retain) id CurrentHost;
@property CGPoint Position;
@property float Value;
@property float ScaleX;
@property (retain) CCSprite *MySprite;
@property BOOL Selected;

-(void)setup;
-(void)changeChunk:(id<ConfigurableChunk>)thisChunk toBelongTo:(id<Interactive>)newFraction;

@end

@protocol Moveable

@property CGPoint Position;

-(BOOL)amIProximateTo:(CGPoint)location;
-(void)moveMarkerTo:(CGPoint)location;

@end

@protocol MoveableChunk

@property CGPoint Position;
@property BOOL Selected;

-(BOOL)amIProximateTo:(CGPoint)location;
-(void)moveChunk;
-(void)changeChunkSelection;
-(BOOL)checkForChunkDropIn:(id<Configurable>)thisObject;
-(void)returnToParentSlice;
@end

