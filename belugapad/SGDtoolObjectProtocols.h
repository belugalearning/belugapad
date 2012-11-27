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
@class SGBtxeRow;

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
-(void)selectMe;

@end


@protocol Selectable

@property BOOL Selected;
@property float HitProximity;

@end

@protocol Pairable

@property CGPoint Position;
@property (retain) NSMutableArray *PairedObjects;
@property BOOL SeekingPair;
@property (retain) CCLabelTTF *Label;

-(void)pairMeWith:(id)thisObject;
-(void)unpairMeFrom:(id)thisObject;
-(void)draw:(int)z;
-(void)destroyThisObject;

@end

@protocol Configurable
@property (retain) NSString *blockType;

-(void)setup;

@end

@protocol ShapeContainer

@property (retain) CCLayer *RenderLayer;
@property (retain) NSMutableArray *BlocksInShape;
@property (retain) CCLabelTTF *Label;
@property (retain) CCNode *BaseNode;
@property (retain) NSString *BlockType;
@property (retain) NSString *LineType;
@property BOOL AllowDifferentTypes;
@property BOOL ShowCount;
@property (retain) CCLabelTTF *CountLabel;
@property (retain) id BTXELabel;
@property (retain) SGBtxeRow *BTXERow;
@property BOOL IsEvalTarget;
@property BOOL Selected;

-(void)addBlockToMe:(id)thisBlock;
-(void)removeBlockFromMe:(id)thisBlock;
-(void)repositionLabel;
-(void)setGroupLabelString:(NSString*)toThisString;
-(void)setGroupBTXELabel:(id)thisLabel;
-(int)blocksInShape;
-(void)layoutMyBlocks;
-(void)destroyThisObject;
-(void)selectMyBlocks;

@end


@protocol Cage

@property CGPoint Position;
@property (retain) CCLayer *RenderLayer;
@property (retain) NSString *CageType;
@property (retain) NSString *BlockType;
@property int InitialObjects;
@property (retain) CCSprite *MySprite;
@property BOOL RandomPositions;
@property (retain) id CurrentObject;

-(void)setup;
-(void)spawnNewBlock;
-(void)removeBlockFromMe:(id)thisBlock;

@end