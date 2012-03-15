//
//  BATQuery.h
//  belugapad
//
//  Created by Gareth Jenkins on 26/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAExpression;
@class BAExpressionTree;

@interface BATQuery : NSObject
{
    int maxDepth;
}

@property (retain) BAExpression *Root;
@property (retain) BAExpressionTree *Tree;

-(id)initWithExpr:(BAExpression*)expr;
-(id)initWithExpr:(BAExpression*)expr andTree:(BAExpressionTree*)tree;
-(int)getMaxDepth;
-(int)getNodeDepthFor:(BAExpression *)expr withParentDepth:(int)pdepth;

-(BOOL)assumeAndEvalEqualityAtRoot;
-(NSMutableArray*)getDistinctVarNames;

@end
