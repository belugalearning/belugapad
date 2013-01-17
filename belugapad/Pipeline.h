//
//  Pipeline.h
//  belugapad
//
//  Created by Gareth Jenkins on 08/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CouchDBDerivedDocument.h"
@class FMDatabase;

@interface Pipeline : CouchDBDerivedDocument

@property (readonly, nonatomic, retain) NSString *name;
@property (readonly, nonatomic, retain) NSArray *problemIds;
@property (readonly, nonatomic, retain) NSArray *flattenedProblems;

-(id)initWithDatabase:(FMDatabase*)db andPipelineId:(NSString*)pId;

@end
