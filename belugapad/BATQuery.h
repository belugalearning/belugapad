//
//  BATQuery.h
//  belugapad
//
//  Created by Gareth Jenkins on 26/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAExpression;

@interface BATQuery : NSObject
{
    int maxDepth;
}

@property (retain) BAExpression *Root;

-(id)initWithExpr:(BAExpression*)expr;
-(int)getMaxDepth;
-(int)getNodeDepthFor:(BAExpression *)expr withParentDepth:(int)pdepth;

@end
