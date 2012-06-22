//
//  BAExpressionTree.m
//  Beluga
//
//  Created by Cathy Shive on 1/30/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import "BAExpressionTree.h"
#import "NSArray_BAAdditions.h"

@interface BAExpressionTree ()
@end

@interface BAExpressionTree(Private)

- (void)_prune;

- (BOOL)_node:(BAExpression *)theNode1 isInSameExpressionAs:(BAExpression *)theNode2;
- (BAExpression*)_changeSignOfNode:(BAExpression*)theNode;

- (void)_removeNode:(BAExpression*)theNodeToRemove;
- (BOOL)_canMoveNode:(BAExpression*)theNode1 toBranchWithNode:(BAExpression*)theNode2;
- (void)_moveNode:(BAExpression*)theNode1 acrossEqualityBeforeNode:(BAExpression*)theNode2;
- (void)_moveNode:(BAExpression *)theNode1 acrossEqualityAfterNode:(BAExpression *)theNode2;
- (BOOL)_moveNode:(BAExpression *)theNode1 toExpressionWithNode:(BAExpression *)theNode2;
- (void)_addNode:(BAExpression *)theNode1 toExpressionWithRoot:(BAExpression *)theTargetExpressionRoot withOperator:(BAOperator *)theTargetOperator beforeNode:(BAExpression*)theNode2;
- (void)_addNode:(BAExpression *)theNode1 toExpressionWithRoot:(BAExpression *)theTargetExpressionRoot withOperator:(BAOperator *)theTargetOperator afterNode:(BAExpression*)theNode2;
- (void)_addNode:(BAExpression*)theNode toExpressionWithRoot:(BAExpression*)theTargetExpressionRoot withOperator:(BAOperator*)theTargetOperator;
- (BAExpression*)_removeNode:(BAExpression*)theNode fromExpressionWithRoot:(BAExpression*)theSourceExpressionRoot;
- (void)_insertNode:(BAExpression*)theNode1 beforeNode:(BAExpression*)theNode2;
- (void)_insertNode:(BAExpression*)theNode1 afterNode:(BAExpression*)theNode2;

- (BAExpression*)_nodeAtIndex:(NSInteger)theIndex;
- (NSInteger)_indexForNode:(BAExpression*)theNode;
@end

@implementation BAExpressionTree
@synthesize root = mRoot;
@synthesize VariableSubstitutions;

+(BAExpressionTree*)treeWithRoot:(BAExpression*)theRoot
{
	BAExpressionTree * aTree = [[[self alloc] init] autorelease];
	[aTree setRoot:theRoot];
	return aTree;
}

- (id)copyWithZone:(NSZone *)theZone
{
	BAExpressionTree* aCopy = (BAExpressionTree*)[[[self class] allocWithZone:theZone] init];
    
    //TODO: is this right?
	aCopy->mRoot = nil;
    
    //copy the subs dict
    aCopy.VariableSubstitutions=[[self.VariableSubstitutions copyWithZone:theZone] autorelease];
    
	[aCopy setRoot:[[[self root] copy] autorelease]];
	return aCopy;
}

- (void)dealloc
{
	[mRoot release];
	[super dealloc];
}


#pragma mark Root
- (void)setRoot:(BAExpression *)theRoot
{
	if(mRoot!=theRoot)
	{
		[mRoot setParent:nil];
		[mRoot release];
		mRoot = [theRoot retain];
		[mRoot setParent:self];
	}
}


#pragma mark -
#pragma mark API


#pragma mark move api
- (BOOL)canMoveNode:(BAExpression*)theNode
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	// the node can't be the root
	if([self root] == theNode)
		return NO;
	
	// can only move literal nodes
	// in this case the power op is treated like a literal node
	if(		[theNode isLiteral]
	   ||	[theNode isKindOfClass:[BAPowerOperator class]])
		return YES;
	
	return NO;
}

- (BOOL)canMoveNode:(BAExpression *)theNode1 beforeNode:(BAExpression*)theNode2
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	return [self _canMoveNode:theNode1 toBranchWithNode:theNode2];
}

- (BOOL)canMoveNode:(BAExpression *)theNode1 afterNode:(BAExpression*)theNode2;
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	return [self _canMoveNode:theNode1 toBranchWithNode:theNode2];
}

- (void)moveNode:(BAExpression *)theNode1 beforeNode:(BAExpression *)theNode2
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];

	if([self _canMoveNode:theNode1 toBranchWithNode:theNode2] == NO)
		return;
	
	// check for moving across an equality operator
	if([self _node:theNode1 isInSameExpressionAs:theNode2] == NO)
	{
		[self _moveNode:theNode1 acrossEqualityBeforeNode:theNode2];
	}
	else
	{
		// otherwise, do a simple remove and insert
		[[theNode1 retain] autorelease];
		[self _removeNode:theNode1];
		[self _insertNode:theNode1 beforeNode:theNode2];
	}
	
	[self _prune];
	[self validate];
}

- (void)moveNode:(BAExpression *)theNode1 afterNode:(BAExpression *)theNode2
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	if([self _canMoveNode:theNode1 toBranchWithNode:theNode2] == NO)
		return;
	
	// check for moving across an equality operator
	if([self _node:theNode1 isInSameExpressionAs:theNode2] == NO)
	{
		[self _moveNode:theNode1 acrossEqualityAfterNode:theNode2];
	}
	else
	{	
		// otherwise, do a simple remove and insert
		[[theNode1 retain] autorelease];
		[self _removeNode:theNode1];
		[self _insertNode:theNode1 afterNode:theNode2];
	}
	
	[self _prune];
	[self validate];
}

/*
	if there is not equality, returns 0
	if the expression is on the left side of the equality, retuns -1
	if the expression is on the right side of the equality, returns 1
*/
- (NSInteger)sideOfEqualityForNode:(BAExpression*)theNode
{
	if([[self root] isKindOfClass:[BAEqualsOperator class]] == NO)
		return 0;
	
	if([theNode isDescendantOf:[[[self root] children] objectAtIndex:0]])
		return -1;
	
	else if([theNode isDescendantOf:[[[self root] children] objectAtIndex:1]])
		return 1;
	
	else return NSNotFound;
}

#pragma mark remove api

- (void)removeNodes:(NSArray*)theNodes
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	
	for(BAExpression * aNode in theNodes)
		[self _removeNode:aNode];
	
	[self _prune];
	if([self validate] == NO)
		[NSException raise:@"BAExpressionTree" format:@"removeNode: - tree does not validate after remove operation"];	
}

- (void)removeNode:(BAExpression*)theNode
{	
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	[self _removeNode:theNode];
	
	[self _prune];
	[self validate];
}

#pragma mark insert api
- (void)insertNode:(BAExpression*)theNode1 beforeNode:(BAExpression*)theNode2
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	[self _insertNode:theNode1 beforeNode:theNode2];
	
	[self _prune];
	[self validate];
}

- (void)insertNode:(BAExpression*)theNode1 afterNode:(BAExpression*)theNode2
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	[self _insertNode:theNode1 afterNode:theNode2];
	
	[self _prune];
	[self validate];	
}



#pragma mark replace api
- (void)replaceNode:(BAExpression*)theNode1 withNode:(BAExpression*)theNode2
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	if(		[self containsNode:theNode1] == NO
	   ||	[self containsNode:theNode2])
	{
		[NSException raise:@"BAExpressionTree" format:@"replaceNode:withNode: - theNode1 must be contained by tree and theNode2 cannot be contained by the tree"];
		return;
	}
	
	BAExpression * aPrarent = [theNode1 parent];
	if(aPrarent == nil)
	{
		[NSException raise:@"BAExpressioNTree" format:@"replaceNode:withNode: - theNode one has no parent"];
		return;
	}
	
	[aPrarent replaceChild:theNode1 withChild:theNode2];
	
	[self _prune];
	[self validate];
}

-(void)substitueVariablesForIntegersOnNode:(BAExpression *)theNode
{
    if(!self.VariableSubstitutions)return;
    for (int i=0; i<[[theNode children] count]; i++) {
        BAExpression *childNode=[[theNode children] objectAtIndex:i];
        if([childNode isKindOfClass:[BAVariable class]])
        {            
            BAVariable *vnode=(BAVariable*)childNode;
            
            if(vnode.multiplierIntValue!=1)[NSException raise:@"BAExpressionTree" format:@"variable multipliers not supported"];
            
            NSNumber *nsub=[self.VariableSubstitutions objectForKey:vnode.name];
            if(nsub)
            {
                BAInteger *inode=[BAInteger integerWithIntValue:[nsub integerValue]];
                [self replaceNode:vnode withNode:inode];
            }
        }
        else {
            [self substitueVariablesForIntegersOnNode:childNode];
        }
    }
}

- (void)reverseSidesAroundEquality
{
	if([[self root] isKindOfClass:[BAEqualsOperator class]])
	{
		BAExpression * aLeftChild = [[[self root] children] objectAtIndex:0];
		BAExpression * aRightChild = [[[self root] children] objectAtIndex:1];
		[[self root] setChildren:[NSArray arrayWithObjects:aRightChild, aLeftChild, nil]];
	}
}


#pragma mark private
- (BOOL)_canMoveNode:(BAExpression*)theNode1 toBranchWithNode:(BAExpression*)theNode2
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	// can't move the root
	if(theNode1 == [self root])
		return NO;
	
	if(		[self containsNode:theNode1] == NO
	   ||	[self containsNode:theNode2] == NO)
		return NO;
	
	if(		[theNode2 parent] == nil
	   ||	[theNode1 parent] == nil)
		return NO;
	
	// can't swap nodes around for their parents, can only rearrange the "leafs"
	if([theNode1 parent] == theNode2)
		return NO;
	
	if(theNode1 == theNode2)
		return NO;
	
	// if the nodes are on opposite sides of an equality operator
	if([self _node:theNode1 isInSameExpressionAs:theNode2] == NO)
	{
		return YES;
		// check for two things:
		// 1.  That theNode1 can move across the equality line
		// 2.  That we can insert node1 in the same branch as theNode2
		// for both of these to come out true, both nodes must be at the same
		// level of presedence as the root's children
		
		BOOL aCanMove = NO;
		
		// 1:  check theNode1
		// we can allow the move if
		// - node1 is a child of the root
		// - node1's parent is a child of the root
		// - node1's parent is part of a precedence group with a child of the root
		
		BAExpression * aNode1Parent = [theNode1 parent];
		NSArray * aChildrenOfRoot = [[self root] children];
		if(		[aChildrenOfRoot containsObject:theNode1]
		   ||	[aChildrenOfRoot containsObject:aNode1Parent])
		{	
			aCanMove = YES;
		}
		else if([aNode1Parent isKindOfClass:[BAOperator class]])
		{
			for(BAExpression * aChild in aChildrenOfRoot)
			{
				if([aChild isKindOfClass:[BAOperator class]])
				{
					if([(BAOperator*)aNode1Parent isInPrecedenceGroupWith:(BAOperator*)aChild])
					{
						aCanMove = YES;
						break;
					}
				}
			}
		}		
		
		if(aCanMove)
		{
			aCanMove = NO;
			//			// 2. check theNode2
			//			if([self root] == theNode2)
			//				aCanMove = YES;
			//			else
			//			{
			// we can allow the move if
			// - node2 is a child of the root
			// - node2's parent is a child of the root
			// - node2's parent is part of a precedence group with a child of the root
			
			BAExpression * aNode2Parent = [theNode2 parent];
			if(		[aChildrenOfRoot containsObject:theNode2]
			   ||	[aChildrenOfRoot containsObject:aNode2Parent])
			{
				aCanMove = YES;
			}
			else if([aNode2Parent isKindOfClass:[BAOperator class]])
			{
				for(BAExpression * aChild in aChildrenOfRoot)
				{
					if([aChild isKindOfClass:[BAOperator class]])
					{
						if([(BAOperator*)aNode2Parent isInPrecedenceGroupWith:(BAOperator*)aChild])
						{
							aCanMove = YES;
							break;
						}
					}
				}
			}			
		}			
		//		}
		
		if(aCanMove)
		{
			// temporarily disabling support for nodes whose 
			// parent is either an multiplicaiton or division operator
			if(		[[theNode1 parent] isKindOfClass:[BAMultiplicationOperator class]]
			   ||	[[theNode1 parent] isKindOfClass:[BADivisionOperator class]])
				aCanMove = NO;
		}
		return aCanMove;
		
	}
	
	// if we aren't moving accross equlity operator
	// theNode2 can't be the root
	if([self root] == theNode2)
		return NO;
	
	// 1. Enclosing brackets, if there is a bracket and both expressions are not a descendant of the same bracket, return no
	// 2. Both parents must be commutative
	// 3. If node1 and node2 have the same parent return yes
	// 4.  a. If node1 is a descendant of node2's parent or vice versa
	//	   b. If the parents have enclosing brackets and they are not in the same brackets, return no
	//	   b. the parent's have the same prescendent return yes
	
	// 1 - check enclosing brackets
	BABracketOperator * aNode1EnclosingBracket = [theNode1 enclosingBracketOperator];
	BABracketOperator * aNode2EnclosingBracket = [theNode2 enclosingBracketOperator];
	if(		aNode1EnclosingBracket
	   ||	aNode2EnclosingBracket)
		if(aNode1EnclosingBracket != aNode2EnclosingBracket)
			return NO;
	
	BAOperator * aParent1 = (BAOperator*)[theNode1 parent];
	BAOperator * aParent2 = (BAOperator*)[theNode2 parent];
	
	// 2 - check the commutativity of the parents
	if([aParent1 isCommutative] && [aParent2 isCommutative])
	{
		// 3 - same parent OK
		if(aParent1 == aParent2)
			return YES;
		
		// 4a - is one parent a descendant of the other? (2 + 3 + 5) if we want to swap the 2 and 5, this would be the case
		if(		[aParent1 isInPrecedenceGroupWith:aParent2])
		{	
			// 4b - do the parents have the same prscendence? (2 + 3 + 5) if we want to swap the 2 and 5, this would be the case
			BAOperatorSortDescriptor * aSortDescriptor = [[[BAOperatorSortDescriptor alloc] init] autorelease];
			NSInteger aParent1Precedence = [aSortDescriptor priorityIntForOperator:aParent1];
			NSInteger aPresnt2Precedence = [aSortDescriptor priorityIntForOperator:aParent2];
			if(aParent1Precedence == aPresnt2Precedence)
				return YES;
		}
	}
	return NO;		
}

- (void)_moveNode:(BAExpression*)theNode1 acrossEqualityBeforeNode:(BAExpression*)theNode2
{
	
	// split up the two sides into two separate expressions:
	BAExpression * aLeftExpressionRoot = [[[self root] children] objectAtIndex:0];
	BAExpression * aRightExpressionRoot = [[[self root] children] objectAtIndex:1];
	
	BAExpression * aSourceExpression = [aLeftExpressionRoot containsNode:theNode1]?aLeftExpressionRoot:aRightExpressionRoot;
	BAExpression * aTargetExpression = [aLeftExpressionRoot containsNode:theNode2]?aLeftExpressionRoot:aRightExpressionRoot;
	
	
	// Hack for a special case.
	// while mathematically, you should be able to drag a numerator of a division expression across an equality operator, 
	// we don't have the UI to support the result (decimals or fractions), so we disallow it here
	if(		[[theNode1 parent] isKindOfClass:[BADivisionOperator class]]
	   &&	[[[theNode1 parent] children] indexOfObject:theNode1] == 0) // the numerator is the left side child
		return;
	
	
	// Another special case
	// if there are only single literal expressions on both sides of the equality operator
	// just flip them around 
	if(		[aLeftExpressionRoot isLiteral]
	   &&	[aRightExpressionRoot isLiteral])
	{
		NSMutableArray * aFlippedChildren = [NSMutableArray arrayWithObjects:aRightExpressionRoot, aLeftExpressionRoot,nil];
		[[self root] setChildren:aFlippedChildren];
		return;
	}
	
	
	// step one:
	// remove 'theNode1' from the source expression
	// validate the source expression - this should leave the left expression valid
	
	// hold onto node1, it should be released after we remove it from the source 
	// expression and we don't want it to dealloc
	[[theNode1 retain] autorelease];
	BAExpression * aTargetOperator = [self _removeNode:theNode1 fromExpressionWithRoot:aSourceExpression];
	// One thing to note is that after the previous line, 'aSourceExpression' is probably no longer the correct pointer to the root of the expression
	// because of this, I'm going to clear out the reference
	aSourceExpression = nil;
	
	// if no target operator is returned, it means that the node wasn't removed
	// so we cannot proceed to add it to the other expression
	// we just fail silently
	if(aTargetOperator)
	{
		// One thing to check at this stage is that theNode1 has no parent
		if([theNode1 parent] != nil)
		{
			[NSException raise:@"BAExpressionTree" format:@"_moveNode:acrossEquality: - node has been removed from its original expression, yet still has a parent"];
			return;
		}
	
		// step two:
		// add 'theNode1' to the target expression
		// validate the target expression
		[self _addNode:theNode1 toExpressionWithRoot:aTargetExpression withOperator:(BAOperator*)aTargetOperator beforeNode:theNode2];
		[aTargetExpression validate];
	}
}

- (void)_moveNode:(BAExpression *)theNode1 acrossEqualityAfterNode:(BAExpression *)theNode2
{
	// split up the two sides into two separate expressions:
	BAExpression * aLeftExpressionRoot = [[[self root] children] objectAtIndex:0];
	BAExpression * aRightExpressionRoot = [[[self root] children] objectAtIndex:1];
	
	BAExpression * aSourceExpression = [aLeftExpressionRoot containsNode:theNode1]?aLeftExpressionRoot:aRightExpressionRoot;
	BAExpression * aTargetExpression = [aLeftExpressionRoot containsNode:theNode2]?aLeftExpressionRoot:aRightExpressionRoot;
	
	
	// Hack for a special case.
	// while mathematically, you should be able to drag a numerator of a division expression across an equality operator, 
	// we don't have the UI to support the result (decimals or fractions), so we disallow it here
	if(		[[theNode1 parent] isKindOfClass:[BADivisionOperator class]]
	   &&	[[[theNode1 parent] children] indexOfObject:theNode1] == 0) // the numerator is the left side child
		return;
	
	
	// Another special case
	// if there are only single literal expressions on both sides of the equality operator
	// just flip them around 
	if(		[aLeftExpressionRoot isLiteral]
	   &&	[aRightExpressionRoot isLiteral])
	{
		NSMutableArray * aFlippedChildren = [NSMutableArray arrayWithObjects:aRightExpressionRoot, aLeftExpressionRoot,nil];
		[[self root] setChildren:aFlippedChildren];
		return;
	}
	
	
	// step one:
	// remove 'theNode1' from the source expression
	// validate the source expression - this should leave the left expression valid
	
	// hold onto node1, it should be released after we remove it from the source 
	// expression and we don't want it to dealloc
	[[theNode1 retain] autorelease];
	BAExpression * aTargetOperator = [self _removeNode:theNode1 fromExpressionWithRoot:aSourceExpression];
	// One thing to note is that after the previous line, 'aSourceExpression' is probably no longer the correct pointer to the root of the expression
	// because of this, I'm going to clear out the reference
	aSourceExpression = nil;
	
	// if no target operator is returned, it means that the node wasn't removed
	// so we cannot proceed to add it to the other expression
	// we just fail silently
	if(aTargetOperator)
	{
		// One thing to check at this stage is that theNode1 has no parent
		if([theNode1 parent] != nil)
		{
			[NSException raise:@"BAExpressionTree" format:@"_moveNode:acrossEquality: - node has been removed from its original expression, yet still has a parent"];
			return;
		}
		
		// step two:
		// add 'theNode1' to the target expression
		// validate the target expression
		[self _addNode:theNode1 toExpressionWithRoot:aTargetExpression withOperator:(BAOperator*)aTargetOperator afterNode:theNode2];
		[aTargetExpression validate];
	}
}

- (BOOL)_moveNode:(BAExpression *)theNode1 toExpressionWithNode:(BAExpression *)theNode2
{
	// split up the two sides into two separate expressions:
	BAExpression * aLeftExpressionRoot = [[[self root] children] objectAtIndex:0];
	BAExpression * aRightExpressionRoot = [[[self root] children] objectAtIndex:1];
	
	BAExpression * aSourceExpression = [aLeftExpressionRoot containsNode:theNode1]?aLeftExpressionRoot:aRightExpressionRoot;
	BAExpression * aTargetExpression = [aLeftExpressionRoot containsNode:theNode2]?aLeftExpressionRoot:aRightExpressionRoot;
	
	
	// Hack for a special case.
	// while mathematically, you should be able to drag a numerator of a division expression across an equality operator, 
	// we don't have the UI to support the result (decimals or fractions), so we disallow it here
	if(		[[theNode1 parent] isKindOfClass:[BADivisionOperator class]]
	   &&	[[[theNode1 parent] children] indexOfObject:theNode1] == 0) // the numerator is the left side child
		return NO;
	
	
	// Another special case
	// if there are only single literal expressions on both sides of the equality operator
	// just flip them around 
	if(		[aLeftExpressionRoot isLiteral]
	   &&	[aRightExpressionRoot isLiteral])
	{
		NSMutableArray * aFlippedChildren = [NSMutableArray arrayWithObjects:aRightExpressionRoot, aLeftExpressionRoot,nil];
		[[self root] setChildren:aFlippedChildren];
		return NO;
	}
	
	
	// step one:
	// remove 'theNode1' from the source expression
	// validate the source expression - this should leave the left expression valid
	
	// hold onto node1, it should be released after we remove it from the source 
	// expression and we don't want it to dealloc
	[[theNode1 retain] autorelease];
	BAExpression * aTargetOperator = [self _removeNode:theNode1 fromExpressionWithRoot:aSourceExpression];
	// One thing to note is that after the previous line, 'aSourceExpression' is probably no longer the correct pointer to the root of the expression
	// because of this, I'm going to clear out the reference
	aSourceExpression = nil;
	
	// if no target operator is returned, it means that the node wasn't removed
	// so we cannot proceed to add it to the other expression
	// we just fail silently
	if(aTargetOperator)
	{
		// One thing to check at this stage is that theNode1 has no parent
		if([theNode1 parent] != nil)
		{
			[NSException raise:@"BAExpressionTree" format:@"_moveNode:acrossEquality: - node has been removed from its original expression, yet still has a parent"];
			return NO;
		}
		
		// step two:
		// add 'theNode1' to the target expression
		// validate the target expression
		[self _addNode:theNode1 toExpressionWithRoot:aTargetExpression withOperator:(BAOperator*)aTargetOperator];
		[aTargetExpression validate];
		return YES;
	}
	return NO;
}


- (void)_addNode:(BAExpression *)theNode1 toExpressionWithRoot:(BAExpression *)theTargetExpressionRoot withOperator:(BAOperator *)theTargetOperator beforeNode:(BAExpression*)theNode2
{
	if(		theNode1 == nil
	   ||	theNode2 == nil
	   ||	theTargetExpressionRoot == nil
	   ||	theTargetOperator == nil)
	{
		[NSException raise:@"BAExpressionTree" format:@"_addNode:toExpressionWithRoot:withOperator: - invalid argument exception"];
	}
	
	// to keep things more simple, while I get this working, I'm separating out the implementation of adding 
	// the node with an addition operator and a multiplication or division operator
	// with the addition operator, we will insert theNode1 before theNode2
	// with the other operators, we will only wrap the current root expression in a bracket and add theNode1 after the whole expression
	
	if([theTargetOperator isKindOfClass:[BAAdditionOperator class]])
	{
//		if(		[theTargetExpressionRoot isKindOfClass:[BAInteger class]]
//		   &&	[(BAInteger*)theTargetExpressionRoot intValue] == 0)
//		{
//			// special case, if we're adding the a "zero" expression, 
//			// simply replace the zero with theNode
//			BAExpression * aParent = [theTargetExpressionRoot parent];
//			[aParent replaceChild:theTargetExpressionRoot withChild:theNode];
//		}
//		else
//		{
		BAExpression * aTargetParent = [theNode2 parent];
		NSInteger aNode2Index = [[aTargetParent children] indexOfObject:theNode2];
		[[theNode2 retain] autorelease];
		BAExpression * aChildToReplace = nil;
		NSInteger anInsertionIndex = 0;
		NSMutableArray * aNewOperatorChildren = nil;
		
		if([self root] != aTargetParent)
		{
			aChildToReplace = [[[[aTargetParent children] objectAtIndex:anInsertionIndex] retain] autorelease];
			if(theNode2 != aChildToReplace)
				[aTargetParent removeChild:aChildToReplace];
			[aTargetParent removeChild:theNode2];
			if(aNode2Index == 0)
				aNewOperatorChildren = [NSMutableArray arrayWithObjects:theNode1, aChildToReplace, nil];
			else if(aNode2Index == 1)
				aNewOperatorChildren = [NSMutableArray arrayWithObjects:aChildToReplace, theNode1, nil];
		}
		else
		{
			[aTargetParent removeChild:theNode2];
			aNewOperatorChildren = [NSMutableArray arrayWithObjects:theNode1, theNode2, nil];
			anInsertionIndex = aNode2Index;
			
		}
		[theTargetOperator setChildren:aNewOperatorChildren];
		NSMutableArray * aTargetParentChildren = [[[aTargetParent children] mutableCopy] autorelease];
		[aTargetParentChildren insertObject:theTargetOperator atIndex:anInsertionIndex];
		[aTargetParent setChildren:aTargetParentChildren];
		//}
	}
	else if(	[theTargetOperator isKindOfClass:[BAMultiplicationOperator class]]
			||	[theTargetOperator isKindOfClass:[BADivisionOperator class]])
	{
		BAExpression * aTargetParent = [theTargetExpressionRoot parent];
		NSMutableArray * aNewRootChildren = [[[aTargetParent children] mutableCopy] autorelease];
		NSInteger anInsertionIndex = [[aTargetParent children] indexOfObject:theTargetExpressionRoot];
		
		[[theNode1 retain] autorelease];
		[[theTargetExpressionRoot retain] autorelease];
		[aTargetParent removeChild:theTargetExpressionRoot];
		
		BABracketOperator * aBracketOperator = [[[BABracketOperator alloc] init] autorelease];		
		[aBracketOperator addChild:theTargetExpressionRoot];
		
		NSMutableArray * anOperatorChildren = [NSMutableArray arrayWithObjects:aBracketOperator, theNode1, nil];
		[theTargetOperator setChildren:anOperatorChildren];
		
		[aNewRootChildren insertObject:theTargetOperator atIndex:anInsertionIndex];
		[aNewRootChildren removeObject:theTargetExpressionRoot];
		[aTargetParent setChildren:aNewRootChildren];
	}	
}

- (void)_addNode:(BAExpression *)theNode1 toExpressionWithRoot:(BAExpression *)theTargetExpressionRoot withOperator:(BAOperator *)theTargetOperator afterNode:(BAExpression*)theNode2
{
	if(		theNode1 == nil
	   ||	theNode2 == nil
	   ||	theTargetExpressionRoot == nil
	   ||	theTargetOperator == nil)
	{
		[NSException raise:@"BAExpressionTree" format:@"_addNode:toExpressionWithRoot:withOperator: - invalid argument exception"];
	}
	
	// to keep things more simple, while I get this working, I'm separating out the implementation of adding 
	// the node with an addition operator and a multiplication or division operator
	// with the addition operator, we will insert theNode1 before theNode2
	// with the other operators, we will only wrap the current root expression in a bracket and add theNode1 after the whole expression
	
	if([theTargetOperator isKindOfClass:[BAAdditionOperator class]])
	{
		//		if(		[theTargetExpressionRoot isKindOfClass:[BAInteger class]]
		//		   &&	[(BAInteger*)theTargetExpressionRoot intValue] == 0)
		//		{
		//			// special case, if we're adding the a "zero" expression, 
		//			// simply replace the zero with theNode
		//			BAExpression * aParent = [theTargetExpressionRoot parent];
		//			[aParent replaceChild:theTargetExpressionRoot withChild:theNode];
		//		}
		//		else
		//		{
		
		
		BAExpression * aNode2Parnet = [theNode2 parent];
		BAExpression * aTargetParent = [aNode2Parnet parent];
		BAExpression * aChildToReplace = nil;
		NSMutableArray * aNewOperatorChildren = nil;
		NSInteger anInsertionIndex = 0;;
		
		if([self root] != aNode2Parnet)
		{
			aChildToReplace = [[aNode2Parnet retain] autorelease];
			anInsertionIndex = [[aTargetParent children] indexOfObject:aChildToReplace];
			aNewOperatorChildren = [NSMutableArray arrayWithObjects:aChildToReplace, theNode1, nil];
			[aTargetParent removeChild:aChildToReplace];
		}
		else
		{
			aTargetParent = aNode2Parnet;
			anInsertionIndex = [[aNode2Parnet children] indexOfObject:theNode2];
			[aNode2Parnet removeChild:theNode2];
			aNewOperatorChildren = [NSMutableArray arrayWithObjects:theNode2,theNode1, nil];
		}
		
		[theTargetOperator setChildren:aNewOperatorChildren];
		NSMutableArray * aTargetParentChildren = [[[aTargetParent children] mutableCopy] autorelease];
		[aTargetParentChildren insertObject:theTargetOperator atIndex:anInsertionIndex];
		[aTargetParent setChildren:aTargetParentChildren];
		//}
	}
	else if(	[theTargetOperator isKindOfClass:[BAMultiplicationOperator class]]
			||	[theTargetOperator isKindOfClass:[BADivisionOperator class]])
	{
		BAExpression * aTargetParent = [theTargetExpressionRoot parent];
		NSMutableArray * aNewRootChildren = [[[aTargetParent children] mutableCopy] autorelease];
		NSInteger anInsertionIndex = [[aTargetParent children] indexOfObject:theTargetExpressionRoot];
		
		[[theNode1 retain] autorelease];
		[[theTargetExpressionRoot retain] autorelease];
		[aTargetParent removeChild:theTargetExpressionRoot];
		
		BABracketOperator * aBracketOperator = [[[BABracketOperator alloc] init] autorelease];		
		[aBracketOperator addChild:theTargetExpressionRoot];
		
		NSMutableArray * anOperatorChildren = [NSMutableArray arrayWithObjects:aBracketOperator, theNode1, nil];
		[theTargetOperator setChildren:anOperatorChildren];
		
		[aNewRootChildren insertObject:theTargetOperator atIndex:anInsertionIndex];
		[aNewRootChildren removeObject:theTargetExpressionRoot];
		[aTargetParent setChildren:aNewRootChildren];
	}	
}


- (void)_addNode:(BAExpression*)theNode toExpressionWithRoot:(BAExpression*)theTargetExpressionRoot withOperator:(BAOperator*)theTargetOperator
{
	if(		theNode == nil
	   ||	theTargetExpressionRoot == nil
	   ||	theTargetOperator == nil)
	{
		[NSException raise:@"BAExpressionTree" format:@"_addNode:toExpressionWithRoot:withOperator: - invalid argument exception"];
	}
	
	// for now, just to get things working in the most simple way possible, we don't insert next to any specific 
	// node in the target expression
	// instead we make the new operator the new root
	// with the old root as a child, along with theNode
	
	// watch out for orders of operation!
	
	// if the new operator is a higher precedence, we need to actually add it to the end of the expression
	// the easiest way to do that is to put the current root inside of a bracket operator

	// so, if it's an addition operator, we're going to replace the old root with the operator
	// the oparator will have theNode and the old root as children
	if([theTargetOperator isKindOfClass:[BAAdditionOperator class]])
	{
//		if(		[theTargetExpressionRoot isKindOfClass:[BAInteger class]]
//		   &&	[(BAInteger*)theTargetExpressionRoot intValue] == 0)
//		{
//			// special case, if we're adding the a "zero" expression, 
//			// simply replace the zero with theNode
//			BAExpression * aParent = [theTargetExpressionRoot parent];
//			[aParent replaceChild:theTargetExpressionRoot withChild:theNode];
//		}
//		else
//		{
			BAExpression * aTargetParent = [theTargetExpressionRoot parent];
			NSMutableArray * aNewRootChildren = [[[aTargetParent children] mutableCopy] autorelease];
			NSInteger anInsertionIndex = [[aTargetParent children] indexOfObject:theTargetExpressionRoot];
			
			[[theNode retain] autorelease];
			[[theTargetExpressionRoot retain] autorelease];
			[aTargetParent removeChild:theTargetExpressionRoot];
			
			NSMutableArray * anOperatorChildren = [NSMutableArray arrayWithObjects:theNode, theTargetExpressionRoot, nil];
			[theTargetOperator setChildren:anOperatorChildren];
			
			[aNewRootChildren insertObject:theTargetOperator atIndex:anInsertionIndex];
			[aNewRootChildren removeObject:theTargetExpressionRoot];
			[aTargetParent setChildren:aNewRootChildren];
//		}
	}
	else if(	[theTargetOperator isKindOfClass:[BAMultiplicationOperator class]]
			||	[theTargetOperator isKindOfClass:[BADivisionOperator class]])
	{
		BAExpression * aTargetParent = [theTargetExpressionRoot parent];
		NSMutableArray * aNewRootChildren = [[[aTargetParent children] mutableCopy] autorelease];
		NSInteger anInsertionIndex = [[aTargetParent children] indexOfObject:theTargetExpressionRoot];
		
		[[theNode retain] autorelease];
		[[theTargetExpressionRoot retain] autorelease];
		[aTargetParent removeChild:theTargetExpressionRoot];
		
		BABracketOperator * aBracketOperator = [[[BABracketOperator alloc] init] autorelease];		
		[aBracketOperator addChild:theTargetExpressionRoot];
		
		NSMutableArray * anOperatorChildren = [NSMutableArray arrayWithObjects:aBracketOperator, theNode, nil];
		[theTargetOperator setChildren:anOperatorChildren];
		
		[aNewRootChildren insertObject:theTargetOperator atIndex:anInsertionIndex];
		[aNewRootChildren removeObject:theTargetExpressionRoot];
		[aTargetParent setChildren:aNewRootChildren];
	}
}

- (BAExpression*)_removeNode:(BAExpression*)theNode fromExpressionWithRoot:(BAExpression*)theSourceExpressionRoot
{
	if(		theSourceExpressionRoot == nil
	   ||	[theSourceExpressionRoot containsNode:theNode] == NO)
	{
		[NSException raise:@"BAExpressionTree" format:@"_removeNode:fromExpression: - invalid argument exception"];
		return nil;
	}
	
	BAExpression * aResultingOperator = nil;
	
	if(theNode == theSourceExpressionRoot)
	{
		// this happens if there is a single literal node on either side of the root
		// to remove it, we must replace it with an integer with the value of zero
		// if the value is already 0, we can't do anything 
		if(		[theNode isKindOfClass:[BAInteger class]]
		   &&	[(BAInteger*)theNode intValue] == 0)
		{
			return nil;
		}
		
		// CS: NOTE - this logic isn't resulting in correct resluts for equations:
		// until I figure out why, I'm just going to return nil
		return nil;
		
		BAInteger *	aZeroInteger = [BAInteger integerWithIntValue:0];
		BAExpression * aParent = [theSourceExpressionRoot parent];
		[aParent replaceChild:theNode withChild:aZeroInteger];
		aResultingOperator = [[[BAAdditionOperator alloc] init] autorelease];
	}
	else
	{
		BAExpression * aParent = [[[theNode parent] retain] autorelease];
		
		// we continue with the assumption that the parent and the root are both operators
		if(		[aParent isKindOfClass:[BAOperator class]] == NO
		   ||	[theSourceExpressionRoot isKindOfClass:[BAOperator class]] == NO)
		{
			[NSException raise:@"BAExpressionTree" format:@"_removeNode:fromExpression: - the node's parent or the root node is not an operator, as expected"];
			return nil;
		}
		
		// the parent must be part of the same precedence group as the root
		if([(BAOperator*)aParent isInPrecedenceGroupWith:(BAOperator*)theSourceExpressionRoot] == NO)
		{
			return nil;
		}
		
		// first let's deal with the case where the parent operation is 
		// either addition or multiplication
		if(		[aParent isKindOfClass:[BAAdditionOperator class]]
		   ||	[aParent isKindOfClass:[BAMultiplicationOperator class]])
		{
			// we can simply remove the child and let the tree clean up itself
			[aParent removeChild:theNode];
			[aParent removeRedundantOperatorIfNeeded];
		
			// the operator we will return is the opposite of the parent
			aResultingOperator = [aParent isKindOfClass:[BAAdditionOperator class]]?[[[BAAdditionOperator alloc] init]autorelease]:[[[BADivisionOperator alloc] init] autorelease];
			
			// if the parent is an additionoperator, we need to reverse the sign of the node
			if([aParent isKindOfClass:[BAAdditionOperator class]]) {
				theNode = [self _changeSignOfNode:theNode];
                (void)theNode;
            }
		}
		else if([aParent isKindOfClass:[BADivisionOperator class]])
		{	
			[aParent removeChild:theNode];
			[aParent removeRedundantOperatorIfNeeded];
			
			aResultingOperator = [[[BAMultiplicationOperator alloc] init] autorelease];
		}
	}
	return aResultingOperator;
}


- (void)_insertNode:(BAExpression*)theNode1 beforeNode:(BAExpression*)theNode2
{	
	
	if(		theNode1 == nil
	   ||	theNode2 == nil)
	{
		[NSException raise:@"NSExpressionTree" format:@"insertNode:beforeNode: invalid argument - theNode1 or theNode2 is nil"];	
		return;
	}
	
	BAExpression * aParent = [theNode2 parent];
	if(aParent == nil)
	{
		[NSException raise:@"NSExpressionTree" format:@"insertNode:beforeNode: - couldn't insert, theNode2 has no parent"];
		return;
	}	
	
	if([[aParent children] containsObject:theNode1])
	{
		[NSException raise:@"NSExpressionTree" format:@"insertNode:beforeNode: - couldn't insert, theNode1 is already inserted, try a \'move\' instead"];
		return;		
	}
	
	NSInteger anInsertIndex = [[aParent children] indexOfObject:theNode2];	
	if(anInsertIndex != NSNotFound)
	{
		[aParent insertChild:theNode1 atIndex:anInsertIndex];
	}
	else
		[NSException raise:@"NSExpressionTree" format:@"insertNode:beforeNode: - couldn't insert, no insertion index was found"];
}

- (void)_insertNode:(BAExpression*)theNode1 afterNode:(BAExpression*)theNode2
{	
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	if(		theNode1 == nil
	   ||	theNode2 == nil)
	{
		[NSException raise:@"NSExpressionTree" format:@"insertNode:afterNode: invalid argument - theNode1 or theNode2 is nil"];	
		return;
	}
	
	BAExpression * aParent = [theNode2 parent];
	if(aParent == nil)
	{
		[NSException raise:@"NSExpressionTree" format:@"insertNode:afterNode: - couldn't insert, theNode2 has no parent"];
		return;
	}	
	
	if([[aParent children] containsObject:theNode1])
	{
		[NSException raise:@"NSExpressionTree" format:@"insertNode:beforeNode: - couldn't insert, theNode1 is already inserted, try a \'move\' instead"];
		return;		
	}	
	
	NSInteger anInsertIndex = [[aParent children] indexOfObject:theNode2];	
	if(anInsertIndex != NSNotFound)
	{
		anInsertIndex++;
		if(anInsertIndex <= [[aParent children] count])
		{
			[aParent insertChild:theNode1 atIndex:anInsertIndex];
		}
		else
			[NSException raise:@"NSExpressionTree" format:@"insertNode:afterNode: - couldn't insert, no valid insertion index was found"];
	}
	else
		[NSException raise:@"NSExpressionTree" format:@"insertNode:afterNode: - couldn't insert, no insertion index was found"];	
}

- (BOOL)_node:(BAExpression*)theNode1 isInSameExpressionAs:(BAExpression*)theNode2
{
	if([[self root] isKindOfClass:[BAEqualsOperator class]])
	{
		// we consider the equlity operator to be a part of both sides
		if([self root] == theNode2)
			return YES;
		
		// the expression tree is only broken up into two expressions
		// when the root is an equality operator
		BAExpression * aRightExpression = [[[self root] children] objectAtIndex:1];
		BAExpression * aLeftExpression = [[[self root] children] objectAtIndex:0];
		if([theNode1 isDescendantOf:aRightExpression])
		{
			if([theNode2 isDescendantOf:aRightExpression])
				return YES;
			return NO;
		}
		if([theNode1 isDescendantOf:aLeftExpression])
		{
			if([theNode2 isDescendantOf:aLeftExpression])
				return YES;
			return NO;
		}
	}
	return YES;
}

- (BAExpression*)_changeSignOfNode:(BAExpression*)theNode
{
	// this returns the same object with the content changed
	// it is only used when moving nodes across an equality operator
	
	// in the case of an integer expression, change the int value
	if([theNode isKindOfClass:[BAInteger class]])
	{
		NSInteger anIntValue = [(BAInteger*)theNode intValue];
		anIntValue = 0-anIntValue;
		[(BAInteger*)theNode setIntValue:anIntValue];
		return theNode;
	}
	
	// in th case of a variable, we change the sign of the multiplier
	if([theNode isKindOfClass:[BAVariable class]])
	{
		NSInteger anInt = [(BAVariable*)theNode multiplierIntValue];
		anInt = 0-anInt;
		[(BAVariable*)theNode setMultiplierIntValue:anInt];
		return theNode;
	}
	
	// in the case of a power operator, I *think* we change the sign of the base value
	if([theNode isKindOfClass:[BAPowerOperator class]])
	{
		// I want to verify the proper thing to do here before coding it up
		[NSException raise:@"BAExpressionTree" format:@"changeSignOfNode: - changing the sign of a power operator is not implemented yet."];
		return nil;
	}
	return nil;
}



- (void)_removeNode:(BAExpression*)theNode
{
	if(theNode == [self root])
	{
		// this creates an empty tree
		// which is a bit pointless...
		[self setRoot:nil];
	}
	
	if([self containsNode:theNode])
	{
		BAExpression * aParent = [theNode parent];
		[aParent removeChild:theNode];
	}
	else
		[NSException raise:@"BAExpressionTree" format:@"cannot remove node - node is not in tree"];
	
}



#pragma mark -
#pragma mark ExpressionTree Element Protocol
- (id<BAExpressionTreeElement>)parent
{
	return nil;
}

- (NSArray*)children
{
	return [NSArray arrayWithObject:[self root]];
}

- (NSInteger)nodeCount
{
	if([self root]==nil)
		return 0;
	
	NSInteger aCount = 1;
	for(BAExpression* aNode in [[self root] children])
		aCount+=[aNode nodeCount];
	return aCount;
}

- (NSArray*)flatten
{
	BAExpression * aRoot = [self root];
	if(aRoot == nil)
		return nil;
	else 
		return [aRoot flatten];
}

- (BOOL)containsNode:(BAExpression*)theNode
{
	if(theNode == [self root])
		return YES;
	
	for(BAExpression* aChild in [[self root] children])
	{
		if([aChild containsNode:theNode])
			return YES;
	}
	return NO;
}

- (NSArray*)leafNodes
{
	NSMutableArray * aLeafNodes = [NSMutableArray array];
	if([[self root] isLiteral])
		[aLeafNodes addObject:self];
	else
	{
		for(BAExpression * aChild in [[self root] children])
			[aLeafNodes addObjectsFromArray:[aChild leafNodes]];
	}
	return [[aLeafNodes copy] autorelease];
}

- (void)replaceChild:(BAExpression *)theChildToReplace withChild:(BAExpression *)theNewChild
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	if(theChildToReplace == [self root])
		[self setRoot:theNewChild];
	else
		[NSException raise:@"BAExpressionTree" format:@"replaceChild:withChild: - original child must be root of the tree"];
	
	[self _prune];
	[self validate];
}


#pragma mark -
#pragma mark Evaluating
- (BOOL)canEvaluateNode:(BAExpression*)theNode
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	if(		[self containsNode:theNode] == NO
	   ||	[theNode canEvaluate] == NO)
		return NO;
	
	BAExpression*  aValue = [theNode cloneEvaluate];
	if(aValue == nil)
		return NO;
	
	return YES;
}

- (BAExpression*)evaluateNode:(BAExpression*)theNode
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	
	// it is possible that the structure of the tree
	// will be different after calling 'evaluate' (see notes in multiplication operator and addition operator evaluate methods)
	// retain theNode
	[[theNode retain] autorelease];
	BAExpression * aResult = [theNode evaluate];
	
	// we don't have to do anyting if the result won't change the sturcture of the tree
	if(aResult == theNode)
		return nil;
	
	if(aResult == nil)
	{
		[NSException raise:@"BAExpressionTree" format:@"evaluateNode: - node cannot be evaluated"];
		return nil;
	}
	
	// replace the node with its result
	[self replaceNode:theNode withNode:aResult];
	
	return aResult;
}

- (BOOL)canEvaluate
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	return [[self root] canEvaluate];
}

- (BAExpression*)evaluate
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];

	return [[self root] evaluate];
}

- (BAExpressionTree*)cloneEvaluateNode:(BAExpression*)theNode;
{
	
	NSInteger aNodeIndex = [self _indexForNode:theNode];
	
	BAExpressionTree * aCopy = [[self copy] autorelease]; 
	BAExpression * aNodeToEvaluate = [aCopy _nodeAtIndex:aNodeIndex];
	[aCopy evaluateNode:aNodeToEvaluate];
	return aCopy;
}

- (BAExpression*)_nodeAtIndex:(NSInteger)theIndex
{
	NSArray * aFlattenedExpression = [self flatten];
	if([aFlattenedExpression indexIsValid:theIndex])
		return [aFlattenedExpression objectAtIndex:theIndex];
	return nil;
}

- (NSInteger)_indexForNode:(BAExpression*)theNode
{
	NSArray * aFlattenedExpression = [self flatten];
	for(NSInteger i = 0;i < [aFlattenedExpression count]; i++)
	{
		if(theNode == [aFlattenedExpression objectAtIndex:i])
		{
			return i;
		}
	}
	return NSNotFound;
}


- (BAExpression*)evaluateTree
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	// we can't evalute a tree that has an equality as the root
	if([[self root] isKindOfClass:[BAEqualsOperator class]])
		return nil;
	
	[[self root] setFullEvaluate:YES];
	BAExpression * aResult = [[self root] recursiveEvaluate];
	[[self root] setFullEvaluate:NO];
	return aResult;
}

- (BAExpressionTree*)cloneEvaluateTree
{
	BAExpressionTree * aCopy = [[self copy] autorelease];
	BAExpression * aResult = [aCopy evaluateTree];
	if(aResult)
		[aCopy setRoot:aResult];
	
	
	
	if([aCopy validate] == NO)
		[NSException raise:@"BAExpressionTree" format:@"cloneEvaluateTree - result is not a valid expresion tree"];
	return aCopy;
}

- (NSString*)xmlStringValue
{
    NSMutableString *s=[NSMutableString stringWithFormat:@"<?xml version='1.0'?>\n"];
    [s appendString:@"<!DOCTYPE math PUBLIC '-//W3C//DTD MathML 2.0//EN' 'http://www.w3.org/TR/MathML2/dtd/mathml2.dtd'>\n"];
    [s appendString:@"<math xmlns='http://www.w3.org/1998/Math/MathML'>\n"];
    
    for(NSInteger i = 0; i < [[self children] count]; i++)
    {
        BAExpression * aChild = [[self children] objectAtIndex:i];
        [s appendString:[aChild xmlStringValueWithPad:@" "]];
    }
    
    [s appendString:@"</math>"];
    
    return s;
}

#pragma mark -
#pragma mark Pruning
- (void)_prune
{
	// when we _prune, we are looking for two things:
	// 1. operators with too many children, where we can add operators	
	// 2. operator redundancy in branches, where one operator's children can be merged with the parent's operator
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"_prune - root's parent is nil"];
	// first add any operators that we need
	// then remove any redundant operators
	[[self root] addOperatorIfNeeded];
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"_prune - root's parent is nill after adding operators"];
	[[self root] removeRedundantOperatorIfNeeded];
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"_prune - root's parent is nil after removing operators"];
}

- (void)replaceChildWithOnlyChild:(BAExpression*)theChild
{
	if([[self root] parent] != self)
		[NSException raise:@"BAExpressionTree" format:@"root's parent is not the tree."];
	
	// CS: caution here - this is only called by our root object, which we're going to release
	if([self root] == theChild)
	{
		BAExpression * anOnlyChild = nil;
		if([[theChild children] count] ==1)
			anOnlyChild = [[[[theChild children] objectAtIndex:0] retain] autorelease];
		else
			[NSException raise:@"BAExperssionTree" format:@"replaceChildWithOnlyChild: - there is more than one child or no children"];
		[[[self root] retain] autorelease];
		[self setRoot:anOnlyChild];
	}
}

- (NSString*)expressionString
{
	return [[self root] expressionString];
}

#pragma mark -
#pragma mark Validate
- (BOOL)validate
{
	if([[self root] parent] != self)
		return NO;
	
	BOOL aBool = [[self root] validate];
	if(!aBool)
		[NSException raise:@"BAExpressionTree" format:@"tree did not validate"];	

	return aBool;
}

@end
