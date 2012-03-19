//
//  ContentService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BAExpressionTree;

@interface ContentService : NSObject

@property (nonatomic, readonly, retain) NSDictionary *currentPDef;
@property (nonatomic, readonly, retain) BAExpressionTree *currentPExpr;

-(id)initWithProblemPipeline:(NSString*)source;
-(void)gotoNextProblem;

@end
