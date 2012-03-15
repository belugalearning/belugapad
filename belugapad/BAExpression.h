//
//  BAExpression.h
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAExpressionTreeElementProtocol.h"

/*
 BAExpression is an abstract superclass for expression objects, which are the nodes of an "expression tree" (see BAExpressionTree)
 
 BAExpressions can be integers, variables, or operators.
 
 In a well-formed tree, integers and variables (which are "literal" objects) for the leaf nodes.  the rest of the tree
 is formed by operators
 */

@class BABracketOperator;
@interface BAExpression : NSObject<NSCopying, BAExpressionTreeElement>
{
	NSMutableArray *			mChildren;
	id<BAExpressionTreeElement>	wParent;	
@private
	BOOL	mFullEvaluate; // this is a bit of a hack which allows us to mutate the tree structure during a recursive evaluate which needs to repeaat an evalate operation
}

@property(nonatomic, readwrite, retain) NSMutableArray *children;
@property(nonatomic, readwrite, assign) id<BAExpressionTreeElement>parent;
@property (nonatomic, retain, readwrite) NSDictionary *metadata;

// managing the tree structure
- (void)addChild:(BAExpression*)theChild;
- (void)removeChild:(BAExpression*)theChild;
- (void)addChildren:(NSArray*)theChildren;
- (void)removeChildren:(NSArray*)theChildren;
- (void)insertChild:(BAExpression*)theChild atIndex:(NSUInteger)theIndex;
- (void)replaceChild:(BAExpression *)theChildToReplace withChild:(BAExpression *)theNewChild;

- (BAExpression*)leftChild;
- (BAExpression*)rightChild;
- (void)setLeftChild:(BAExpression*)theChild;
- (void)setRightChild:(BAExpression*)theChild;

- (BOOL)isDescendantOf:(BAExpression*)theExpression;
- (BOOL)isLiteral;

// value
- (NSString*)stringValue;
- (NSString*)expressionString;
- (NSString*)xmlStringValueWithPad:(NSString *)padding;


// evaluation
- (BAExpression*)cloneEvaluate; // evaluates a copy of the expression without mutating the expression itself (use this to check the result before actually evaluating the expresion)
- (BAExpression*)evaluate;
- (BAExpression*)recursiveEvaluate;

// metadata
- (id)metadataValueForKey:(NSString *)key;
- (void)setMetadataValue:(id)value forKey:(NSString *)key;
- (void)removeMetadataForKey:(NSString *)key;

// CS:??? Look into taking these out, it's not clear how they're supposed to behave
- (BOOL)isEqualToExpression:(BAExpression*)theOtherExpression;
- (BOOL)recursiveIsEqual:(BAExpression*)theOtherExpression;
@end


@interface BAExpression(BADeprecated)

- (BABracketOperator*)enclosingBracketOperator;

@end


@interface BAExpression(BAInternal)

@property(nonatomic, readwrite, assign) BOOL fullEvaluate; // will become BAInternal

// these are to help the 'pruning' and validation process 
- (NSInteger)childBalance;
- (BOOL)canBeReplacedByChild;
- (BOOL)canAddOperatorsForExtraChildren;
- (void)addOperatorIfNeeded;
- (void)removeRedundantOperatorIfNeeded;

@end

