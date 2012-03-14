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
#import "global.h"

@interface ExprIOTests : GeneralTests

@end


@implementation ExprIOTests

-(void)testReadParse1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child");
}


-(void)testReadParseAndWrite1
{
    NSString *f=BUNDLE_FULL_PATH(@"/Problems/tools-dev/expr-tests/aplusbeq14.mathml");
    BAExpressionTree *tree=[BATio loadTreeFromMathMLFile:f];
    
    NSLog(@"root expression: %@", [[tree root] expressionString]);
    
    STAssertTrue([tree.root.children count] >0, @"tree should have more than one child and should be stringValue writable");
}


@end
