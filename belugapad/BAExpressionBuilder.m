//
//  BAExpressionBuilder.m
//  Beluga
//
//  Created by Cathy Shive on 1/26/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAExpressionBuilder.h"
#import "BAExpressionHeaders.h"
#import "NSArray_BAAdditions.h"

@implementation BAExpressionBuilder


#pragma mark -
#pragma mark API
NSInteger randomIntInRange(NSInteger start, NSUInteger length)
{
	return  ((NSInteger)(arc4random() % length) + start);
}


//NSInteger randomIntInRange(NSInteger lowerBound, NSInteger upperBound)
//{
//    NSInteger length = upperBound - lowerBound + 1;
//    
//	return  ((arc4random() % (length)) + lowerBound);
//}


NSInteger gcd(NSInteger a, NSInteger b)
{
    if (b > a) goto b_larger;
    while (1) {
        a = a % b;
        if (a == 0) return b;
	b_larger:
        b = b % a;
        if (b == 0) return a;
    }
}


+(NSArray*)simpleOperatorClasses
{
	// returns simple operators (+, *, %) as opposed to (power, brackets or equality operators)
	return [NSArray arrayWithObjects:[BAAdditionOperator class],
									 [BAMultiplicationOperator class],
									 [BADivisionOperator class], nil];
}

+ (NSArray*)complexOperatorClasses
{
	return [NSArray arrayWithObjects:[BAPowerOperator class],
									 [BABracketOperator class], nil];
}

+ (NSArray*)possibleVariableNames
{
	return [NSArray arrayWithObjects:@"x", @"y", @"a", @"b", @"p", @"q", nil];// x,y,a,b,p,q,
}

+ (BAVariable*)randomVariable
{	
	/*
	 CS: Notes from Alastair C. on generating variables:
	 
	 generation of variable
	 x can be either x, y, z, a or b according to following
	 liklihood	variable
	 3/4   		   x
	 1/4		y , z, a, b	
	 */
	
	// Pick a random int bewween 1 and 16
	// 1-12 will result in an x
	// 13-16 will map to the other possibilities
	NSInteger aRandomInt = randomIntInRange(1, 16);
	switch(aRandomInt)
	{
		case 13:
			return [BAVariable variableWithName:@"y" multiplierIntValue:1];
		case 14:
			return [BAVariable variableWithName:@"z" multiplierIntValue:1];
		case 15:
			return [BAVariable variableWithName:@"a" multiplierIntValue:1];
		case 16:
			return [BAVariable variableWithName:@"b" multiplierIntValue:1];				
		default:
			return [BAVariable variableWithName:@"x" multiplierIntValue:1];
	}
	
}

+ (BAPowerOperator*)randomPowerExpression
{
	BAPowerOperator * aPowerOperator = [[[BAPowerOperator alloc] init] autorelease];
	
	// the base is a random int (1-9)
	NSInteger aRandomBase = randomIntInRange(2, 8);
	// the exponenet is a random int (2-9)
	NSInteger aRandomExponent;
	if(aRandomBase <= 4) // exponent value (2-4)
		aRandomExponent = randomIntInRange(2, 3);
	else if(aRandomBase > 4 && aRandomBase <= 6) // exponent value (2-3)
		aRandomExponent = randomIntInRange(2, 2);
	else if(aRandomBase > 6) // any base over 6 can only have an exponent of '2'
		aRandomExponent = 2;
	
	[aPowerOperator addChild:[BAInteger integerWithIntValue:aRandomBase]];
	[aPowerOperator addChild:[BAInteger integerWithIntValue:aRandomExponent]];
	return aPowerOperator;
}
		
+ (BABracketOperator*)randomBracketExpression
{
	BABracketOperator * aBracketOperator = [[[BABracketOperator alloc] init] autorelease];
	[aBracketOperator addChild:[self randomSimpleOperationExpression]];
	return aBracketOperator;
}

+ (BAExpression*)randomSimpleOperationExpression
{
	// pick a random operator
	id anOperatorClass = [NSArray randomObjectFromArray:[self simpleOperatorClasses]];
	BAExpression * anExpressionToReturn = nil;
	if(anOperatorClass == [BADivisionOperator class])
		anExpressionToReturn = [self randomDivisionExpression];
	else if(anOperatorClass == [BAMultiplicationOperator class])
		anExpressionToReturn = [self randomMultiplicationExpression];
	else if(anOperatorClass == [BAAdditionOperator class])
		anExpressionToReturn = [self randomAdditionExpression];
	return anExpressionToReturn;
}

+ (BADivisionOperator*)randomDivisionExpression
{
	BADivisionOperator * aDivisionOperator = [[[BADivisionOperator alloc] init] autorelease];
	// rules for division opertors
	// divisor cannot be 0
	NSInteger aDivisorInt = randomIntInRange(1, 9);
	// the numerator is chosen so that the divisor divides evenly into it
	// so that the result is always an integer
	NSInteger aNumeratorInt = aDivisorInt * randomIntInRange(1, 9);
	
	[aDivisionOperator addChild:[BAInteger integerWithIntValue:aNumeratorInt]];	
	[aDivisionOperator addChild:[BAInteger integerWithIntValue:aDivisorInt]];
	
	return aDivisionOperator;
}

+ (BAMultiplicationOperator*)randomMultiplicationExpression
{
	BAMultiplicationOperator * aMultiplicationOperator = [[[BAMultiplicationOperator alloc] init] autorelease];
	[aMultiplicationOperator addChild:[BAInteger integerWithIntValue:randomIntInRange(1, 9)]];
	[aMultiplicationOperator addChild:[BAInteger integerWithIntValue:randomIntInRange(1, 9)]];
	return aMultiplicationOperator;
}

+ (BAAdditionOperator*)randomAdditionExpression
{
	BAAdditionOperator * anAdditionOperator = [[[BAAdditionOperator alloc] init] autorelease];
	[anAdditionOperator addChild:[BAInteger integerWithIntValue:randomIntInRange(-9, 18)]];
	[anAdditionOperator addChild:[BAInteger integerWithIntValue:randomIntInRange(-9, 18)]];
	return anAdditionOperator;
}
@end


