//
//  ContentService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BAExpressionTree, Problem, Syllabus;
@class CouchDatabase;

@interface ContentService : NSObject

@property (nonatomic, readonly, retain) Problem *currentProblem;
@property (nonatomic, readonly, retain) NSDictionary *currentPDef;
@property (nonatomic, readonly, retain) BAExpressionTree *currentPExpr;
@property (nonatomic, readonly, retain) Syllabus *defaultSyllabus;

-(id)initWithProblemPipeline:(NSString*)source;
-(void)gotoNextProblem;
-(CouchDatabase*)Database;

@end
