//
//  SGFBlockObjectProtocols.h
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"



@protocol Group

@property (retain) NSMutableArray *MyBlocks;
@property int MaxObjects;

-(void)addObject:(id)thisObject;
-(void)removeObject:(id)thisObject;
-(BOOL)checkTouchInGroupAt:(CGPoint)location;
-(void)moveGroupPositionFrom:(CGPoint)fromHere To:(CGPoint)here;
-(BOOL)checkIfInBubbleAt:(CGPoint)location;
-(void)tintBlocksTo:(ccColor3B)thisColour;
-(void)inflateZIndexOfMyObjects;
-(void)resetZIndexOfMyObjects;
-(void)destroy;


@end

@protocol Moveable

@property CGPoint Position;
@property (retain) id MyGroup;

-(void)move;

@end

@protocol Rendered

@property BOOL Replacement;
@property (retain) CCSprite *MySprite;
@property (retain) CCLayer *RenderLayer;
@property CGPoint Position;
@property int zIndex;


-(void)setup;
-(void)fadeAndDestroy;

@end

@protocol Target

@property (retain) NSMutableArray *GroupsInMe;

-(void)addGroup:(id)thisGroup;
-(void)removeGroup:(id)thisGroup;
-(int)containedGroups;
-(void)fadeAndDestroy;


@end

@protocol Operator

@property (retain) NSArray *SupportedOperators;
@property (retain) NSString *OperatorType;
@property (retain) CCLabelTTF *Label;
@property (retain) NSMutableArray *ChildOperators;

-(BOOL)amIProximateTo:(CGPoint)location;
-(void)fadeAndDestroy;
-(void)showOtherOperators;

@end