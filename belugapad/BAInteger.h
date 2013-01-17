//
//  BAInteger.h
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAExpression.h"
/*
	- BAInteger is an expression with an Integer value
	- A BAInteger a literal expression, so it doesn't have a children
*/

typedef enum
{
	BAIntegerSymbolType_Prefix = 0,
	BAIntegerSymbolType_Suffix
	
} BAIntegerSymbolType; // deprecated

@interface BAInteger : BAExpression
{
	NSInteger				mIntValue;
@private
	// The following is a hack to add a feature quickly for Alastair, but it's not really working out  
	// I recommend removing the "symbols string" feature all together from BAInteger
	NSString *				mSymbolString;
	BAIntegerSymbolType		mSymbolType;
}
@property (nonatomic, readwrite, assign) NSInteger intValue;
@property (nonatomic, readonly, copy) NSString * symbolString; // deprecated
@property (nonatomic, readonly, assign) BAIntegerSymbolType symbolType; // deprecated

/*
	integerWithIntValue: 
	- returns an autoreleased object with that int value configured
*/
+(BAInteger*)integerWithIntValue:(NSInteger)theIntValue;
/*
	- returns a list of the possible factors of this integer value as multiplication expressions
	example:
	if [anInt intValue] = 36
	the result of [anInt factors] looks like: 
    ["1 × 36", "2 × 18", "3 × 12", "4 × 9", "6 × 6", "9 × 4", "12 × 3", "18 × 2", "36 × 1"]
*/
- (NSArray*)factors;

@end

@interface BAInteger(BADeprecated)

- (void)setSymbolString:(NSString *)symbolString;
- (void)setSymbolType:(BAIntegerSymbolType)symbolType;

@end