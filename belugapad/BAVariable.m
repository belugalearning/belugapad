//
//  BAVariable.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAVariable.h"
@interface BAVariable ()
@end


@implementation BAVariable
@synthesize name = mName;
@synthesize multiplierIntValue = mMultiplierIntValue;

+(BAVariable*)variableWithName:(NSString*)theName
{
	return [BAVariable variableWithName:theName multiplierIntValue:1];
}

// deprecated, use `variableWithName:` instead
+(BAVariable*)variableWithName:(NSString*)theName multiplierIntValue:(NSInteger)theMultiplierInt
{
	BAVariable * aVariable = [[[BAVariable alloc] init] autorelease];
	[aVariable setName:theName];
	[aVariable setMultiplierIntValue:theMultiplierInt];
	return aVariable;
}

- (id)init
{
	if(self = [super init])
	{
		// default is one
		mMultiplierIntValue = 1;
	}
	return self;
}


-(id)copyWithZone:(NSZone *)theZone
{
	BAVariable* aCopy = (BAVariable*)[super copyWithZone:theZone];
	
	aCopy->mMultiplierIntValue = 1;
	aCopy->mName = nil;
	
	[aCopy setMultiplierIntValue:[self multiplierIntValue]];
	[aCopy setName:[self name]];
	
	return aCopy;
}


- (void)dealloc
{
	[mName release];
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
	return nil;
}

- (BAExpression*)recursiveEvaluate
{
	return [BAVariable variableWithName:[self name] multiplierIntValue:[self multiplierIntValue]];
}

- (NSString*)stringValue
{
	NSString * aMultiplierString = nil;
	if([self multiplierIntValue] == -1)
		aMultiplierString = @"-";
	else if([self multiplierIntValue] == 1)
		aMultiplierString = @"";
	else
		aMultiplierString = [NSString stringWithFormat:@"%d", [self multiplierIntValue]];
	return [NSString stringWithFormat:@"%@%@", aMultiplierString, [self name]];
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    return [NSString stringWithFormat:@"%@<ci>%@</ci>\n", padding, [self stringValue]];
}

- (NSString*)expressionString
{
	return [self stringValue];
}

- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
	if([theOtherExpression isKindOfClass:[BAVariable class]] == NO)
		return NO;
	if (	[self multiplierIntValue] == [(BAVariable*)theOtherExpression multiplierIntValue]
			&&	[[self name] isEqualToString:[(BAVariable*)theOtherExpression name]])
		return YES;
	return NO;
}

@end
