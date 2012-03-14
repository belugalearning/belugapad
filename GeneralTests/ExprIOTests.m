//
//  ExprIOTests.m
//  belugapad
//
//  Created by Gareth Jenkins on 14/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATio.h"
#import "BATQuery.h"
#import "global.h"

@interface ExprIOTests : GeneralTests

@end


@implementation ExprIOTests

-(void)testReadParse1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child -- a + b = 14");
}

-(void)testReadParse2
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/7plus7eq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child -- 7 + 7 = 14");
}

-(void)testVarSumEqual
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/7plus7eq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root (eq) should allow l to r comparison");
    
}

-(void)testVarSumNotEqual
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/7plus7eq15.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"tree root (eq) should fail l to r literal, evaluated comparison");
}

-(void)testVarSumNotPossible
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"tree root (eq) should not be possible with variables");
    
}

-(void)testVarSumWithSubstituions
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions");
    
}

-(void)testReadParseAndWrite1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    NSLog(@"root expression: %@", [[tree root] expressionString]);
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child and should be stringValue writable");
}


@end
