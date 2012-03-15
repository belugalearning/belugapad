//
//  BAOperatorSortDescriptor.m
//  Beluga
//
//  Created by Cathy Shive on 12/20/10.
//  Copyright 2010 Heritage World Press. All rights reserved.
//

#import "BAOperatorSortDescriptor.h"
#import "BAOperator.h"
#import "BADivisionOperator.h"
#import "BAMultiplicationOperator.h"
#import "BAAdditionOperator.h"
#import "BABracketOperator.h"
#import "BAPowerOperator.h"

@implementation BAOperatorSortDescriptor
- (NSComparisonResult)compareObject:(BAOperator*)theObject1 toObject:(BAOperator*)theObject2
{
	// this is based on 'order of operations rules' that we define
	// division, multiplication, addition, subtraction
	NSInteger aPriority1 = [self priorityIntForOperator:theObject1];
	NSInteger aPriority2 = [self priorityIntForOperator:theObject2];
	if(		aPriority1 == NSNotFound
	   ||	aPriority2 == NSNotFound)
	{
		// this is a programming error
		[NSException raise:@"BAOperatorSortDescriptor Exception" format:@"Sorting unknown operators"];
	}	
		
	if(aPriority1<aPriority2)
		return NSOrderedDescending;
	else if(aPriority1>aPriority2)
		return NSOrderedAscending;
	else
		return NSOrderedSame;
}

- (NSInteger)priorityIntForOperator:(BAOperator*)theOperator
{
	if([theOperator isKindOfClass:[BABracketOperator class]])
		return 1;
	else if([theOperator isKindOfClass:[BAPowerOperator class]])
		return 1;
	else if([theOperator isKindOfClass:[BADivisionOperator class]])
		return 2;
	else if([theOperator isKindOfClass:[BAMultiplicationOperator class]])
		return 3;
	else if([theOperator isKindOfClass:[BAAdditionOperator class]])
		return 4;
	else
		return NSNotFound;
}

- (id)copyWithZone:(NSZone*)zone
{
	return [[BAOperatorSortDescriptor alloc] initWithKey:[self key] ascending:[self ascending] selector:[self selector]];
}

@end
