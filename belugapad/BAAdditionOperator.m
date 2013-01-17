//
//  BAAdditionOperator.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAAdditionOperator.h"
#import "BAPowerOperator.h"

@implementation BAAdditionOperator
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
		[NSException raise:@"BAAditionOperator" format:@"evaluateForExpressions: - children array must have 2 objects"];
	
	BAExpression * aLeftChild = [theChildren objectAtIndex:0];
	BAExpression * aRightChild = [theChildren objectAtIndex:1];
	
	// adding an integer with an integer
	if(		[aLeftChild isKindOfClass:[BAInteger class]]
	   &&	[aRightChild isKindOfClass:[BAInteger class]])
	{
		if(		(	[(BAInteger*)aLeftChild symbolString] != nil
			   &&	[(BAInteger*)aRightChild symbolString] != nil)
		   &&	[[(BAInteger*)aLeftChild symbolString] isEqualToString:[(BAInteger*)aRightChild symbolString]])
		{
			// if both ints have the same symbol string, we'll make a new int with the same symbol string
			NSString * aSymbolString = [(BAInteger*)aLeftChild symbolString];
			BAInteger * anInteger = [BAInteger integerWithIntValue:[(BAInteger*)aLeftChild intValue]+[(BAInteger*)aRightChild intValue]];
			[anInteger setSymbolString:aSymbolString];
			return anInteger;
		}
		
		// otherwise, just get rid of the symbols string, create a plain integer		
		return [BAInteger integerWithIntValue:[(BAInteger*)aLeftChild intValue]+[(BAInteger*)aRightChild intValue]];
		
	}	
	// adding a 0 and anything
	if(		[aLeftChild isKindOfClass:[BAInteger class]]
	   &&	[(BAInteger*)aLeftChild intValue] == 0)
	{
		return [[aRightChild copy] autorelease];
	}
	else if(	[aRightChild isKindOfClass:[BAInteger class]]
			&&	[(BAInteger*)aRightChild intValue] == 0)
	{
		return [[aLeftChild copy] autorelease];
	}
	
	// adding 2 like variables
	else if(	[aLeftChild isKindOfClass:[BAVariable class]]
			&&	[aRightChild isKindOfClass:[BAVariable class]]
			&& [[(BAVariable*)aLeftChild name] isEqualToString:[(BAVariable*)aRightChild name]])
	{
		// just add the multilier values
		NSInteger aMultiplier = [(BAVariable*)aLeftChild multiplierIntValue]+[(BAVariable*)aRightChild multiplierIntValue];
		if(aMultiplier!= 0)
			return [BAVariable variableWithName:[(BAVariable*)aLeftChild name] multiplierIntValue:aMultiplier];
		else 
			return [BAInteger integerWithIntValue:0];
	}
	// adding 2 like variables with power operators with like exponents
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
			
			// the variables must be the same name and the exponent values must be the same
			if([[(BAVariable*)aRightChildVariable name] isEqualToString:[(BAVariable*)aLeftChildVariable name]]
			   && [(BAInteger*)aRightChildExponent intValue] == [(BAInteger*)aLeftChildExponent intValue])
			{
				NSInteger anExponentValue = [(BAInteger*)aLeftChildExponent intValue];
				NSInteger aMultiplierValue = [(BAVariable*)aLeftChildVariable multiplierIntValue] + [(BAVariable*)aRightChildVariable multiplierIntValue];
				BAVariable * aNewVariable = [BAVariable variableWithName:[(BAVariable*)aRightChildVariable name] multiplierIntValue:aMultiplierValue];
				BAInteger * aNewExponent = [BAInteger integerWithIntValue:anExponentValue];
				BAPowerOperator * aNewPowerOperator = [[[BAPowerOperator alloc] init] autorelease];
				[aNewPowerOperator setChildren:[NSArray arrayWithObjects:aNewVariable, aNewExponent, nil]];
				return aNewPowerOperator;
			}
		}
	}
	return nil;
}

- (BAExpression*)evaluate
{	
    // TODO: refactor with the same code in the multiplication operator
    
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
	// where we manipulate our children until we have something we can evaluate
	// and then move around our one of our child operators so that it becomes our parent
	// it's a bit tricky to make sure that the structure of the expression remains the same
	// so while technically
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
	
	if(		[aLeftChild isLiteral] 
	   &&	[aRightChild isLiteral])
		return [self evaluateForExpressions:[NSArray arrayWithObjects:aLeftChild, aRightChild, nil]];
	
	if(		[aLeftChild isKindOfClass:[BAAdditionOperator class]]
	   ||	[aRightChild isKindOfClass:[BAAdditionOperator class]])
	{	
		
		// one or both of our children is(are) multiplicaiton operators
		// we need to check
		// if the other operator is not a multiplicaiton operator, make sure it is not any other kind of operator
		if(		(	[aLeftChild isKindOfClass:[BAOperator class]]
				 &&	[aLeftChild isKindOfClass:[BAAdditionOperator class]] == NO)
		   ||	(	[aRightChild isKindOfClass:[BAOperator class]]
				 && [aRightChild isKindOfClass:[BAAdditionOperator class]] == NO))
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
			if([aLeftLeafs count] == 2)
				return [aLeftLeafs objectAtIndex:1];			
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
			if([aRightLeafs count] == 2)
				return [aRightLeafs objectAtIndex:0];	
			return nil;		
		}
	}
	return nil;
}

- (NSString*)stringValue
{
	return @"+";
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    NSMutableString *s=[NSMutableString stringWithFormat:@"%@<apply>\n", padding];
    
    [s appendFormat:@"%@ <plus />\n", padding];
    
    
    for(NSInteger i = 0; i < [[self children] count]; i++)
    {
        BAExpression * aChild = [[self children] objectAtIndex:i];
        [s appendString:[aChild xmlStringValueWithPad:[NSString stringWithFormat:@"%@ ", padding]]];
    }
    
    [s appendFormat:@"%@</apply>\n", padding];
    
    return s;
}

- (NSString*)expressionString
{
	if([[self children] count] > 0)
	{		
		NSMutableString * aStringToReturn = [NSMutableString stringWithString:@""];
		NSInteger aChildCount = [[self children] count];
		for(NSInteger i = 0; i < aChildCount; i++)
		{
			BAExpression * aChild = [[self children] objectAtIndex:i];
			if(i != aChildCount-1)
				[aStringToReturn appendString:[NSString stringWithFormat:@"%@ + ", [aChild expressionString]]];
			else
				[aStringToReturn appendString:[NSString stringWithFormat:@"%@", [aChild expressionString]]];
		}
		return [[aStringToReturn copy] autorelease];
	}
	else
		return @"+";
}

- (BOOL)canAddOperatorsForExtraChildren
{
	return YES;
}


- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
     @throw [NSException exceptionWithName:@"equality not implemented in BAAdditionOperator" reason:@"equality not implemented in BAAdditionOperator" userInfo:nil];
    
//	if([theOtherExpression isKindOfClass:[BAAdditionOperator class]] == NO)
//		return NO;
//	
//	// do we just compare the operator itself or do we compare the whole operation (including the childrne?)
//	
//	// for now, i consider it a match if it is the same operator, the children must be compared on their own
//	return YES;
}


@end
