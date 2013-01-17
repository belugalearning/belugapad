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
@property (readonly, retain) NSString *lastSavedPDef; // json dictionary
@property (readonly, retain) NSString *changeStack; // json array
@property (readonly) NSInteger stackCurrentIndex;
@property (readonly) NSInteger stackLastSaveIndex;
@property (readonly) BOOL hasUnsavedEdits;

-(id)initWithDatabase:(FMDatabase*)db andProblemId:(NSString*)pId;

-(void) updatePDef:(NSString*)pdef
    andChangeStack:(NSString*)changeStack
 stackCurrentIndex:(NSInteger)stackCurrentIndex
stackLastSaveIndex:(NSInteger)stackLastSaveIndex;

-(void) updateOnSaveWithRevision:(NSString*)rev;

@end
