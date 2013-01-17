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
    NSMutableArray *vars=[[[NSMutableArray alloc] init] autorelease];
    
    [self getDistinctVarNamesFrom:Tree.root withArray:vars];
    
    //sort this a-z
    vars = (NSMutableArray*)[vars sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
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
    //BAExpression *leval=[[[self.Root children] objectAtIndex:0] evaluate];
    //BAExpression *reval=[[[self.Root children] objectAtIndex:1] evaluate];
    
    //return [leval isEqualToExpression:reval];
    
    BAExpression *firstchild=[[[self.Root children] objectAtIndex:0] evaluate];
    NSLog(@"firstchild eval:\n%@", [firstchild xmlStringValueWithPad:@"  "]);

    //the result of each comparioson is anded with the cumulative result
    //a single child query will return YES
    BOOL evalResult=YES;
    
    //compare each child to the first
    for (int i=1; i<[[self.Root children] count]; i++) {
        BAExpression *thischild=[[[self.Root children] objectAtIndex:i] evaluate];
        NSLog(@"thischild eval:\n%@", [thischild xmlStringValueWithPad:@"  "]);
        evalResult=[firstchild isEqualToExpression:thischild] && evalResult;
    }
    
    return evalResult;
}

-(void)dealloc
{
    self.Root=nil;
    self.Tree=nil;
    [super dealloc];
}

@end
