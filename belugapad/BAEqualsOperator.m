//
//  BAEqualsOperator.m
//  Beluga
//
//  Created by Cathy Shive on 2/7/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAEqualsOperator.h"


@implementation BAEqualsOperator
- (BAOperatorType)operatorType
{
	return BAOperatorType_Binary;
}

- (BOOL)isCommutative
{
	return NO;
}

- (NSString*)stringValue
{
	return @"=";
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    NSMutableString *s=[NSMutableString stringWithFormat:@"%@<apply>\n", padding];
    
    //[s appendFormat:@"%@ <eq />\n"];
    [s appendFormat:@"%@ <eq />\n", padding];
    
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
		return [NSString stringWithFormat:@"%@ = %@", aLeftString, aRightString];
	}
	else
		return @"=";
}


- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
    @throw [NSException exceptionWithName:@"equality not implemented in BAEqualsOperator" reason:@"equality not implemented in BAEqualsOperator" userInfo:nil];
    
//	if([theOtherExpression isKindOfClass:[BAEqualsOperator class]] == NO)
//		return NO;
	
//	// do we just compare the operator itself or do we compare the whole operation (including the childrne?)
//	
//	// I don't know what the right behavior is for equals operators in this case.
//	// for now, i'll just return yes
//	return YES;
}

@end
