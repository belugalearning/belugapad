//
//  BATTreeViz.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BATViz.h"

@interface BATTreeViz : BATViz
{
    int maxDepth;
}

-(void)drawNode:(BAExpression*)node atDepth:(int)depth withParentX:(float)parentX andSiblingIndex:(int)siblingIndex;

@end
