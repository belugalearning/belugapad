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

-(void)testVarSumWithSubstituions1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions");
    
}

-(void)testVarSumWithSubstituions2
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:11] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:3] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions that are different");
    
}

-(void)testVarSumWithPartialSubstituions
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"a"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"tree root equality should not be possible without full variable substitution");
}

-(void)testVarSumWithIncorrectSubstituions
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:3] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:16] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertFalse([q assumeAndEvalEqualityAtRoot], @"tree root equality should not be possible with incorrect variables and substitutions");
}

-(void)testVarSumWithSubstituionsOnCopy1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    tree=[tree copy];
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions on a copied tree");
    
}

-(void)testVarSumWithSubstituionsOnCopy2
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    tree=[tree copy];
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions after copy");
    
}

-(void)testVarSumWithSubstituionsOnCopy3
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:7] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    tree=[tree copy];
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions after copying sub-d tree");
    
}


-(void)testReadParseAndWriteToString
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    NSLog(@"root expression: %@", [[tree root] expressionString]);
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child and should be stringValue writable");
}

-(void)testReadParseAndWriteToXML
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    NSLog(@"xml expression: %@", [[tree root] xmlStringValueWithPad:@""]);
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child and should be xmlStringValue writable");
}

-(void)testReadParseAndWriteToXMLAndReadAgainAndSubstituteAndEvaluate
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    NSString *o=[tree xmlStringValue];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *file = [documentsDirectory stringByAppendingPathComponent:@"test-output-for-test.mathml"];
    
    [o writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    BAExpressionTree *newtree=[BATio loadTreeFromMathMLFile:file];
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:3] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:11] forKey:@"b"];
    
    newtree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [newtree substitueVariablesForIntegersOnNode:newtree.root];
    
    STAssertTrue([newtree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:newtree.root andTree:newtree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions after save, reload, subs");
}

-(void)testReadParseAndWriteToXMLAndReadAgainWithLiterals
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/7plus7eq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    NSString *o=[tree xmlStringValue];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *file = [documentsDirectory stringByAppendingPathComponent:@"test-output-for-test.mathml"];
    
    [o writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    BAExpressionTree *newtree=[BATio loadTreeFromMathMLFile:file];
        
    STAssertTrue([newtree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:newtree.root andTree:newtree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with literals and reload through xml");
}



-(void)testVarSubstitutedStringToXML
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    //create the substitutions and add to the tree
    NSMutableDictionary *subs=[[NSMutableDictionary alloc]init];
    [subs setObject:[NSNumber numberWithInt:3] forKey:@"a"];
    [subs setObject:[NSNumber numberWithInt:11] forKey:@"b"];
    
    tree.VariableSubstitutions=(NSDictionary*)subs;
    
    //execute the substitutions
    [tree substitueVariablesForIntegersOnNode:tree.root];
    
    NSLog(@"xml expression: %@", [[tree root] xmlStringValueWithPad:@""]);
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    STAssertTrue([q assumeAndEvalEqualityAtRoot], @"tree root equality should be possible with variables and substitutions and writing to xmlstring");
    
}

-(void)testVariableNameQueryCount
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    
    NSMutableArray *varnames=[q getDistinctVarNames];
    
    STAssertTrue([varnames count]==2, @"count of unique vars should be two");
    
}

-(void)testVariableNameQueryCountWithDuplicates
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbbyaeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
    
    BATQuery *q=[[BATQuery alloc] initWithExpr:tree.root andTree:tree];
    
    NSMutableArray *varnames=[q getDistinctVarNames];
    
    STAssertTrue([varnames count]==2, @"count of unique vars should be two (distinct)");
    
}

-(void)testReadParseAndWriteToXMLdocString
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    NSLog(@"xml string document: \n%@", [tree xmlStringValue]);
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child and should be xmlStringValue writable to document");
}

@end
