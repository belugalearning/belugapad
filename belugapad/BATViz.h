//
//  BATViz.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BAExpression;
@class CCLayer;

@interface BATViz : NSObject
{
    
}

@property (retain) BAExpression *Root;
@property (retain) CCLayer *DrawLayer;
@property CGRect Bounds;

-(id)initWithExpr:(BAExpression*)expr andLayer:(CCLayer*)layer andBounds:(CGRect)bounds;
-(void)initDraw;
-(void)updateDrawIndicators;
-(void)scaleVizToBounds;


@end
