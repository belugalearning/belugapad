//
//  PowerLogicTests.m
//  Beluga Maths
//
//  Created by Richard Buckle on 21/02/2012.
//  Copyright (c) 2012 Beluga Learning Ltd. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"

@interface PowerLogicTests : GeneralTests

@end

@implementation PowerLogicTests

- (BAExpressionTree *)treeRaising:(BAExpression *)lhs toThePowerOf:(BAExpression *)rhs {
    BAPowerOperator *powerNode = [BAPowerOperator operator];
    [powerNode addChild:lhs];
    [powerNode addChild:rhs];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:powerNode];
    return tree;
}

- (void)testNumberExponentiation
{
    BAExpressionTree *tree = [self treeRaising:[BAInteger integerWithIntValue:2] 
                                  toThePowerOf:[BAInteger integerWithIntValue:3]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    STAssertFalse([(id)tree.root isCommutative], @"Exponentation is not commutative");
    STAssertFalse([tree canMoveNode:tree.root.leftChild afterNode:tree.root.rightChild], @"cannot swap the arguments of the power operator");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:8]], @"Expression should evaluate to the correct value");
}

- (void)testNumberToPowerZero
{
    BAExpressionTree *tree = [self treeRaising:[BAInteger integerWithIntValue:2] 
                                  toThePowerOf:[BAInteger integerWithIntValue:0]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:1]], @"Expression should evaluate to the correct value");
}

- (void)testZeroToPowerZero
{
    BAExpressionTree *tree = [self treeRaising:[BAInteger integerWithIntValue:0] 
                                  toThePowerOf:[BAInteger integerWithIntValue:0]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertFalse([tree canEvaluate], @"tree should not be evaluatable");
}

- (void)testVariableToPowerZero
{
    BAExpressionTree *tree = [self treeRaising:[BAVariable variableWithName:@"x"] 
                                  toThePowerOf:[BAInteger integerWithIntValue:0]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:1]], @"Expression should evaluate to the correct value");
}

- (void)testZeroExpressionVariableToPowerZero
{
    BAMultiplicationOperator *zeroMultiplication = [BAMultiplicationOperator operator];
    [zeroMultiplication addChild:[BAVariable variableWithName:@"x"]];
    [zeroMultiplication addChild:[BAInteger integerWithIntValue:0]];
    BAExpressionTree *tree = [self treeRaising:zeroMultiplication 
                                  toThePowerOf:[BAInteger integerWithIntValue:0]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertFalse([tree canEvaluate], @"tree should not be evaluatable because identical to 0^0");
}


@end

