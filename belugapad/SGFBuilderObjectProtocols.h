//
//  SGFBuilderObjectProtocols.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@protocol Row

@property int Denominator;
@property (retain) NSMutableArray *ContainedBlocks;


@end

@protocol Block

@property int Denominator;
@property int TemporaryDenominator;
@property int TemporaryNumerator;
@property (retain) id ParentRow;

-(void)move;

@end

