//
//  MultiplyLogicTests.m
//  Beluga Maths
//
//  Created by Richard Buckle on 20/02/2012.
//  Copyright (c) 2012 Beluga Learning Ltd. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"

@interface MultiplyLogicTests : GeneralTests

@end

@implementation MultiplyLogicTests

- (BAExpressionTree *)treeByMultiplying:(BAExpression *)lhs by:(BAExpression *)rhs {
    BAMultiplicationOperator *multNode = [BAMultiplicationOperator operator];
    [multNode addChild:lhs];
    [multNode addChild:rhs];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:multNode];
    return tree;
}

- (void)testNumberMultiplication
{
    BAExpressionTree *tree = [self treeByMultiplying:[BAInteger integerWithIntValue:2] 
                                                  by:[BAInteger integerWithIntValue:3]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([tree.root.children count] == 2, @"Original tree's root should still have two children");
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:6]], @"Expression should evaluate to the correct value");
    
    [self checkRootIsCommutative:tree];
}

- (void)testMultiplyIntegerByZero
{
    BAExpressionTree *tree = [self treeByMultiplying:[BAInteger integerWithIntValue:0] 
                                                  by:[BAInteger integerWithIntValue:42]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:0]], @"Expression should evaluate to the correct value");
}

- (void)testMultiplicationOfVariable
{
    BAExpressionTree *tree = [self treeByMultiplying:[BAInteger integerWithIntValue:2] 
                                                  by:[BAVariable variableWithName:@"x"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    // TODO: fails STAssertFalse([tree canEvaluate], @"tree should not be evaluatable");
    
    [self checkRootIsCommutative:tree];
}

- (void)testMultiplyVariableByZero
{
    BAExpressionTree *tree = [self treeByMultiplying:[BAInteger integerWithIntValue:0] 
                                                  by:[BAVariable variableWithName:@"x"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:0]], @"Expression should evaluate to the correct value");
}

- (void)testMultiplicationOfTwoVariables
{
    BAExpressionTree *tree = [self treeByMultiplying:[BAVariable variableWithName:@"x"] 
                                                  by:[BAVariable variableWithName:@"y"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue(![tree canEvaluate], @"tree should not be evaluatable");
    
    [self checkRootIsCommutative:tree];
}

- (void)testMoveRightIntoCommonDenominator {
    // test a * (b / c) identical to (a * b) / c
    BAVariable *varA = [BAVariable variableWithName:@"a"];
    BAVariable *varB = [BAVariable variableWithName:@"b"];
    BAVariable *varC = [BAVariable variableWithName:@"c"];
    
    BAMultiplicationOperator *multNode = [BAMultiplicationOperator operator];
    BADivisionOperator *divNode = [BADivisionOperator operator];
    [multNode addChild:varA];
    [divNode addChild:varB];
    [divNode addChild:varC];
    [multNode addChild:divNode];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:multNode];
    
    // TODO: fails STAssertTrue([tree canMoveNode:varA beforeNode:varC], @"a * (b / c) should be identical to (a * b) / c");
    [tree moveNode:varA beforeNode:varC];
    NSLog(@"%@", [[tree root] expressionString]);
}

- (void)testMoveLeftIntocommonDenominator {
    // test (a / b) * c identical to (a * c) / b
    BAVariable *varA = [BAVariable variableWithName:@"a"];
    BAVariable *varB = [BAVariable variableWithName:@"b"];
    BAVariable *varC = [BAVariable variableWithName:@"c"];
    
    BAMultiplicationOperator *multNode = [BAMultiplicationOperator operator];
    BADivisionOperator *divNode = [BADivisionOperator operator];
    [multNode addChild:divNode];
    [divNode addChild:varA];
    [divNode addChild:varB];
    [multNode addChild:varC];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:multNode];
    
    // TODO: fails STAssertTrue([tree canMoveNode:varC afterNode:varA], @"(a / b) * c should be identical to (a * c) / b");
    [tree moveNode:varC afterNode:varA];
    NSLog(@"%@", [[tree root] expressionString]);
}

@end
