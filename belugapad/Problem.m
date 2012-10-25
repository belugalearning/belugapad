//
//  Problem.m
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Problem.h"
#import "CouchDBDerivedDocument.h"
#import "FMDatabase.h"
#import "JSONKit.h"

@interface Problem()
{
    @private
    FMDatabase *database;
}
@property (readwrite, retain) NSString *_rev;
@property (readwrite, retain) NSDictionary *pdef;
@property (readwrite, retain) NSString *lastSavedPDef; // json dictionary
@property (readwrite, retain) NSString *changeStack; // json array
@property (readwrite) NSInteger stackCurrentIndex;
@property (readwrite) NSInteger stackLastSaveIndex;
@end


@implementation Problem

-(id)initWithDatabase:(FMDatabase*)db andProblemId:(NSString*)pId
{
    database = [db retain];
    [db open];
    FMResultSet *rs = [database executeQuery:@"select * from Problems where id=?", pId];
    
    if ([rs next])
    {
        self = [super initWithFMResultSetRow:rs];
        if (self)
        {
            self.pdef = [[rs stringForColumn:@"pdef"] objectFromJSONString];
            self.lastSavedPDef = [rs stringForColumn:@"pdef"];
            self.changeStack = [rs stringForColumn:@"change_stack"];
            self.stackCurrentIndex = [rs intForColumn:@"stack_current_index"];
            self.stackLastSaveIndex = [rs intForColumn:@"stack_last_save_index"];
        }
    }
    else
    {
        self = nil;
    }
    [db close];
    return self;
}

-(BOOL)hasUnsavedEdits
{
    return self.stackCurrentIndex != self.stackLastSaveIndex;
}

-(void) updatePDef:(NSDictionary*)pdef
    andChangeStack:(NSString*)changeStack
 stackCurrentIndex:(NSInteger)stackCurrentIndex
stackLastSaveIndex:(NSInteger)stackLastSaveIndex
{
    self.pdef = pdef;
    self.changeStack = changeStack;
    self.stackCurrentIndex = stackCurrentIndex;
    self.stackLastSaveIndex = stackLastSaveIndex;
    
    [database open];
    [database executeUpdate:@"UPDATE Problems SET pdef=?, change_stack=?, stack_current_index=?, stack_last_save_index=? WHERE id=?", [pdef JSONString], changeStack, [NSNumber numberWithInt:stackCurrentIndex], [NSNumber numberWithInt:stackLastSaveIndex], self._id];
    [database close];
    
}

-(void) updateOnSaveWithRevision:(NSString*)rev
{
    self._rev = nil;
    self.lastSavedPDef = [self.pdef JSONString];
    self.stackLastSaveIndex = self.stackCurrentIndex;
    [database open];
    [database executeUpdate:@"UPDATE Problems SET _rev=?, last_saved_pdef=?, stack_last_save_index=? WHERE id=?", rev, self.lastSavedPDef, [NSNumber numberWithInt:self.stackLastSaveIndex], self._id];
    [database close];
}

-(void)dealloc
{
    if (database)
    {
        [database close];
        [database release];
    }
    self.pdef = nil;
    self.lastSavedPDef = nil;
    self.changeStack = nil;
    [super dealloc];
}

@end
