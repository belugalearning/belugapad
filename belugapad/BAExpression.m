//
//  BAExpression.m
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//
//http://math.hws.edu/eck/cs225/s03/binary_trees/
//http://webcourse.cs.technion.ac.il/236703/Spring2005/ho/WCFiles/08C-Expression-Tree-in-C++-x4.pdf

#import "BAExpression.h"
#import "BABracketOperator.h"

@interface BAExpression ()
@end

@implementation BAExpression
@synthesize parent = wParent;
@synthesize children = mChildren;
@synthesize metadata;

- (id)init
{
	if(self = [super init])
	{
        self.metadata = [NSDictionary dictionary];
	}
	return self;
}

-(id)copyWithZone:(NSZone *)theZone
{
	BAExpression * aCopy = [[[self class] allocWithZone:theZone] init];
	
	aCopy->mChildren=nil;
	aCopy->wParent=nil;
	aCopy->mFullEvaluate = NO;
	
	// set children with a deep copy of our children
	[aCopy setChildren:[[[NSMutableArray alloc] initWithArray:[self children] copyItems:YES] autorelease]];
    
    // copy metadata
    aCopy.metadata = [NSDictionary dictionaryWithDictionary:self.metadata];
	
	return aCopy;
}

- (void)dealloc
{
	[mChildren release];
    self.metadata = nil;
	[super dealloc];
}

- (NSString*)stringValue
{
	return nil;
}

- (NSString*)expressionString
{
	return nil;
}

- (NSString*)xmlStringValueWithPad:(NSString *)padding
{
    return nil;
}

- (BOOL)canEvaluate
{
	return NO; // subclasses must implement this
}

- (BAExpression*)evaluate
{
	return nil;// subclasses must implelment this
}

- (BAExpression*)recursiveEvaluate
{
	return nil;//subclasses must implement this
}

- (BAExpression*)cloneEvaluate
{
	BAExpression * aCopy = [[self copy] autorelease];
	return [aCopy evaluate];
}


- (void)setFullEvaluate:(BOOL)theBool
{
	mFullEvaluate = theBool;
	for(BAExpression * aChild in [self children])
		[aChild setFullEvaluate:YES];
}


#pragma mark - Metadata
- (id)metadataValueForKey:(NSString *)key
{
    return [self.metadata valueForKey:key];
}

- (void)setMetadataValue:(id)value forKey:(NSString *)key;
{
    // Contrary to appearances, this is actually quite cheap due to internal optimisations in Foundation.
    // Plus, it keeps KVC/KVO compliance.
    // Profile it before attempting any manual optimisations!
    NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:self.metadata];
    [temp setValue:value forKey:key];
    self.metadata = [NSDictionary dictionaryWithDictionary:temp];
}

- (void)removeMetadataForKey:(NSString *)key
{
    // Contrary to appearances, this is actually quite cheap due to internal optimisations in Foundation.
    // Plus, it keeps KVC/KVO compliance.
    // Profile it before attempting any manual optimisations!
    NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:self.metadata];
    [temp removeObjectForKey:key];
    self.metadata = [NSDictionary dictionaryWithDictionary:temp];
}

#pragma mark -
#pragma mark Managing the Tree
- (void)setParent:(BAExpression *)theParent
{
	wParent = theParent;
}

- (BOOL)isLiteral
{
	return NO;
}

- (NSMutableArray*)children
{
	if(mChildren == nil)
		mChildren = [[NSMutableArray alloc] init];
	return mChildren;
}

- (BAExpression*)leftChild
{
	if([[self children] count] > 0)
		return [[self children] objectAtIndex:0];
	return nil;
}

- (BAExpression*)rightChild
{
	if([[self children] count] > 1)
		return [[self children] objectAtIndex:1];
	return nil;
}

- (void)setLeftChild:(BAExpression*)theChild
{
	if([[self children] count] == 0)
		[self addChild:theChild];
	else
	{
		BAExpression * aCurrentChild = [[self children] objectAtIndex:0];
		[self replaceChild:aCurrentChild withChild:theChild];
	}
}

- (void)setRightChild:(BAExpression*)theChild
{		
	if([[self children] count] == 1)
		[self addChild:theChild];
	else if([[self children] count] > 1)
	{
		BAExpression * aCurrentChild = [[self children] objectAtIndex:1];
		[self replaceChild:aCurrentChild withChild:theChild];
	}
	else
	{
		// CS: for now we don't allow setting the right child
		// without setting the left child first
		[NSException raise:@"BAExpression" format:@"Cannot set the right child without the left child set."];
	}
}

- (void)setChildren:(NSMutableArray*)theChildren
{	
	if([self isLiteral] == NO)
	{
		if(mChildren == nil)
			mChildren = [[NSMutableArray alloc] init];

		// clear out the old children and add the new ones one by one
		for(BAExpression * aChild in [self children])
			[aChild setParent:nil];
		[mChildren removeAllObjects];
		[mChildren addObjectsFromArray:theChildren];
		for(BAExpression * anExpression in theChildren)
			[anExpression setParent:self];
	}
}

- (void)addChild:(BAExpression*)theChild
{
	if([self isLiteral] == NO)
	{
		if(theChild!=nil)
		{
			[[self children] addObject:theChild];
			[theChild setParent:self];
		}
	}
	else
		[NSException raise:@"BAExpression" format:@"Cannot add a child to a literal expression"];
}

- (void)removeChild:(BAExpression*)theChild
{
	if([self isLiteral] == NO)
	{
		if(theChild!=nil)
		{
			[[self children] removeObject:theChild];
			[theChild setParent:nil];
		}
	}
	else
		[NSException raise:@"BAExpression" format:@"Cannot remove a child from a literal expression"];
}

- (void)addChildren:(NSArray*)theChildren
{
	if([self isLiteral] == NO)
	{
		for(BAExpression * aChild in theChildren)
			[self addChild:aChild];
	}
}

- (void)removeChildren:(NSArray*)theChildren;
{
	if([self isLiteral] == NO)
	{	
		for(BAExpression * aChild in theChildren)
			[self removeChild:aChild];
	}
}

- (void)replaceChild:(BAExpression *)theChildToReplace withChild:(BAExpression *)theNewChild
{
	NSUInteger aChildIndex = [[self children] indexOfObject:theChildToReplace];
	if(aChildIndex == NSNotFound)
	{
		[NSException raise:@"BAExpression" format:@"replaceChild:withChild: - original child not found"];
		return;
	}
	
	[theChildToReplace setParent:nil];
	[[self children] replaceObjectAtIndex:aChildIndex withObject:theNewChild];
	[theNewChild setParent:self];
}

- (void)insertChild:(BAExpression*)theChild atIndex:(NSUInteger)theIndex
{
	if([self isLiteral] == NO)
	{
		[theChild setParent:self];
		[[self children] insertObject:theChild atIndex:theIndex];
	}
}


- (BOOL)isDescendantOf:(BAExpression*)theExpression
{
	if(theExpression == self)
		return YES;
	
	BAExpression * aParent = [self parent];
	while(aParent != nil)
	{
		if(aParent == theExpression)
			return YES;
		aParent = [aParent parent];
	}
	return NO;
}

- (BOOL)containsNode:(BAExpression*)theNode
{
	if(theNode == self)
		return YES;
	for(BAExpression* aChild in [self children])
	{
		if([aChild containsNode:theNode])
			return YES;
	}
	return NO;
}

- (BABracketOperator*)enclosingBracketOperator
{
	BAExpression * aParent = [self parent];
	while (aParent != nil) 
	{
		if([aParent isKindOfClass:[BABracketOperator class]])
			return (BABracketOperator*)aParent;
		aParent = [aParent parent];
	}
	return nil;
}

- (NSArray*)leafNodes
{
	NSMutableArray * aLeafNodes = [NSMutableArray array];
	if([self isLiteral])
		[aLeafNodes addObject:self];
	else
	{
		for(BAExpression * aChild in [self children])
			[aLeafNodes addObjectsFromArray:[aChild leafNodes]];
	}
	return [[aLeafNodes copy] autorelease];
}

- (NSArray*)flatten
{
	NSMutableArray * aFlattenedTree = [NSMutableArray array];	
	
	// array is formatted to return a list in the "Infix notation" style
	// there is one exception: the bracket operator
	// which is placed after its internal expression
	//http://en.wikipedia.org/wiki/Infix_notation	
	// code showing how to build the lists with different notation styles:
	//http://math.hws.edu/eck/cs225/s03/binary_trees/	
	
	// Note: the following code assumes that the tree is well-formed
	NSArray * aChildren = [self children];
	if([aChildren count] >= 1) 
	{
		[aFlattenedTree addObjectsFromArray:[[aChildren objectAtIndex:0] flatten]];
		[aFlattenedTree addObject:self];
		if([aChildren count] > 1) // we have the special case of the bracket unary expression with no right child
			[aFlattenedTree addObjectsFromArray:[[aChildren objectAtIndex:1] flatten]];
	}
	else if([aChildren count]==0)
		[aFlattenedTree addObject:self];
	return aFlattenedTree;
}

- (NSInteger)nodeCount
{	
	NSInteger aCount = 1;
	for(BAExpression* aNode in [self children])
		aCount+=[aNode nodeCount];
	return aCount;
}

- (void)replaceChildWithOnlyChild:(BAExpression*)theChild
{
	if([self containsNode:theChild])
	{
		BAExpression * anOnlyChild = nil;
		if([[theChild children] count] ==1)
			anOnlyChild = [[[[theChild children] objectAtIndex:0] retain] autorelease];
		else
			[NSException raise:@"BAExperssionTree" format:@"replaceChildWithOnlyChild: - there is more than one child"];
	
		NSUInteger anInsertionIndex = [[self children] indexOfObject:theChild];
		[theChild setParent:nil];
		[[self children] removeObject:theChild];
		[anOnlyChild setParent:self];
		[[self children] insertObject:anOnlyChild atIndex:anInsertionIndex];
	}
}

- (BOOL)validate
{
	// I'm not checking that a parent exists 
	// because it is ok for the root of an expression to
	// exist without being in an expression tree...
	if([self childBalance] != 0)
		return NO;
	for(BAExpression* aChild in [self children])
	{
		if([aChild validate] == NO)
		   return NO;
	}
	return YES;
}


- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression
{
	return NO; // subclasses must implement this
}

- (BOOL)recursiveIsEqual:(BAExpression*)theOtherExpression
{
	if([self isEqualToExpression:theOtherExpression])
	{
		if([[self children] count] == [[theOtherExpression children] count])
		{
			for(NSUInteger i = 0; i < [[self children] count]; i++)
			{
				if([[[self children] objectAtIndex:i] recursiveIsEqual:[[theOtherExpression children] objectAtIndex:i]] == NO)
					return NO;
			}
			return YES;
		}
		return NO;
	}
	return NO;
}

@end

@implementation BAExpression(BAInternal)

- (BOOL)fullEvaluate
{
    return mFullEvaluate;
}

//- (void)setFullEvaluate:(BOOL)fullEvaluate
//{
//    mFullEvaluate = fullEvaluate;
//}

- (NSInteger)childBalance
{
	return 0; // only operator subclasses will have a possible surplus or deficit of children - default 0
}

- (BOOL)canBeReplacedByChild
{
	return NO;// only operator subclass will implement this - default NO
}

- (BOOL)canAddOperatorsForExtraChildren
{
	return NO;// only operator subclass will implement this - defalut NO
}

- (void)addOperatorIfNeeded
{
	// only operator subclass will implement this
}

- (void)removeRedundantOperatorIfNeeded
{
	// only operator subclass will implement this
}

@end

