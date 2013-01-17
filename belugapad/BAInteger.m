//
//  BAInteger.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAInteger.h"
#import "BAMultiplicationOperator.h"

@interface BAInteger()

@property (nonatomic, readwrite, copy) NSString * symbolString; // deprecated
@property (nonatomic, readwrite, assign) BAIntegerSymbolType symbolType; // deprecated

@end

@implementation BAInteger

@synthesize intValue = mIntValue;
@synthesize symbolString = mSymbolString;
@synthesize symbolType = mSymbolType;

+(BAInteger*)integerWithIntValue:(NSInteger)theIntValue
{
	BAInteger * anInteger = [[[self alloc] init] autorelease];
	[anInteger setIntValue:theIntValue];
	return anInteger;
}

-(id)copyWithZone:(NSZone *)theZone
{
	BAInteger* aCopy = (BAInteger*)[super copyWithZone:theZone];

	aCopy->mIntValue = 0;
	aCopy->mSymbolString = nil;
	aCopy->mSymbolType = BAIntegerSymbolType_Prefix;
	
	[aCopy setIntValue:[self intValue]];
	[aCopy setSymbolString:[self symbolString]];
	[aCopy setSymbolType:[self symbolType]];
	
	return aCopy;
}

- (void)dealloc
{
	[mSymbolString release];
	[super dealloc];
}

- (BOOL)isLiteral
{
	return YES;
}

- (BOOL)canEvaluate
{
	return YES;
}

- (BAExpression*)evaluate
{
	return self;//[BAInteger integerWithIntValue:[self intValue]];
}

- (BAExpression*)recursiveEvaluate
{
	return [BAInteger integerWithIntValue:[self intValue]];
}

- (NSArray*)_trialDivision
{
	//http://en.wikipedia.org/wiki/Integer_factorization
	//http://en.wikipedia.org/wiki/Trial_division	
	//http://en.literateprograms.org/Trial_division_(C)
	// I'm doing a bit of a bastardization of the "trial division" algorithm
	
	NSMutableArray * anArrayToReturn = [[[NSMutableArray alloc] init] autorelease];
	
	BOOL isNegative = [self intValue] < 0;
	NSInteger i = abs([self intValue]);

	for(NSInteger x = 1; x <= i; x++)
	{
		if(i % x == 0)
		{
			if(isNegative==NO)
			{	
				NSArray * anArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:x], [NSNumber numberWithInt:i/x], nil];
				[anArrayToReturn addObject:anArray];
			}
			else
			{
				// for negative numbers, there are two possible combintaitons of negative and positive 
				NSArray * anArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:0-x], [NSNumber numberWithInt:i/x], nil];
				[anArrayToReturn addObject:anArray];
				NSArray * aSecondArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:x], [NSNumber numberWithInt:0-(i/x)], nil];
				[anArrayToReturn addObject:aSecondArray];				
			}
		}
	}
	//NSLog(@"%@", anArrayToReturn);
	return anArrayToReturn;
}

- (NSArray*)_factorsAsExpressions
{
	NSArray * aFactors = [self _trialDivision];
	NSMutableArray * anExpressionsToReturn = [NSMutableArray array];
	for(NSArray * aValues in aFactors)
	{
		if([aValues count] != 2)
			[NSException raise:@"BAInteger" format:@"factorsAsExprssions - expected to find 2 children in list"];
		
		BAMultiplicationOperator * anOperator = [[[BAMultiplicationOperator alloc] init] autorelease];
		NSInteger aLeftChildIntValue = [[aValues objectAtIndex:0] intValue];
		NSInteger aRightChildIntValue = [[aValues objectAtIndex:1] intValue];
		[anOperator setChildren:[NSArray arrayWithObjects:[BAInteger integerWithIntValue:aLeftChildIntValue], [BAInteger integerWithIntValue:aRightChildIntValue], nil]];
		[anExpressionsToReturn addObject:anOperator];
	}
	return [[anExpressionsToReturn copy] autorelease];
}


- (NSArray*)factors
{	
	// returns a list of the possible factors of this integer value as multiplication expressions
	// example:
	// if [self intValue] = 36
	// the result looks like: 
    // ["1 × 36", "2 × 18", "3 × 12", "4 × 9", "6 × 6", "9 × 4", "12 × 3", "18 × 2", "36 × 1"]
	return [self _factorsAsExpressions];
}


- (NSString*)stringValue
{
	if([self symbolString] == nil)
		return [NSString stringWithFormat:@"%d", [self intValue]];
	else
		if([self symbolType] == BAIntegerSymbolType_Prefix)
			return [NSString stringWithFormat:@"%@%d", [self symbolString], [self intValue]];
		else
			return [NSString stringWithFormat:@"%d%@", [self intValue] , [self symbolString]];
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    return [NSString stringWithFormat:@"%@<cn type='integer'>%@</cn>\n", padding, [self stringValue]];
}

- (NSString*)expressionString
{
	return [self stringValue];
}

- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
	if([theOtherExpression isKindOfClass:[BAInteger class]] == NO)
		return NO;
	
	if ([self intValue] == [(BAInteger*)theOtherExpression intValue])
	{
		if(		(	([self symbolString] && [(BAInteger*)theOtherExpression symbolString])
				 &&	[[self symbolString] isEqualToString:[(BAInteger*)theOtherExpression symbolString]])
			|| 
				(	[self symbolString] == nil
				 &&	[(BAInteger*)theOtherExpression symbolString] == nil))
		{	
			if([self symbolType] == [(BAInteger*)theOtherExpression symbolType])
				return YES;
		}
	}
	return NO;
}

@end
