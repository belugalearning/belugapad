//
//  BABracketOperator.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BABracketOperator.h"


@implementation BABracketOperator
- (BAOperatorType)operatorType
{
	return BAOperatorType_Unary;
}

- (BOOL)isCommutative
{
	return NO;
}


- (BAExpression*)recursiveEvaluate
{
	// the bracket operator will just be skipped, it'll pass on the message to its child
	if([self childBalance] == 0)
		return [[[self children] objectAtIndex:0] recursiveEvaluate];
	
	return nil;
}

- (BOOL)canEvaluate
{
	return NO;
}

- (NSString*)stringValue
{
	return @"()";
}


- (NSString*)expressionString
{
//	if([self childBalance] != 0)
//		NSLog(@"expression is not well formed, child balance is: %d", [self childBalance]);

	if([[self children] count] > 0)
	{
		NSString * aSubexpression = [[[self children] objectAtIndex:0] expressionString];
		return [NSString stringWithFormat:@"(%@)", aSubexpression];
	}
	else
		return @"()";
}

- (BOOL)canBeReplacedByChild
{
	if([super canBeReplacedByChild])
		return YES;
	
	// check if we have one child and it's a literal expression return yes
	if(		[[self children] count] == 1
	   &&	[(BAExpression*)[[self children] objectAtIndex:0] isLiteral])
		return YES;
	
	return NO;
}

- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
    @throw [NSException exceptionWithName:@"equality not implemented in BABracketOperator" reason:@"equality not implemented in BABracketOperator" userInfo:nil];
    
//	if([theOtherExpression isKindOfClass:[BABracketOperator class]] == NO)
//		return NO;
//	
//	// do we just compare the operator itself or do we compare the whole operation (including the childrne?)
//	
//	// I don't know what the right behavior is for bracket operators in this case.
//	// for now, i'll just return yes, but i have a hunch that we'll want to check their inner expressions...
//	return YES;
}

@end
