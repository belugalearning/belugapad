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

-(id)initWithExpr:(BAExpression*)expr
{
    if(self=[super init])
    {
        self.Root=expr;        
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

@end
