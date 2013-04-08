//
//  SGFBuilderObjectProtocols.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@protocol RenderedObject

@property (retain) CCLayer *RenderLayer;
@property (retain) CCSprite *MySprite;
@property CGPoint Position;

-(void)setup;
-(void)destroy;


@end


@protocol Row

@property int Denominator;
@property (retain) NSMutableArray *ContainedBlocks;
@property (retain) CCSprite *DenominatorUpButton;
@property (retain) CCSprite *DenominatorDownButton;

-(void)setRowDenominator:(int)incr;

@end

@protocol Block

@property int Denominator;
@property int TemporaryDenominator;
@property int TemporaryNumerator;
@property (retain) id ParentRow;

-(void)move;

@end

@protocol Touchable

@property CGPoint Position;

-(void)checkTouch:(CGPoint)location;

@end