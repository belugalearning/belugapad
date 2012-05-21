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
        if([(BAInteger*)aLeftChild intValue]==0)
        {
            return [BAInteger integerWithIntValue:0];
        }
		// we can only return an integer if the numerator divides evenly into the denominator
		else if([(BAInteger*)aLeftChild intValue] % [(BAInteger*)aRightChild intValue] == 0)
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

- (void)simplifyIntegerDivision
{
    if(self.children.count!=2)
    {
        @throw [NSException exceptionWithName:@"cannot simplify" reason:@"cannot simplify without precisely two children" userInfo:nil];
    }
    if(![[self.children objectAtIndex:0] isKindOfClass:[BAInteger class]] ||
       ![[self.children objectAtIndex:1] isKindOfClass:[BAInteger class]])
    {
        @throw [NSException exceptionWithName:@"cannot simplify" reason:@"cannot simplify if children are not BAIntegers" userInfo:nil];
    }
    
    //will get top and bottom as integers, simplify and then recreate if necessary
    BAInteger *top=[self.children objectAtIndex:0];
    BAInteger *bottom=[self.children objectAtIndex:1];
    int origtop=[top intValue];
    int origbottom=[bottom intValue];
    int a=origtop;
    int b=origbottom;
    
    //get GCD
    while (b!=0) {
        int t=b;
        b = a % b;
        a=t;
    }
    int gcd=a;

    if(gcd>1)
    {
        [self removeChild:top];
        [self removeChild:bottom];
        
        [self addChild:[BAInteger integerWithIntValue:origtop / gcd]];
        [self addChild:[BAInteger integerWithIntValue:origbottom / gcd]];
    }
}

- (NSString*)stringValue
{
	return @"÷";
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    NSMutableString *s=[NSMutableString stringWithFormat:@"%@<apply>\n", padding];
    
    [s appendFormat:@"%@ <divide />\n", padding];
    
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
    if([self children].count != 2 || [self children].count != 2)
    {
        @throw [NSException exceptionWithName:@"not supported" reason:@"equal on supported with 2 children per side" userInfo:nil];
        return NO;
    }
    
    
    //compare divisions with 2 integer children on both sides
    if([[[self children] objectAtIndex:0] isKindOfClass:[BAInteger class]] &&
       [[[self children] objectAtIndex:1] isKindOfClass:[BAInteger class]] &&
       [[[theOtherExpression children] objectAtIndex:0] isKindOfClass:[BAInteger class]] &&
       [[[theOtherExpression children] objectAtIndex:1] isKindOfClass:[BAInteger class]])
    {
        //return yes if top of self and top of comparison are equal, and bottom of self and bottom of compare are equal
        BAInteger *ltop=(BAInteger*)[[self children] objectAtIndex:0];
        BAInteger *lbottom=(BAInteger*)[[self children] objectAtIndex:1];
        BAInteger *rtop=(BAInteger*)[[theOtherExpression children] objectAtIndex:0];
        BAInteger *rbottom=(BAInteger*)[[theOtherExpression children] objectAtIndex:1];
        
        if([ltop isEqualToExpression:rtop] && [lbottom isEqualToExpression:rbottom])
        {
            return YES;
        }
        else {
            //this is a no based on the terms provided -- not 
            return NO;
        }
    }
    else if(![theOtherExpression isKindOfClass:[BADivisionOperator class]])
    {
        //can't compare to anything but a division currently
        return NO;
    }
    else {
        @throw [NSException exceptionWithName:@"equality not implemented in BADivisionOperator" reason:@"not implemented" userInfo:nil];
    }
    
    return NO;
}

@end
