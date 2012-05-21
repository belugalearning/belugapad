//
//  ExprSimplifyTests.m
//  belugapad
//
//  Created by Gareth Jenkins on 20/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BADivisionOperator.h"
#import "BATio.h"
#import "BATQuery.h"
#import "global.h"

@interface ExprSimplifyTests : GeneralTests

@end

@implementation ExprSimplifyTests

-(BADivisionOperator *)buildDivisionWithDividend:(int) dividend andDivisor:(int) divisor
{
    BADivisionOperator *div=[BADivisionOperator operator];
    [div addChild:[BAInteger integerWithIntValue:dividend]];
    [div addChild:[BAInteger integerWithIntValue:divisor]];
    return div;
}

-(BOOL)doesDivision:(BAExpression*)div haveDividend:(int)dividend andDivisor:(int)divisor
{
    BAInteger *top=[[div children] objectAtIndex:0];
    BAInteger *bottom=[[div children] objectAtIndex:1];
    return ([top intValue]==dividend && [bottom intValue]==divisor);
}

-(void)testDivSimplifyToSame
{
    BADivisionOperator *d=[self buildDivisionWithDividend:1 andDivisor:2];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:1 andDivisor:2], @"didn't simplify");
}


-(void)testDivSimplify2over4
{
    BADivisionOperator *d=[self buildDivisionWithDividend:2 andDivisor:4];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:1 andDivisor:2], @"didn't simplify");
}

-(void)testDivSimplify3over6
{
    BADivisionOperator *d=[self buildDivisionWithDividend:3 andDivisor:6];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:1 andDivisor:2], @"didn't simplify");
}

-(void)testDivSimplify21over42
{
    BADivisionOperator *d=[self buildDivisionWithDividend:21 andDivisor:42];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:1 andDivisor:2], @"didn't simplify");
}

-(void)testDivSimplify4over2
{
    BADivisionOperator *d=[self buildDivisionWithDividend:4 andDivisor:2];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:2 andDivisor:1], @"didn't simplify");
}

-(void)testDivSimplify15over9
{
    BADivisionOperator *d=[self buildDivisionWithDividend:15 andDivisor:9];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:5 andDivisor:3], @"didn't simplify");
}

-(void)testDivSimplify28over60
{
    BADivisionOperator *d=[self buildDivisionWithDividend:28 andDivisor:60];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:7 andDivisor:15], @"didn't simplify");
}

-(void)testDivSimplify95over114
{
    BADivisionOperator *d=[self buildDivisionWithDividend:95 andDivisor:114];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:5 andDivisor:6], @"didn't simplify");
}

-(void)testDivSimplify2900over3000
{
    BADivisionOperator *d=[self buildDivisionWithDividend:2900 andDivisor:3000];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:29 andDivisor:30], @"didn't simplify");
}

-(void)testDivSimplify7over7
{
    BADivisionOperator *d=[self buildDivisionWithDividend:7 andDivisor:7];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:1 andDivisor:1], @"didn't simplify");
}

-(void)testDivSimplify1over1
{
    BADivisionOperator *d=[self buildDivisionWithDividend:1 andDivisor:1];
    [d simplifyIntegerDivision];
    STAssertTrue([self doesDivision:d haveDividend:1 andDivisor:1], @"didn't simplify");
}




@end
