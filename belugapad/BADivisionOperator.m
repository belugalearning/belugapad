//
//  BADivisionOperator.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BADivisionOperator.h"
#import "BAPowerOperator.h"

@implementation BADivisionOperator
- (BAOperatorType)operatorType
{
	return BAOperatorType_Binary;
}

- (BOOL)isCommutative
{
	return NO;
}


- (BAExpression*)evaluateForExpressions:(NSArray*)theChildren
{
	if([theChildren count] != 2)
		[NSException raise:@"BADivisionOperator" format:@"evaluateForExpressions: - children array must have 2 objects"];
	
	BAExpression * aLeftChild = [theChildren objectAtIndex:0];
	BAExpression * aRightChild = [theChildren objectAtIndex:1];
	
	if(		[aLeftChild isKindOfClass:[BAInteger class]]
	   &&	[aRightChild isKindOfClass:[BAInteger class]]
	   &&	[(BAInteger*)aRightChild intValue] != 0)
	{
		// we can only return an integer if the numerator divides evenly into the denominator
		if([(BAInteger*)aLeftChild intValue] % [(BAInteger*)aRightChild intValue] == 0)
		{	
			if(		(	[(BAInteger*)aLeftChild symbolString] != nil
					 &&	[(BAInteger*)aRightChild symbolString] != nil)
			   &&	[[(BAInteger*)aLeftChild symbolString] isEqualToString:[(BAInteger*)aRightChild symbolString]])
			{
				// if both ints have the same symbol string, we'll make a new int with the same symbol string
				NSString * aSymbolString = [(BAInteger*)aLeftChild symbolString];
				BAInteger * anInteger = [BAInteger integerWithIntValue:[(BAInteger*)aLeftChild intValue]/[(BAInteger*)aRightChild intValue]];
				[anInteger setSymbolString:aSymbolString];
				return anInteger;
			}
			return [BAInteger integerWithIntValue:[(BAInteger*)aLeftChild intValue]/[(BAInteger*)aRightChild intValue]];
		}
		else
		{
			// return a new division operator with the left and right child
			// if the children are the same as our children, return self
			// otherwise make a new operator
			if(		[theChildren objectAtIndex:0] == [[self children] objectAtIndex:0]
			   &&	[theChildren objectAtIndex:1] == [[self children] objectAtIndex:1])
				return self;
			
			BADivisionOperator * anOpToReturn = [[[BADivisionOperator alloc] init] autorelease];
			[anOpToReturn setChildren:(NSMutableArray*)theChildren];
			return anOpToReturn;
		}
	}
	if(		[aLeftChild isKindOfClass:[BAVariable class]]
	   &&	[aRightChild isKindOfClass:[BAVariable class]])
	{
		// dividing two variables, if they are like variables
		if([[(BAVariable*)aRightChild name] isEqualToString:[(BAVariable*)aLeftChild name]])
		{
			// the variable from each side cancel each other out (they equal 1 when divided)
			
			// get the multipliers, if they divide evenly, we can return an integer
			// otherwise we have to return another division expression (fraction)
			NSInteger aLeftMultiplier = [(BAVariable*)aLeftChild multiplierIntValue];
			NSInteger aRightMultiplier = [(BAVariable*)aRightChild multiplierIntValue];
			if(aLeftMultiplier % aRightMultiplier == 0)
			{
				return [BAInteger integerWithIntValue:aLeftMultiplier/aRightMultiplier];
			}
			else
			{
				BADivisionOperator * aDivisionOperator = [[[BADivisionOperator alloc] init] autorelease];
				[aDivisionOperator setChildren:[NSArray arrayWithObjects:[BAInteger integerWithIntValue:aLeftMultiplier], [BAInteger integerWithIntValue:aRightMultiplier], nil]];
				return aDivisionOperator;
			}
		}
		return nil;
	}

	if(		[aLeftChild isKindOfClass:[BAPowerOperator class]]
	   &&	[aRightChild isKindOfClass:[BAPowerOperator class]])
	{
		// dividing exponents if the bases are like variables
		BAExpression * aRightBase = [[aRightChild children] objectAtIndex:0];
		BAExpression * aLeftBase = [[aLeftChild children] objectAtIndex:0];
	
		if(		[aRightBase isKindOfClass:[BAVariable class]]
		   &&	[aLeftBase isKindOfClass:[BAVariable class]]
		   &&	[[(BAVariable*)aRightBase name] isEqualToString:[(BAVariable*)aLeftBase name]]
		   &&	[(BAVariable*)aRightBase multiplierIntValue] != 0)
		{
			
			// if the multipiers don't divide evenly
			// we can't do this division, we'll just return 
			// a division operator with the power ops as children
			NSInteger aLeftMultiplier = [(BAVariable*)aLeftBase multiplierIntValue];
			NSInteger aRightMultiplier = [(BAVariable*)aRightBase multiplierIntValue];
			if(aLeftMultiplier % aRightMultiplier == 0)
			{
				BAExpression * aRightExponent = [[aRightChild children] objectAtIndex:1];
				BAExpression * aLeftExponent = [[aLeftChild children] objectAtIndex:1];
				
				// divide the bases
				NSInteger aNewBaseMultiplier = aLeftMultiplier/aRightMultiplier;
				
				// subtract the exponents
				NSInteger aNewExponentInt = [(BAInteger*)aLeftExponent intValue] - [(BAInteger*)aRightExponent intValue];
				if(aNewExponentInt == 0)
				{
					// if the exponents subtract to zero, the variable should be replaced by an integer with the value of 1
					BAInteger * aValueToReturn = [BAInteger integerWithIntValue:aNewBaseMultiplier];
					return aValueToReturn;
				}
				else if(aNewExponentInt == 1)
				{
					// if the exponents subtract to one, return just the variable
					BAVariable * aValueToReturn = [BAVariable variableWithName:[(BAVariable*)aRightBase name] multiplierIntValue:1];
					return aValueToReturn;
				}
				else
				{				
					BAVariable * aNewVariable = [BAVariable variableWithName:[(BAVariable*)aRightBase name] multiplierIntValue:aNewBaseMultiplier];
					BAInteger * aNewExponent = [BAInteger integerWithIntValue:aNewExponentInt];
					BAPowerOperator * aNewPowerOperator = [[[BAPowerOperator alloc] init] autorelease];
					[aNewPowerOperator setChildren:[NSMutableArray arrayWithObjects:aNewVariable, aNewExponent, nil]];
					return aNewPowerOperator;
				}
			}
			else
			{
				// if the children are the same as our children, return self
				// otherwise make a new operator
				if(		[theChildren objectAtIndex:0] == [[self children] objectAtIndex:0]
				   &&	[theChildren objectAtIndex:1] == [[self children] objectAtIndex:1])
					return self;
				
				BADivisionOperator * anOpToReturn = [[[BADivisionOperator alloc] init] autorelease];
				[anOpToReturn setChildren:(NSMutableArray*)theChildren];
				return anOpToReturn;
			}
		}
	}
	return nil;
}

- (BAExpression*)evaluate
{
	return [self evaluateForExpressions:[self children]];
}

- (NSString*)stringValue
{
	return @"÷";
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    NSMutableString *s=[NSMutableString stringWithFormat:@"%@<apply>\n", padding];
    
    [s appendFormat:@"%@ <divide />\n"];
    
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
//	if([self childBalance] != 0)
//		NSLog(@"expression is not well formed, child balance is: %d", [self childBalance]);

	
	if([[self children] count] > 0)
	{
		NSString * aLeftString = [[[self children] objectAtIndex:0] expressionString];
		NSString * aRightString = [[[self children] objectAtIndex:1] expressionString];
		return [NSString stringWithFormat:@"%@ ÷ %@", aLeftString, aRightString];
	}
	else
		return @"÷";
}

- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
	if([theOtherExpression isKindOfClass:[BADivisionOperator class]] == NO)
		return NO;
	
	// do we just compare the operator itself or do we compare the whole operation (including the childrne?)
	
	// for now, i consider it a match if it is the same operator, the children must be compared on their own
	return YES;
}

@end
