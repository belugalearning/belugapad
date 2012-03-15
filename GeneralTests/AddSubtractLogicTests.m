//
//  AddSubtractLogicTests.m
//  Beluga Maths
//
//  Created by Richard Buckle on 13/02/2012.
//  Copyright (c) 2012 Beluga Learning Ltd. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"

@interface AddSubtractLogicTests : GeneralTests

@end


@implementation AddSubtractLogicTests

- (BAExpressionTree *)treeByAdding:(BAExpression *)lhs to:(BAExpression *)rhs {
    BAAdditionOperator *additionNode = [BAAdditionOperator operator];
    [additionNode addChild:lhs];
    [additionNode addChild:rhs];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:additionNode];
    return tree;
}

- (void)testNumberAddition
{
    BAExpressionTree *tree = [self treeByAdding:[BAInteger integerWithIntValue:2] 
                                             to:[BAInteger integerWithIntValue:3]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([tree.root.children count] == 2, @"Original tree's root should still have two children");
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:5]], @"Expression should evaluate to the correct value");

    [self checkRootIsCommutative:tree];
}

- (void)testInvalidAddition
{
    BAExpressionTree *tree = [self treeByAdding:[BAInteger integerWithIntValue:2] 
                                             to:nil];
    
    // TODO: not sure validation failure should throw
    
//TODO: disabled to allow for breakpoint exceptions w/out throws
//    STAssetThrows([tree validate], @"tree should not be valid");
    STAssertFalse([tree canEvaluate], @"tree should not be evaluatable");

//TODO: disabled to allow for breakpoint exceptions w/out throws    
//    STAssertThrows([tree cloneEvaluateTree], @"invalid tree should throw when evaluated");
}

- (void)testPreAddZero
{
    BAExpressionTree *tree = [self treeByAdding:[BAInteger integerWithIntValue:0] 
                                             to:[BAVariable variableWithName:@"x"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([tree.root.children count] == 2, @"Original tree's root should still have two children");
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAVariable variableWithName:@"x"]], @"Expression should evaluate to the correct value");
    
    [self checkRootIsCommutative:tree];
}

- (void)testPostAddZero
{
    BAExpressionTree *tree = [self treeByAdding:[BAVariable variableWithName:@"x"] 
                                             to:[BAInteger integerWithIntValue:0]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([tree.root.children count] == 2, @"Original tree's root should still have two children");
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAVariable variableWithName:@"x"]], @"Expression should evaluate to the correct value");
    
    [self checkRootIsCommutative:tree];
}

- (void)testTripleAddition
{
    BAAdditionOperator *additionNode = [BAAdditionOperator operator];
    BAAdditionOperator *innerAdditionNode = [BAAdditionOperator operator];
    [innerAdditionNode addChild:[BAInteger integerWithIntValue:3]];
    [innerAdditionNode addChild:[BAInteger integerWithIntValue:4]];
    [additionNode addChild:[BAInteger integerWithIntValue:2]];
    [additionNode addChild:innerAdditionNode];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:additionNode];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([tree.root.children count] == 2, @"Original tree's root should still have two children");
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:9]], @"Expression should evaluate to the correct value");
    
    // TODO: fails [self checkRootIsCommutative:tree];
}

- (void)testAdditionToVariable
{
    BAExpressionTree *tree = [self treeByAdding:[BAInteger integerWithIntValue:2] 
                                             to:[BAVariable variableWithName:@"x"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue(![tree canEvaluate], @"tree should not be evaluatable");
    
    [self checkRootIsCommutative:tree];
}

- (void)testAdditionOfTwoVariables
{
    BAExpressionTree *tree = [self treeByAdding:[BAVariable variableWithName:@"x"] 
                                             to:[BAVariable variableWithName:@"y"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertFalse([tree canEvaluate], @"tree should not be evaluatable");
    
    [self checkRootIsCommutative:tree];
}

- (void)testAdditionOfSameVariables
{
    BAExpressionTree *tree = [self treeByAdding:[BAVariable variableWithName:@"x"] 
                                             to:[BAVariable variableWithName:@"x"]];
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    BAMultiplicationOperator *muliply2byX = [BAMultiplicationOperator operator];
    [muliply2byX addChild:[BAInteger integerWithIntValue:2]];
    [muliply2byX addChild:[BAVariable variableWithName:@"x"]];
    STAssertTrue([evaluatedTree.root isEqualToExpression:[muliply2byX evaluate]], @"x+x should evaluate to 2x");
}

@end
