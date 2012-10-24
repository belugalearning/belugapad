//
//  Problem.h
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CouchDBDerivedDocument.h"
@class FMDatabase;

@interface Problem : CouchDBDerivedDocument

@property (readonly, retain) NSDictionary *pdef;
@property (readonly, retain) NSDictionary *lastSavedPDef;
@property (readonly, retain) NSArray *editStack;
@property (readonly) NSInteger stackCurrentIndex;
@property (readonly) NSInteger stackLastSaveIndex;

-(id)initWithDatabase:(FMDatabase*)db andProblemId:(NSString*)pId;

-(void) updatePDef:(NSString*)pdef
      andEditStack:(NSString*)editStack
 stackCurrentIndex:(NSInteger)stackCurrentIndex
stackLastSaveIndex:(NSInteger)stackLastSaveIndex;

-(void) updateOnSaveWithRevision:(NSString*)rev;

@end
