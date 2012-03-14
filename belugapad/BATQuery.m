//
//  BATQuery.m
//  belugapad
//
//  Created by Gareth Jenkins on 26/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BATQuery.h"
#import "BAExpressionTree.h"
#import "BAExpressionHeaders.h"

@implementation BATQuery

@synthesize Root;
@synthesize Tree;

-(id)initWithExpr:(BAExpression *)expr
{
    return [self initWithExpr:expr andTree:nil];
}

-(id)initWithExpr:(BAExpression*)expr andTree:(BAExpressionTree*)tree
{
    if(self=[super init])
    {
        self.Root=expr;        
        
        if(tree) self.Tree=tree;
        else self.Tree=[BAExpressionTree treeWithRoot:expr];
    }
    
    return self;
}

-(int)getMaxDepth
{
    return [self getNodeDepthFor:self.Root withParentDepth:0];
}

-(int)getNodeDepthFor:(BAExpression *)expr withParentDepth:(int)pdepth
{
    if([[expr children] count]==0)
    {
        return pdepth+1;
    }
    else {
        int lmax=0;
        for (BAExpression *child in [expr children]) {
            int d=[self getNodeDepthFor:child withParentDepth:pdepth];
            if(d>lmax)lmax=d;
        }
        return pdepth+lmax+1;
    }
}

-(NSMutableArray*)getDistinctVarNames
{
    NSMutableArray *vars=[[NSMutableArray alloc] init];
    
    [self getDistinctVarNamesFrom:Tree.root withArray:vars];
    
    return vars;
}

-(void)getDistinctVarNamesFrom:(BAExpression *)expr withArray:(NSMutableArray*)array
{
    for (BAExpression *child in [expr children]) {
        if([child isKindOfClass:[BAVariable class]])
        {
            NSString *vname=[(BAVariable*)child name];
            if(![array containsObject:vname])
            {
                [array addObject:vname];
            }
        }
        else {
            [self getDistinctVarNamesFrom:child withArray:array];
        }
    }
}

-(BOOL)assumeAndEvalEqualityAtRoot
{
    //assumes root is equality and evaluates both sides and compares use l comp r
    BAExpression *leval=[[[self.Root children] objectAtIndex:0] evaluate];
    BAExpression *reval=[[[self.Root children] objectAtIndex:1] evaluate];
    
    return [leval isEqualToExpression:reval];
}

@end
