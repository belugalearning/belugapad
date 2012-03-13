//
//  DivisionLogicTests.m
//  Beluga Maths
//
//  Created by Richard Buckle on 21/02/2012.
//  Copyright (c) 2012 Beluga Learning Ltd. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"

@interface DivisionLogicTests : GeneralTests

@end

@implementation DivisionLogicTests

- (BAExpressionTree *)treeByDividing:(BAExpression *)lhs by:(BAExpression *)rhs {
    BADivisionOperator *divNode = [BADivisionOperator operator];
    [divNode addChild:lhs];
    [divNode addChild:rhs];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:divNode];
    return tree;
}

- (void)testDivideIntegerByInteger
{
    BAExpressionTree *tree = [self treeByDividing:[BAInteger integerWithIntValue:42] 
                                               by:[BAInteger integerWithIntValue:3]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:14]], @"Expression should evaluate to the correct value");
}

- (void)testDivideIntegerByZero
{
    BAExpressionTree *tree = [self treeByDividing:[BAInteger integerWithIntValue:42] 
                                               by:[BAInteger integerWithIntValue:0]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertFalse([tree canEvaluate], @"tree should not be evaluatable");
}

- (void)testDivideVariableByZero
{
    BAExpressionTree *tree = [self treeByDividing:[BAVariable variableWithName:@"x"] 
                                               by:[BAInteger integerWithIntValue:0]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertFalse([tree canEvaluate], @"tree should not be evaluatable");
}

- (void)testDivideVariableByItself
{
    BAExpressionTree *tree = [self treeByDividing:[BAVariable variableWithName:@"x"] 
                                               by:[BAVariable variableWithName:@"x"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:1]], @"Expression should evaluate to the correct value");
}

@end
