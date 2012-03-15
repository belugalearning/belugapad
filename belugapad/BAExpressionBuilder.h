//
//  BAExpressionBuilder.h
//  Beluga
//
//  Created by Cathy Shive on 1/26/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
	BAExpressionBuilder is a helper for generating expressions for different problems.
 
	If you add new subclasses to BAExpression and you want them to be generated randomly, 
    you can add support for the new expression classes to the exisiting API or create new API here.
*/

@class BAExpression;
@class BAInteger;
@class BAVariable;
@class BAPowerOperator;
@class BABracketOperator;
@class BADivisionOperator;
@class BAMultiplicationOperator;
@class BAAdditionOperator;

@interface BAExpressionBuilder : NSObject 
{
}

NSInteger gcd(NSInteger a, NSInteger b);
NSInteger randomIntInRange(NSInteger start, NSUInteger length);

+ (NSArray*)simpleOperatorClasses;
+ (NSArray*)complexOperatorClasses;
+ (NSArray*)possibleVariableNames;
+ (BAVariable*)randomVariable;
+ (BADivisionOperator*)randomDivisionExpression;
+ (BAAdditionOperator*)randomAdditionExpression;
+ (BAMultiplicationOperator*)randomMultiplicationExpression;
+ (BAExpression*)randomSimpleOperationExpression;
+ (BAPowerOperator*)randomPowerExpression;
+ (BABracketOperator*)randomBracketExpression;
@end
