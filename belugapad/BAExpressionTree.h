//
//  BAExpressionTree.h
//  Beluga
//
//  Created by Cathy Shive on 1/30/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAExpressionTreeElementProtocol.h"
#import "BAExpressionHeaders.h"

@interface BAExpressionTree : NSObject <BAExpressionTreeElement>
{
	BAExpression *			mRoot;
}
@property(nonatomic, readwrite, retain) BAExpression * root;
/*
	treeWithRoot:
	returns autoreleased BAExpressionTree object.  Sets the root property to theRoot
*/
+(BAExpressionTree*)treeWithRoot:(BAExpression*)theRoot;

//used for variable evaluations
@property (retain) NSDictionary *VariableSubstitutions;

#pragma mark Mutating the tree
/*
	You can reorder the nodes in a tree using the appropriate method from the "moveNode:" API
	For example, take the expression:
	2 + 5 + 7
	You can move the "5" node before the "2" node, which will change the expression to 
	5 + 2 + 7
	
	The drag and drop code in the expression view uses this API to reorder the nodes in real-time
*/
- (BOOL)canMoveNode:(BAExpression*)theNode;
- (BOOL)canMoveNode:(BAExpression *)theNode1 beforeNode:(BAExpression*)theNode2;
- (BOOL)canMoveNode:(BAExpression *)theNode1 afterNode:(BAExpression*)theNode2;
- (void)moveNode:(BAExpression *)theNode1 beforeNode:(BAExpression *)theNode2;
- (void)moveNode:(BAExpression *)theNode1 afterNode:(BAExpression *)theNode2;
/*
	Insert theNode1 before or after theNode2
*/
- (void)insertNode:(BAExpression*)theNode1 beforeNode:(BAExpression*)theNode2;
- (void)insertNode:(BAExpression*)theNode1 afterNode:(BAExpression*)theNode2;
/*
	Remove nodes
*/
- (void)removeNodes:(NSArray*)theNodes;
- (void)removeNode:(BAExpression*)theNode;
/*
	Replace theNode1 with theNode2
*/
- (void)replaceNode:(BAExpression*)theNode1 withNode:(BAExpression*)theNode2;

//recusively replace variables with integers
-(void)substitueVariablesForIntegersOnNode:(BAExpression *)theNode;


#pragma mark Evaluating the tree
- (BOOL)canEvaluateNode:(BAExpression*)theNode;
- (BAExpression*)evaluateNode:(BAExpression*)theNode;
- (BAExpressionTree*)cloneEvaluateNode:(BAExpression*)theNode;
- (BAExpression*)evaluateTree;
- (BAExpressionTree*)cloneEvaluateTree;

- (NSInteger)sideOfEqualityForNode:(BAExpression*)theNode;

- (void)reverseSidesAroundEquality;

- (NSString*)xmlStringValue;

@end
