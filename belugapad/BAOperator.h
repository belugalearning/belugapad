//
//  BAOperator.h
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAExpression.h"
#import "BAInteger.h"
#import "BAVariable.h"

/*
	BAOperator is the superclass for all operator expressions. To add an operator, make a new subclass.
 
	An operator is not a literal (meaning it can (should, actually) have children)
	- Binary operators can have two children (power, division)
	- Unary operators only have one child
 
	- The "commutative" property determins if the order of the children can be changed without changing the value of the expression (defalut is yes)
	http://en.wikipedia.org/wiki/Commutativity
	
 */

typedef enum
{
	BAOperatorType_Unknown = 0,
	BAOperatorType_Binary,
	BAOperatorType_Unary,
}BAOperatorType;

@interface BAOperator : BAExpression 

+ (id)operator;
- (BOOL)isCommutative;

@end

@interface BAOperator(BAInternal)

- (BAExpression*)evaluateForExpressions:(NSArray*)theChildren;

- (BAInteger*)leftIntegerExpressionForEvaluation;
- (BAInteger*)rightIntegerExpressionForEvaluation;

- (BAOperatorType)operatorType;
- (BOOL)isInPrecedenceGroupWith:(BAOperator*)theOtherOperator;

@end
