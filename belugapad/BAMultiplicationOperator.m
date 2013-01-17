//
//  BAMultiplicationOperator.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAMultiplicationOperator.h"
#import "BAPowerOperator.h"
#import "BADivisionOperator.h"
#import "BAVariable.h"

@implementation BAMultiplicationOperator
- (BAOperatorType)operatorType
{
	return BAOperatorType_Binary;
}

- (BOOL)isCommutative
{
	return YES;
}

- (BAExpression*)evaluateForExpressions:(NSArray*)theChildren
{
	if([theChildren count] != 2)
		[NSException raise:@"BAMultiplicationOperator" format:@"evaluateForExpressions: - children array must have 2 objects"];
	
	BAExpression * aLeftChild = [theChildren objectAtIndex:0];
	BAExpression * aRightChild = [theChildren objectAtIndex:1];
	
	// multiplying an integer with an integer
	if(		[aLeftChild isKindOfClass:[BAInteger class]]
	   &&	[aRightChild isKindOfClass:[BAInteger class]])
	{
			
		if([(BAInteger*)aLeftChild symbolString]
		   || [(BAInteger*)aRightChild symbolString])
		{
			// just arbitrarily choosing to take the right-most symbols string to apply to the resutl int
			NSString * aSymbolString = [(BAInteger*)aRightChild symbolString] ? [(BAInteger*)aRightChild symbolString]:[(BAInteger*)aLeftChild symbolString];
			BAIntegerSymbolType aSymbolType = [(BAInteger*)aRightChild symbolString] ? [(BAInteger*)aRightChild symbolType]:[(BAInteger*)aLeftChild symbolType]; 
			BAInteger * anInteger = [BAInteger integerWithIntValue:[(BAInteger*)aLeftChild intValue]*[(BAInteger*)aRightChild intValue]];
			[anInteger setSymbolString:aSymbolString];
			[anInteger setSymbolType:aSymbolType];
			return anInteger;
		}
		return [BAInteger integerWithIntValue:[(BAInteger*)aLeftChild intValue]*[(BAInteger*)aRightChild intValue]];
	}
	// multiplying an integer with a variable
	else if(	(	[aLeftChild isKindOfClass:[BAVariable class]]
				 ||	[aRightChild isKindOfClass:[BAVariable class]])
			&&	(	[aLeftChild isKindOfClass:[BAInteger class]]
				 || [aRightChild isKindOfClass:[BAInteger class]]))
	{
		BAInteger * anInteger = [aLeftChild isKindOfClass:[BAInteger class]] ? (BAInteger*)aLeftChild:(BAInteger*)aRightChild;
		BAVariable * aVariable = [aLeftChild isKindOfClass:[BAVariable class]] ? (BAVariable*)aLeftChild:(BAVariable*)aRightChild;
		// multiply the ints
		NSInteger aNewMultiplier = [anInteger intValue] * [aVariable multiplierIntValue];
		if(aNewMultiplier!=0)
			return [BAVariable variableWithName:[aVariable name] multiplierIntValue:aNewMultiplier];
		else
			return [BAInteger integerWithIntValue:0];
	}
	// multiplying 2 variables
	else if(	[aLeftChild isKindOfClass:[BAVariable class]]
			&&	[aRightChild isKindOfClass:[BAVariable class]]
			&& [[(BAVariable*)aLeftChild name] isEqualToString:[(BAVariable*)aRightChild name]])
	{
		// multiplying a variable with a variable results in an exponent value of 2, the result is a power operator
		BAPowerOperator * aPowerOperator = [[[BAPowerOperator alloc] init] autorelease];
		BAInteger * anExponent = [BAInteger integerWithIntValue:2];
		NSInteger aMultiplier = [(BAVariable*)aLeftChild multiplierIntValue]*[(BAVariable*)aRightChild multiplierIntValue];
		BAVariable * aNewVariable = [BAVariable variableWithName:[(BAVariable*)aLeftChild name] multiplierIntValue:aMultiplier];
		[aPowerOperator setChildren:[NSArray arrayWithObjects:aNewVariable, anExponent, nil]];
		return aPowerOperator;
	}
	
	// Multiplying an power operator with a variable
	else if(	(	[aLeftChild isKindOfClass:[BAVariable class]]
				||	[aRightChild isKindOfClass:[BAVariable class]])
			&&	(	[aLeftChild isKindOfClass:[BAPowerOperator class]]
				 || [aRightChild isKindOfClass:[BAPowerOperator class]]))
	{
		BAPowerOperator * aPowerOperator = [aLeftChild isKindOfClass:[BAPowerOperator class]]?(BAPowerOperator*)aLeftChild:(BAPowerOperator*)aRightChild;
		BAVariable * aVariable = [aLeftChild isKindOfClass:[BAVariable class]]?(BAVariable*)aLeftChild:(BAVariable*)aRightChild;
		
		// the right child of the variable has to be a variable with the same name as the variable		
		BAExpression * aBase = [[aPowerOperator children] objectAtIndex:0];
		if(		[aBase isKindOfClass:[BAVariable class]]
			&&	[[(BAVariable*)aBase name] isEqualToString:[aVariable name]])
		{
			// add the exponents (the current exponent value + 1)
			// multiply the variable ints
			NSInteger aNewExponent = [(BAInteger*)[[aPowerOperator children] objectAtIndex:1] intValue] + 1;
			NSInteger aMultiplier = [(BAVariable*)aBase multiplierIntValue]*[aVariable multiplierIntValue];
			if(aMultiplier==0)
				return [BAInteger integerWithIntValue:0];	
			BAVariable * aNewVariable = [BAVariable variableWithName:[aVariable name] multiplierIntValue:aMultiplier];
			BAPowerOperator * aNewPowerOperator = [[[BAPowerOperator alloc] init] autorelease];
			[aNewPowerOperator setChildren:[NSArray arrayWithObjects:aNewVariable, [BAInteger integerWithIntValue:aNewExponent], nil]];
			return aNewPowerOperator;
		}
	}
	else if(	[aLeftChild isKindOfClass:[BAPowerOperator class]]
			&&	[aRightChild isKindOfClass:[BAPowerOperator class]])
	{
		// multiplying two exponents with variables
		// we need to get the variables and exponent values for each side		
		BAExpression * aLeftChildVariable = [[aLeftChild children] objectAtIndex:0];
		BAExpression * aRightChildVariable = [[aRightChild children] objectAtIndex:0];
		BAExpression * aLeftChildExponent = [[aLeftChild children] objectAtIndex:1];
		BAExpression * aRightChildExponent = [[aRightChild children] objectAtIndex:1];
		if(		[aLeftChildVariable isKindOfClass:[BAVariable class]]
		   &&	[aRightChildVariable isKindOfClass:[BAVariable class]]
		   &&	[aLeftChildExponent isKindOfClass:[BAInteger class]]
		   &&	[aRightChildExponent isKindOfClass:[BAInteger class]])
		{
		
			// the variables must be the same name
			if([[(BAVariable*)aRightChildVariable name] isEqualToString:[(BAVariable*)aLeftChildVariable name]])
			{
				NSInteger anExponentValue = [(BAInteger*)aLeftChildExponent intValue] + [(BAInteger*)aRightChildExponent intValue];
				NSInteger aMultiplierValue = [(BAVariable*)aLeftChildVariable multiplierIntValue] * [(BAVariable*)aRightChildVariable multiplierIntValue];
				if(aMultiplierValue == 0)
					return [BAInteger integerWithIntValue:0];
				
				BAVariable * aNewVariable = [BAVariable variableWithName:[(BAVariable*)aRightChildVariable name] multiplierIntValue:aMultiplierValue];
				BAInteger * aNewExponent = [BAInteger integerWithIntValue:anExponentValue];
				BAPowerOperator * aNewPowerOperator = [[[BAPowerOperator alloc] init] autorelease];
				[aNewPowerOperator setChildren:[NSArray arrayWithObjects:aNewVariable, aNewExponent, nil]];
				return aNewPowerOperator;
			}
		}
	}
	else if(	(	[aLeftChild isKindOfClass:[BADivisionOperator class]]
				 &&	([aRightChild isKindOfClass:[BAInteger class]] || [aRightChild isKindOfClass:[BAMultiplicationOperator class]])
                )
			||	(	[aRightChild isKindOfClass:[BADivisionOperator class]]
				 &&	([aLeftChild isKindOfClass:[BAInteger class]] || [aLeftChild isKindOfClass:[BAMultiplicationOperator class]])
                )
            )
	{
		// Multiplying an Integer by a division operation
		// Return a Division operation with children:
		
		// Left Child: Multiply the left side of the original division op by the integer
		// Right Child: multiply the right side of the original division op by one
		
		BADivisionOperator * aDivisionOpToReturn = [[[BADivisionOperator alloc] init] autorelease];
		
		BAMultiplicationOperator * aMultiplicationOpToReturn = nil;
		id	aMultOpSecondChild = nil;
		BADivisionOperator * aDivisionOp = nil;
		id aMultiplierInt = nil;
		
		if([aLeftChild isKindOfClass:[BADivisionOperator class]])
		{
			aDivisionOp = (BADivisionOperator*)aLeftChild;
			if([aRightChild isKindOfClass:[BAMultiplicationOperator class]])
			{
				aMultiplierInt = [(BAMultiplicationOperator*)aRightChild leftIntegerExpressionForEvaluation];
				aMultiplicationOpToReturn = [BAMultiplicationOperator operator];
				aMultOpSecondChild = [[aRightChild children] objectAtIndex:1];
			}
			else
            {
				aMultiplierInt = aRightChild;
            }
		}
		else
		{
			aDivisionOp = (BADivisionOperator*)aRightChild;
			if([aLeftChild isKindOfClass:[BAMultiplicationOperator class]])
			{
				aMultiplierInt = [(BAMultiplicationOperator*)aRightChild rightIntegerExpressionForEvaluation];
				aMultiplicationOpToReturn = [BAMultiplicationOperator operator];
				aMultOpSecondChild = [[aRightChild children] objectAtIndex:0];
			}
			else
            {
				aMultiplierInt = aLeftChild;		
            }
		}
		
		BAExpression * aLeftSide = [[aDivisionOp children] objectAtIndex:0];
		BAExpression * aRightSide = [[aDivisionOp children] objectAtIndex:1];
			

		BAMultiplicationOperator * aNewLeftSide =[[[BAMultiplicationOperator alloc] init] autorelease];
		BAInteger * aNewInt = [BAInteger integerWithIntValue:[aMultiplierInt intValue]];
		[aNewInt setSymbolString:[aMultiplierInt symbolString]];
		[aNewInt setSymbolType:[aMultiplierInt symbolType]];
		[aNewLeftSide setChildren:[NSArray arrayWithObjects:aLeftSide, aNewInt, nil]];			
			
	
					
		id aNewRightSide = aRightSide;
	
		[aDivisionOpToReturn setChildren:[NSArray arrayWithObjects:aNewLeftSide, aNewRightSide, nil]];
		
		if(aMultiplicationOpToReturn)
		{
			[aMultiplicationOpToReturn addChild:aDivisionOpToReturn];
			[aMultiplicationOpToReturn addChild:aMultOpSecondChild];
		}
		
		if(self.fullEvaluate)
		{
			if(aMultiplicationOpToReturn)
				return [aMultiplicationOpToReturn recursiveEvaluate];
			return [aDivisionOpToReturn recursiveEvaluate];
		}
		
		if(aMultiplicationOpToReturn)
		{
			return aMultiplicationOpToReturn;
		}
		return aDivisionOpToReturn;
	}
			
	return nil;
}




- (BAExpression*)evaluate
{
    // TODO: refactor with addition operator
	BAExpression * aLeftChild = [[self children] objectAtIndex:0];
	BAExpression * aRightChild = [[self children] objectAtIndex:1];
	
	// if both our children are integers,
	// we'll just operate on them right away
	// otherwise we may need to adjust the structure
	// of the expression tree a bit so that we
	// get two integer children, if its possible
	
	//---------
	
	// CS NOTE: the following code works the same for both the addition operator 
	// and the multiplicaiton operator. (they're both commutative operators)
	// At the moment, I'm copying and pasting the implementation in both
	// but it would be better to come up with some better way to do this so that they 
	// could inherit the exact same behavior.
	
	
	// If our children are not both integers or literals (once we add variables)
	// we can still evaluate as long as our children operators are the same operator type as us
	// by performing a bit of a switcher-oo 
	// where we manipulate the children until we have something we can evaluate
	// and then move around our one of the child operators so that it becomes our parent
	// it's a bit tricky to make sure that the structure of the expression remains the same
	// so while mathematically
	// 3 + 5 + 4 + 7
	// is exactly the same as
	// 5 + 7 + 4 + 3
	// if we want to evalute the first (+) operator in 
	// 3 + 5 + 4 + 7
	// it should return an integer value that eqals (3 + 5) or 8
	// and it should also leave the expression tree so that it will flatten into this:
	// 8 + 5 + 4 + 7
	// after the evaluation is complete
	
	// STEPS:
	// 1.  get a new left child (it will either be our current right child or the *right* most leaf node of our left child
	// 2.  get a new right child (it will either be our current right child or the *left* most leaf node of our right child
	// 3.  get the operator (one of our children) that we will be replaced with (try to use the right child)
	// 4.  replace our own children with the new left and right child
	// 5.  replace one of the new operator's children with *ourself*
	// 6.  tell our old parent to replace us with the new operator
	// 7.  return self.evaluate (operate on our children as we would have if both our children had been integers in the first place)
	
	
	// What we're looking for:
	// both or one of our children are operator expressions
	// the operator(s) are the same as us
	// if only one is an multiplicaion operator, the other 
	
	// actually, this check needs to be recursive because there might be an other operator further down in the tree that should prevent the evaluation
	// example 4 * 19 / 20 * 25
	// trying to operate on the first multiplication operator will get through this test:
	
	if(		[aLeftChild isLiteral] 
	   &&	[aRightChild isLiteral])
		return [self evaluateForExpressions:[NSArray arrayWithObjects:aLeftChild, aRightChild, nil]];
	
	if(		[aLeftChild isKindOfClass:[BAMultiplicationOperator class]]
	   ||	[aRightChild isKindOfClass:[BAMultiplicationOperator class]])
	{	
		
		// one or both of our children is(are) multiplicaiton operators
		// we need to check
		// if the other operator is not a multiplicaiton operator, make sure it is not any other kind of operator
		if(		(	[aLeftChild isKindOfClass:[BAOperator class]]
				&&	[aLeftChild isKindOfClass:[BAMultiplicationOperator class]] == NO)
			||	(	[aRightChild isKindOfClass:[BAOperator class]]
				 && [aRightChild isKindOfClass:[BAMultiplicationOperator class]] == NO))
			return [self evaluateForExpressions:[NSArray arrayWithObjects:aLeftChild, aRightChild, nil]];
		
		BAExpression * aNewLeftChild = nil;
		BAExpression * aNewRightChild = nil;
		BAExpression * aChildOp = nil;
		NSInteger aChildOpInsertIndex = NSNotFound;
		
		// find the left child for the operation
		if([aLeftChild isLiteral]) {
			aNewLeftChild = aLeftChild;
        }
		else
		{
			NSArray * aLeftLeafs = [aLeftChild leafNodes];
			if([aLeftLeafs count] >= 2)
				aNewLeftChild = [aLeftLeafs lastObject];
			else
				[NSException raise:@"BAMultiplicationOperator" format:@"evaluate - one or less leaf nodes, expected two or more"];
			
			
			if([(BAOperator*)[aNewLeftChild parent] isInPrecedenceGroupWith:self] == NO)
				return nil;
			
			aChildOp = [[aLeftChild retain] autorelease];
			aChildOpInsertIndex = 1;
		}	
		
		// find the left child for the operation
		if([aRightChild isLiteral]) {
			aNewRightChild = aRightChild;
        }
		else
		{
			NSArray * aRightLeafs = [aRightChild leafNodes];
			if([aRightLeafs count] >= 2)
				aNewRightChild = [aRightLeafs objectAtIndex:0];
			else
				[NSException raise:@"BAMultiplicationOperator" format:@"evaluate - one or less leaf nodes, expected two or more"];
			
			if([(BAOperator*)[aNewRightChild parent] isInPrecedenceGroupWith:self] == NO)
				return nil;
			
			// we favor the right child to replace us
			aChildOp = [[aRightChild retain] autorelease];
			aChildOpInsertIndex = 0;
		}
		
		
		// get a reference to our parent, this is about to change, but we want to be able
		// to message it at the end
		id anOldParent = [self parent];
		NSMutableArray * aNewChildren = [NSMutableArray arrayWithObjects:aNewLeftChild, aNewRightChild,nil];
		[self setChildren:aNewChildren];
		NSMutableArray * aChildOpChildren = [[[aChildOp children] mutableCopy] autorelease];
		[aChildOpChildren replaceObjectAtIndex:aChildOpInsertIndex withObject:self];	
		
		// we must call 'replaceChild:withChild:' first so that this object's parent becomes nil
		// followed by 'setChildren', so that this object will then have 'aChildOp' as its new parent
		[anOldParent replaceChild:self withChild:aChildOp];		
		[aChildOp setChildren:aChildOpChildren];
		
		aLeftChild = aNewLeftChild;
		aRightChild = aNewRightChild;
	}
	
	return [self evaluateForExpressions:[NSArray arrayWithObjects:aLeftChild, aRightChild, nil]];
}

- (BAInteger*)leftIntegerExpressionForEvaluation
{
	if([[self children] count] == 2)
	{
		id aChild = [[self children] objectAtIndex:0];
		if([aChild isLiteral])
			return aChild;
		else
		{
			// use the *right*-most leaf node
			NSArray * aLeftLeafs = [aChild leafNodes];
			if([aLeftLeafs count] > 0)
				return [aLeftLeafs lastObject];			
		}
	}
	return nil;
}

- (BAInteger*)rightIntegerExpressionForEvaluation
{
	if([[self children] count] == 2)
	{
		id aChild = [[self children] objectAtIndex:1];
		if([aChild isLiteral])
			return aChild;
		else
		{
			// use the *left* most leaf-node
			NSArray * aRightLeafs = [aChild leafNodes];
			if([aRightLeafs count] > 0 )
				return [aRightLeafs objectAtIndex:0];	
			return nil;		
		}
	}
	return nil;
}

- (NSString*)stringValue
{
	return @"×";
}

- (NSString*)expressionString
{
//	if([self childBalance] != 0)
//		NSLog(@"expression is not well formed, child balance is: %d", [self childBalance]);
	
	if([[self children] count] > 0)
	{
		NSMutableString * aStringToReturn = [NSMutableString stringWithString:@""];
		NSInteger aChildCount = [[self children] count];
		for(NSInteger i = 0; i < aChildCount; i++)
		{
			BAExpression * aChild = [[self children] objectAtIndex:i];
			if(i != aChildCount-1)
				[aStringToReturn appendString:[NSString stringWithFormat:@"%@ × ", [aChild expressionString]]];
			else
				[aStringToReturn appendString:[NSString stringWithFormat:@"%@", [aChild expressionString]]];
		}
		return [[aStringToReturn copy] autorelease];
	}
	else
		return @"×";
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    NSMutableString *s=[NSMutableString stringWithFormat:@"%@<apply>\n", padding];
    
    [s appendFormat:@"%@ <times />\n", padding];
    
    for(NSInteger i = 0; i < [[self children] count]; i++)
    {
        BAExpression * aChild = [[self children] objectAtIndex:i];
        [s appendString:[aChild xmlStringValueWithPad:[NSString stringWithFormat:@"%@ ", padding]]];
    }
    
    [s appendFormat:@"%@</apply>\n", padding];
    
    return s;
}

- (BOOL)canAddOperatorsForExtraChildren
{
	return YES;
}

- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
    @throw [NSException exceptionWithName:@"equality not implemented in BAMultiplicationOperator" reason:@"equality not implemented in BAMultiplicationOperator" userInfo:nil];
    
//	if([theOtherExpression isKindOfClass:[BAMultiplicationOperator class]] == NO)
//		return NO;
//	
//	// do we just compare the operator itself or do we compare the whole operation (including the childrne?)
//	
//	// for now, i consider it a match if it is the same operator, the children must be compared on their own
//	return YES;
}



@end
