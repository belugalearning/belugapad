//
//  untitled.h
//  Beluga
//
//  Created by Cathy Shive on 1/30/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

/*
CS: for the tree/node relationship to work some methods have to be implemented in both the tree and the node classes. 
*/

#import <Foundation/Foundation.h>

@class BAExpression;
@protocol BAExpressionTreeElement <NSObject, NSCopying>

- (id<BAExpressionTreeElement>)parent;
- (NSArray*)children;

- (BOOL)containsNode:(BAExpression*)theNode;
- (NSArray*)leafNodes;
- (NSInteger)nodeCount;
- (NSArray*)flatten;
- (NSString*)expressionString;

- (void)replaceChildWithOnlyChild:(BAExpression*)theChild; // maybe just replace this with the method below
- (void)replaceChild:(BAExpression*)theChildToReplace withChild:(BAExpression*)theNewChild;

- (BOOL)validate;

- (BOOL)canEvaluate;
- (BAExpression*)evaluate;

@end
