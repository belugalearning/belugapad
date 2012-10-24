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
@property (readwrite, retain) NSDictionary *lastSavedPDef;
@property (readwrite, retain) NSArray *editStack;
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
            self.lastSavedPDef = [[rs stringForColumn:@"pdef"] objectFromJSONString];
            self.editStack = [[rs stringForColumn:@"edit_stack"] objectFromJSONString];
            self.stackCurrentIndex = [rs intForColumn:@"stack_current_index"];
            self.stackLastSaveIndex = [rs intForColumn:@"stack_last_save_index"];
        }
    }
    [db close];
    return self;
}

-(void) updatePDef:(NSString*)pdef
      andEditStack:(NSString*)editStack
 stackCurrentIndex:(NSInteger)stackCurrentIndex
stackLastSaveIndex:(NSInteger)stackLastSaveIndex
{
    self.pdef = [pdef objectFromJSONString];
    self.editStack = [editStack objectFromJSONString];
    self.stackCurrentIndex = stackCurrentIndex;
    self.stackLastSaveIndex = stackLastSaveIndex;
    
    [database open];
    [database executeUpdate:@"UPDATE Problems SET pdef=?, edit_stack=?, stack_current_index=?, stack_last_save_index=? WHERE id=?", pdef, editStack, stackCurrentIndex, stackLastSaveIndex, self._id];
    [database close];
    
}

-(void) updateOnSaveWithRevision:(NSString*)rev
{
    self._rev = nil;
    self.lastSavedPDef = self.pdef;
    self.stackLastSaveIndex = self.stackCurrentIndex;
    [database open];
    [database executeUpdate:@"UPDATE Problems SET _rev=?, stack_last_save_index=? WHERE id=?", rev, self.stackLastSaveIndex, self._id];
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
    self.editStack = nil;
    [super dealloc];
}

@end
