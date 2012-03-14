//
//  BAOperator.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAOperator.h"
#import "BAEqualsOperator.h"

@implementation BAOperator
+ (id)operator
{
	return [[[[self class] alloc] init] autorelease];
}

- (BOOL)isLiteral
{
	// subclasses should NOT override this
	return NO;
}

- (BAOperatorType)operatorType
{
	// subclasses must override
	return BAOperatorType_Unknown;
}

- (BOOL)isCommutative
{
	// subclasses can override to change the default
	return YES;
}

- (BOOL)canEvaluate
{
	if([self childBalance] != 0)
		return NO;
	
	BAExpression * aResult = [self cloneEvaluate];
	
	if(aResult==nil)
		return NO;
	
//	if([aResult recursiveIsEqual:self])
//		return NO;
	
	return YES;
}

- (BAExpression*)evaluate
{
	return nil; // subclasses must override
}

- (BAExpression*)recursiveEvaluate
{
	BAExpression * aResult = nil;
	if([self childBalance] == 0)
	{
		if([self operatorType] == BAOperatorType_Binary)
		{
			BAExpression * aLeftExpression = [[[self children] objectAtIndex:0] recursiveEvaluate];
			BAExpression * aRightExpression = [[[self children] objectAtIndex:1] recursiveEvaluate];
			aResult = [self evaluateForExpressions:[NSArray arrayWithObjects:aLeftExpression, aRightExpression, nil]];
		}
		else
		{
			BAExpression * aChild = [[[self children] objectAtIndex:0] recursiveEvaluate];
			aResult = [self evaluateForExpressions:[NSArray arrayWithObject:aChild]];
		}
	}
	return aResult;
}

- (BAExpression*)evaluateForExpressions:(NSArray*)theChildren
{
	return nil;// subcalsses must implement this
}


- (NSInteger)childBalance
{
	// returning 0 means that we're balanced
	// a negative number means that we have a deficit 
	// a positive number means that have a surplus 
	switch([self operatorType])
	{
		case BAOperatorType_Binary:
			return [[self children] count] - 2;
			break;
		case BAOperatorType_Unary:
			return [[self children] count] - 1;
			break;
		default:
			return 0;
	}
}


/*
 //http://hwp.lighthouseapp.com/projects/70504/tickets/53-double-cancel-on-dividing-line-freezes
 
 I've isolated the bug in this ticket to here. 
 
 The operators aren't being removed in the prune process because they are returning NO by 'canBeReplacedByChild' when they
 should return yes
 
 Instead of just looking at how many children there are, we need to figure out of there is valid input for both sides of the operation
 This is a bit more involved and can take a day or two to implement, but it's necessary, this is a serious bug
 
*/
- (BOOL)canBeReplacedByChild
{
	if(		[self operatorType] != BAOperatorType_Unary
	   &&	[[self children] count] == 1)
//	   && (		[[self parent] isKindOfClass:[BAExpression class]] == NO
//			||	[[self parent] isKindOfClass:[self class]]
//			||	[[self parent] isKindOfClass:[BAEqualsOperator class]]))
			 return YES;
	return NO;
}

- (void)addOperatorIfNeeded
{
	if([self childBalance] > 0)
	{
		// if we have too many children we
		// can possibly fix it by adding an operator
		if([self canAddOperatorsForExtraChildren])
		{
			while([self childBalance] > 0)
			{
				// take the last two children and make them children of the operator
				if([[self children] count] > 2)
				{				
					// make an operator of the same type as this one
					id anOperator = [[[[self class] alloc] init] autorelease];
					NSMutableArray * aNewChildren = [NSMutableArray array];				
					for(NSInteger i = 0; i < 2; i++)
					{
						BAExpression * aChild = [[self children] lastObject];
						[aNewChildren insertObject:aChild atIndex:0];
						[self removeChild:aChild];
					}
					[anOperator setChildren:aNewChildren];
					[self addChild:anOperator];
				}
			}
		}
	}
	
	for(BAExpression * aChild in [self children])
		[aChild addOperatorIfNeeded];
}

- (void)removeRedundantOperatorIfNeeded
{
	if([self canBeReplacedByChild])
	{
		[[self parent] replaceChildWithOnlyChild:self];
		// technically, at this point, we should have been released by our parent
	}

	NSMutableArray * aChildren = [[[self children] copy] autorelease];
	for(BAExpression * aChild in aChildren)
		[aChild removeRedundantOperatorIfNeeded];
}

- (BAInteger*)leftIntegerExpressionForEvaluation
{
	if([[self children] count] == 2)
	{
		id aChild = [[self children] objectAtIndex:0];
		if([aChild isKindOfClass:[BAInteger class]])
			return aChild;
	}
	return nil;
}

- (BAInteger*)rightIntegerExpressionForEvaluation
{
	if([[self children] count] == 2)
	{
		id aChild = [[self children] objectAtIndex:1];
		if([aChild isKindOfClass:[BAInteger class]])
			return aChild;
	}
	return nil;
}

- (BOOL)isInPrecedenceGroupWith:(BAOperator*)theOtherOperator
{
	
	// this checks to see if theOtherOperator
	// has the same level of precedence as self
	// for example
	// in the expression tree for the expression: 4 + 5 + 9 + 1,
	// the operators would be nested, and technically the one lowest
	// in the hierarchy must be evaluated first.  however, according to
	// the rules of the order of operations,
	// they are all at the same precedence level
	
	
	// to return yes
	// one operator must be a descendant of the other
	// and they must be the same operator
	// and all of the operators between them must be the same operator
	if(theOtherOperator == self)
		return YES;
	
	BAOperator * aRoot = nil;
	BAOperator * aNode = nil;
	if([self isDescendantOf:theOtherOperator])
	{
		aRoot = theOtherOperator;
		aNode = self;
	}
	else if([theOtherOperator isDescendantOf:self])
	{
		aRoot = self;
		aNode = theOtherOperator;
	}
	if(		aRoot
	   &&	aNode)
	{
		if([aRoot isKindOfClass:[aNode class]] == NO)
			return NO;
		
		while(aNode != aRoot)
		{
			if([aNode isKindOfClass:[aRoot class]])
				aNode = (BAOperator*)[aNode parent];
			else
				return NO;
		}
		return YES;
	}
	return NO;
}


@end
