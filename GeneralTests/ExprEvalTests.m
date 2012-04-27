//
//  ExprEvalTests.m
//  belugapad
//
//  Created by Gareth Jenkins on 11/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATio.h"
#import "BATQuery.h"
#import "global.h"

@interface ExprEvalTests : GeneralTests

@end

@implementation ExprEvalTests

-(void)testSingleEqualityComparison
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/1eq1.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"expression should be equal");
}

-(void)testThreeEqualityComparison
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/1eq1-chain3.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"expression should be equal");
}

-(void)testFiveEqualityComparison
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/1eq1-chain5.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"expression should be equal");
}

-(void)testFiveEqualityComparisonFailAt5
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/1eq1-chain5-notequal.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"expression should not be equal");
}

-(void)testFiveEqualityComparisonFailAt3
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/1eq1-chain5-notequal-at3.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"expression should not be equal");
}

-(void)testFiveEqualityComparisonFailAt1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/1eq1-chain5-notequal-at1.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"expression should not be equal");
}

-(void)testComaprisonOfTwoDivisions
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/2div4-eq-2div4.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"expression should be equal");    
}

-(void)testInequalityOfTwoDivisions1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/2div5-eq-2div4.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"expression should not be equal");    
}

-(void)testInequalityOfTwoDivisions2
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/3div14-eq-2div4.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"expression should not be equal");    
}

@end
