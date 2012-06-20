//
//  ProblemAttempt.m
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProblemAttempt.h"
#import "global.h"
#import "Problem.h"
#import "UserSession.h"
#import "JSONKit.h"

@interface ProblemAttempt()
{
@private
    NSMutableArray *events;
    NSMutableDictionary *doc;
    NSString *docPath;
}
-(NSString*)generateUUID;
@end

@implementation ProblemAttempt

-(NSString*) _id
{
    return (NSString*)[doc objectForKey:@"_id"];
}

-(id)initAndStartForUserSession:(UserSession*)userSession
                        problem:(Problem*)problem //parentAttemptId:(NSString*)parentAttemptId
                  generatedPDef:(NSDictionary*)pdef
           loggingDirectoryPath:(NSString*)loggingDirectoryPath
{
    self = [super init];
    if (self)
    {
        events = [NSMutableArray array];
        doc = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
               [self generateUUID], @"_id"
               , userSession.document.documentID, @"userSession"
               , @"ProblemAttempt", @"type"
               , problem._id, @"problemId"
               , problem._rev, @"problemRev"
               , events, @"events"
               , nil];
        
        if (pdef) [pdef writeToFile:[NSString stringWithFormat:@"%@/%@.pdef.plist", loggingDirectoryPath, self._id] atomically:NO];        
        docPath = [[NSString stringWithFormat:@"%@/%@.json", loggingDirectoryPath, self._id] retain];
        
        [self logEvent:BL_PA_START withAdditionalData:nil];
    }
    return self;
}


-(void)logEvent:(NSString*)eventType withAdditionalData:(NSObject*)additionalData;
{
    NSNumber *now = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
    NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  eventType, @"eventType"
                                  , now, @"date"
                                  , additionalData, @"additionalData", nil];
    [events addObject:event];
    
    NSData *docData = [doc JSONData];
    if (!docData)
    {
        [event setObject:@"JSON_SERIALIZATION_ERROR" forKey:@"additionalData"];
        docData = [doc JSONData];
    }
    
    NSError *error = nil;
    [docData writeToFile:docPath options:NSDataWritingAtomic error:&error];
    // TODO: Do something better with error
    if (error) NSLog(@"ERROR WRITING LOG FILE:%@", [error debugDescription]);
}
                       

-(NSString*)generateUUID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *uuid = [NSString stringWithFormat:@"%@", UUIDSRef];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
    
    return uuid;
}

-(void)dealloc
{
    [doc release];
    [docPath release];
    [super dealloc];
}

@end
