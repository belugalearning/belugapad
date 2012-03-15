//
//  IntegerLogicTests.m
//  Beluga Maths
//
//  Created by Richard Buckle on 20/02/2012.
//  Copyright (c) 2012 Beluga Learning Ltd. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"

@interface IntegerLogicTests : GeneralTests

@end


@implementation IntegerLogicTests

- (void)testProperties
{
    BAInteger *integerNode = [BAInteger integerWithIntValue:42];
    
    STAssertTrue([integerNode isLiteral], @"Integer node should be a literal");
    STAssertTrue([[integerNode expressionString] isEqualToString:@"42"], @"Integer stringValue should be 42, got %@", [integerNode expressionString]);
}

- (void)testEvaluation
{
    BAInteger *integerNode = [BAInteger integerWithIntValue:42];
    BAExpressionTree *tree = [BAExpressionTree treeWithRoot:integerNode];
    STAssertTrue([[integerNode evaluate] isEqualToExpression:[BAInteger integerWithIntValue:42]], @"Expression should evaluate to the correct value");
    
    STAssertTrue([tree validate], @"tree should be valid");
    STAssertTrue([tree canEvaluate], @"tree should be evaluatable");
    
    BAExpressionTree *evaluatedTree = [tree cloneEvaluateTree];
    STAssertTrue([evaluatedTree.root isLiteral], @"Expression should evaluate to a literal value");
    STAssertTrue([evaluatedTree.root isEqualToExpression:[BAInteger integerWithIntValue:42]], @"Expression should evaluate to the correct value");
}

- (void)testEquality {
    BAInteger *integerNode = [BAInteger integerWithIntValue:42];
    BAInteger *equalIntegerNode = [BAInteger integerWithIntValue:42];
    STAssertTrue([integerNode isEqualToExpression:equalIntegerNode], @"Two identical integers should evaluate as equal");
}

- (void)testInequality {
    BAInteger *integerNode = [BAInteger integerWithIntValue:42];
    BAInteger *differentIntegerNode = [BAInteger integerWithIntValue:43];
    STAssertFalse([integerNode isEqualToExpression:differentIntegerNode], @"Two different integers should not evaluate as equal");
    
    BAVariable *variableNode = [BAVariable variableWithName:@"a"];
    STAssertFalse([integerNode isEqualToExpression:variableNode], @"An integre and a variable should not evaluate as equal");
}

- (void)checkFactorisation:(NSInteger)intToTest expectedFactorCount:(NSInteger)expectedFactorCount {
    BAInteger *integerNode = [BAInteger integerWithIntValue:intToTest];
    
    NSArray *factors = [integerNode factors];
    STAssertTrue([factors count] == expectedFactorCount, @"%d should have %d factors, got %d", intToTest, expectedFactorCount, [factors count]);
    
    for (BAExpression *factor in factors) {
        STAssertTrue([factor validate], @"factor should be valid");
        STAssertTrue([factor isKindOfClass:[BAMultiplicationOperator class]], @"factor should be a multiplication expression");
        STAssertTrue([integerNode isEqualToExpression:[factor evaluate]], @"factor should evaluate to the original number");
    }
}

- (void)testFactorPositiveInteger {
    NSInteger intToTest = 36;
    // Factors are:
    // 1 × 36
    // 2 × 18
    // 3 × 12
    // 4 × 9
    // 6 × 6
    // 9 × 4
    // 12 × 3
    // 18 × 2
    // 36 × 1

    [self checkFactorisation:intToTest expectedFactorCount:9];
}

- (void)testFactorNegativeInteger {
    NSInteger intToTest = -36;
    // Factors are:
    // -1 × 36
    // 1 × -36
    // -2 × 18
    // 2 × -18
    // -3 × 12
    // 3 × -12
    // -4 × 9
    // 4 × -9
    // -6 × 6
    // 6 × -6
    // -9 × 4
    // 9 × -4
    // -12 × 3
    // 12 × -3
    // -18 × 2
    // 18 × -2
    // -36 × 1
    // 36 × -1
    
    [self checkFactorisation:intToTest expectedFactorCount:18];
}

- (void)testFactorPositivePrime {
    NSInteger intToTest = 17;
    // Factors are:
    // 1 × 17
    // 17 × 1
    
    [self checkFactorisation:intToTest expectedFactorCount:2];
}


@end
