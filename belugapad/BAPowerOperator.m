//
//  BAPowerOperator.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAPowerOperator.h"


@implementation BAPowerOperator
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
		[NSException raise:@"BAPowerOperator" format:@"evaluateForExpressions: - children array must have 2 objects"];
	
	BAExpression * aLeftChild = [theChildren objectAtIndex:0];
	BAExpression * aRightChild = [theChildren objectAtIndex:1];
    
    if (    [[aLeftChild cloneEvaluate] isEqualToExpression:[BAInteger integerWithIntValue:0]]
        &&  [[aRightChild cloneEvaluate] isEqualToExpression:[BAInteger integerWithIntValue:0]]) {
        // zero to the power of zero is undefined
        return nil;
    }
	
	if(		[aRightChild isKindOfClass:[BAInteger class]]
	   &&	[(BAInteger*)aRightChild intValue] == 0) {
		return [BAInteger integerWithIntValue:1];
	}
    
	if(		[aLeftChild isKindOfClass:[BAInteger class]]
	   &&	[aRightChild isKindOfClass:[BAInteger class]]) {
		return [BAInteger integerWithIntValue:(NSInteger)pow((double)[(BAInteger*)aLeftChild intValue], (double)[(BAInteger*)aRightChild intValue])];
	}
    
	if(		[aLeftChild isKindOfClass:[BAVariable class]]
	   &&	[aRightChild isKindOfClass:[BAInteger class]]) {
		return self;
	}
    
	return nil;
}


- (BAExpression*)evaluate
{
	if([self childBalance] != 0)
		[NSException raise:@"BAPowerOperator" format:@"evaluate - invalid number of children"];
	
	return [self evaluateForExpressions:[self children]];
}


- (NSString*)stringValue
{
	return @"^";
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    NSMutableString *s=[NSMutableString stringWithFormat:@"%@<apply>\n", padding];
    
    [s appendFormat:@"%@ <power />\n", padding];
    
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
	if([self childBalance] != 0)
		NSLog(@"expression is not well formed, child balance is: %d", [self childBalance]);
	
	if([[self children] count] > 0)
	{
		NSString * aLeftString = [[[self children] objectAtIndex:0] expressionString];
		NSString * aRightString = [[[self children] objectAtIndex:1] expressionString];
		//NSLog(@"\u2070 \u00B9 \u00B2 \u00B3 \u2074 \u2075 \u2076 \u2077 \u2078 \u2079");
		
		BAExpression * aRightExpression = [[self children] objectAtIndex:1];
		if([aRightExpression isKindOfClass:[BAInteger class]])
		{
			switch([(BAInteger*)aRightExpression intValue])
			{
				// I should move this somewhere else so that other code can use it...
				case 0:
					aRightString = @"\u2070";
					break;
				case 1:
					aRightString = @"\u00B9";
					break;
				case 2:
					aRightString = @"\u00B2";
					break;
				case 3:
					aRightString = @"\u00B3";
					break;
				case 4:
					aRightString = @"\u2074";
					break;
				case 5:
					aRightString = @"\u2075";
					break;
				case 6:
					aRightString = @"\u2076";
					break;
				case 7:
					aRightString = @"\u2077";
					break;
				case 8:
					aRightString = @"\u2078";
					break;
				case 9:
					aRightString = @"\u2079";
					break;
				case -1:
					aRightString = @"\u207B\u00B9";
					break;
				case -2:
					aRightString = @"\u207B\u00B2";
					break;
				case -3:
					aRightString = @"\u207B\u00B3";
					break;
				case -4:
					aRightString = @"\u207B\u2074";
					break;
				case -5:
					aRightString = @"\u207B\u2075";
					break;
				case -6:
					aRightString = @"\u207B\u2076";
					break;
				case -7:
					aRightString = @"\u207B\u2077";
					break;
				case -8:
					aRightString = @"\u207B\u2078";
					break;
				case -9:
					aRightString = @"\u207B\u2079";
					break;
			}
		}
		
		return [NSString stringWithFormat:@"%@%@", aLeftString, aRightString];
	}
	else
		return @"^";
}

- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
    @throw [NSException exceptionWithName:@"equality not implemented in BAPowerOperator" reason:@"equality not implemented in BAPowerOperator" userInfo:nil];
    
//	if([theOtherExpression isKindOfClass:[BAPowerOperator class]] == NO)
//		return NO;
//	
//	// do we just compare the operator itself or do we compare the whole operation (including the childrne?)
//	
//	// for power operators, we'll compare the base and exponent values
//	if(		[[[theOtherExpression children] objectAtIndex:0] isEqualToExpression:[[self children] objectAtIndex:0]]
//	   &&	[[[theOtherExpression children] objectAtIndex:1] isEqualToExpression:[[self children] objectAtIndex:1]])
//		return YES;
//	return NO;
}

@end
