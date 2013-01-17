//
//  Pipeline.m
//  belugapad
//
//  Created by Gareth Jenkins on 08/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Pipeline.h"
#import "Problem.h"
#import "FMDatabase.h"
#import "JSONKit.h"
#import "global.h"
#import "AppDelegate.h"
#import "LoggingService.h"

@interface Pipeline()
{
@private
    FMDatabase *database;
}
@property (readwrite, nonatomic, retain) NSString *name;
@property (readwrite, nonatomic, retain) NSArray *problemIds;
@property (readwrite, nonatomic, retain) NSArray *flattenedProblems;
@end

@implementation Pipeline

@synthesize name;
@synthesize problemIds;
@synthesize flattenedProblems;

-(id)initWithDatabase:(FMDatabase*)db andPipelineId:(NSString*)plId
{
    database = [db retain];
    [db open];
    
    FMResultSet *rs = [database executeQuery:@"select * from Pipelines where id=?", plId];
    if ([rs next])
    {
        self = [super initWithFMResultSetRow:rs];
        if (self)
        {
            self.name = [rs stringForColumn:@"name"];
            self.problemIds = [[rs stringForColumn:@"problems"] objectFromJSONString];
            
            NSMutableArray *flattenedPrbs = [NSMutableArray array];
            NSMutableArray *repeatSetBuffer = [NSMutableArray array];
            NSString *currentRepeatSetTag = nil;
            
            for (NSString *prbId in self.problemIds)
            {
                
                Problem *p = [[[Problem alloc] initWithDatabase:database andProblemId:prbId] autorelease];
                if (!p) continue;
                
                // whatever the repeat tags, problem goes in at least once
                [flattenedPrbs addObject:p];
                
                NSString *rptSetTag = [p.pdef objectForKey:@"REPEAT_SET"];
                
                // unless this problem's REPEAT_SET tag is the same as the last, clear the buffer (i.e. potentially abandon set repeat)
                if (!rptSetTag || (currentRepeatSetTag && ![currentRepeatSetTag isEqualToString:rptSetTag])) [repeatSetBuffer removeAllObjects];
                
                currentRepeatSetTag = rptSetTag;
                
                if (rptSetTag)
                {
                    [repeatSetBuffer addObject:p];
                    
                    // REPEAT_MY_SET_MIN key ends set, and represents min total set presentations
                    NSNumber *setRepeatMin = [p.pdef objectForKey:@"REPEAT_MY_SET_MIN"];
                    if (setRepeatMin)
                    {
                        int setRepeats = [setRepeatMin integerValue] - 1;
                        for (int i=0; i<setRepeats; i++) [flattenedPrbs addObjectsFromArray:repeatSetBuffer];
                        currentRepeatSetTag = nil;
                    }
                }
                else
                {
                    NSNumber *rptScaffoldMin = [p.pdef objectForKey:@"REPEAT_AND_SCAFFOLD_MIN"];
                    NSNumber *rptAsIsMin = [p.pdef objectForKey:@"REPEAT_AS_IS_MIN"];
                    int rptMin = (rptScaffoldMin && [rptScaffoldMin integerValue] - 1) || (rptAsIsMin && [rptAsIsMin integerValue] - 1) || 0;
                    for (int i=0; i<rptMin; i++) [flattenedPrbs addObject:p];
                }
                
                self.flattenedProblems = [[flattenedPrbs copy] autorelease];
            }
        }
    }
    else
    {
        self = nil;
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_DB_TABLE_MISSING_ROW forKey:@"type"];
        [d setValue:@"Pipelines" forKey:@"table"];
        [d setValue:plId forKey:@"key"];
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        [ac.loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
    }
    
    [db close];
    return self;
}

-(void)dealloc
{
    if (database)
    {
        [database close];
        [database release];
    }
    self.name = nil;
    self.problemIds = nil;
    self.flattenedProblems = nil;
    [super dealloc];
}

@end
