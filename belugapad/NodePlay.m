//
//  NodePlay.m
//  belugapad
//
//  Created by Nicholas Cartwright on 07/11/2012.
//
//

#import "NodePlay.h"
#import "global.h"
#import "AppDelegate.h"
#import "UsersService.h"
#import "LoggingService.h"
#import "FMDatabase.h"

@interface NodePlay()
{
    @private
    FMDatabase *activityDatabase;
}
@property (nonatomic, readwrite, retain) NSString *episodeId;
@property (nonatomic, readwrite, retain) NSString *batchId;
@property (nonatomic, readwrite, retain) NSString *userId;
@property (nonatomic, readwrite, retain) NSString *nodeId;
@property (nonatomic, readwrite) double startDate;
@property (nonatomic, readwrite) double lastEventDate;
@property (nonatomic, readwrite) double endedPausesTime;
@property (nonatomic, readwrite) double currentPauseStartDate;
@property (nonatomic, readwrite, retain) NSNumber *score;

@property (nonatomic, readwrite) BOOL isPaused;
@property (nonatomic, readwrite) BOOL isInBackground;

@end


@implementation NodePlay

@synthesize episodeId, batchId, userId, nodeId, startDate, lastEventDate, endedPausesTime, currentPauseStartDate, score;


-(id)initWithEpisode:(NSDictionary*)episode batchId:(NSString*)bId
{
    self = [super init];
    if (self)
    {
        self.episodeId = [episode valueForKey:@"_id"];
        self.batchId = bId;
        self.userId = [episode valueForKey:@"user"];
        self.nodeId = [episode valueForKey:@"nodeId"];
        self.score = @0;
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        activityDatabase = [ac.usersService.allUsersDatabase retain];
    }
    return self;
}

-(id)initFromFMResultSet:(FMResultSet*)rs
{
    self = [super init];
    if (self)
    {
        self.episodeId = [rs stringForColumn:@"episode_id"];
        self.batchId = [rs stringForColumn:@"batch_id"];
        self.userId = [rs stringForColumn:@"user_id"];
        self.nodeId = [rs stringForColumn:@"node_id"];
        self.startDate = [rs doubleForColumn:@"start_date"];
        self.lastEventDate = [rs doubleForColumn:@"last_event_date"];
        self.endedPausesTime = [rs doubleForColumn:@"ended_pauses_time"];
        self.currentPauseStartDate = [rs doubleForColumn:@"curr_pause_start_date"];
        self.score = @([rs intForColumn:@"score"]);
        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        activityDatabase = [ac.usersService.allUsersDatabase retain];
    }
    return self;
}

-(double)pauseTime
{
    double t = self.endedPausesTime;
    if (self.currentPauseStartDate) t += (self.lastEventDate - self.currentPauseStartDate);
    return t;
}

-(double)playTime
{
    return self.lastEventDate - self.startDate - self.pauseTime;
}

-(BOOL)processEvent:(NSDictionary*)event error:(NSError**)error
{
    NSString *eventType = [event valueForKey:@"eventType"];
    double eventDate = [[event valueForKey:@"date"] doubleValue];
    NSObject *eventData = [event objectForKey:@"additionalData"];
    
    if ([BL_EP_START isEqualToString:eventType]) self.startDate = eventDate;
    
    self.lastEventDate = eventDate;
    
    
    BOOL startPause = NO;
    if ([BL_PA_PAUSE isEqualToString:eventType])
    {
        self.isPaused = YES;
        if (!self.isInBackground) startPause = YES;
    }
    if ([BL_APP_ENTER_BACKGROUND isEqualToString:eventType])
    {
        self.isInBackground = YES;
        if (!self.isPaused) startPause = eventDate;
    }
    if (startPause) self.currentPauseStartDate = eventDate;
    
    BOOL endPause = NO;
    if ([BL_PA_RESUME isEqualToString:eventType])
    {
        self.isPaused = NO;
        if (!self.isInBackground) endPause = YES;
    }
    if ([BL_APP_ENTER_FOREGROUND isEqualToString:eventType])
    {
        self.isInBackground = NO;
        if (!self.isPaused) endPause = YES;
    }
    
    BOOL episodeEnded = [BL_EP_END isEqualToString:eventType] || ([BL_APP_ERROR isEqualToString:eventType] && eventData && [BL_APP_ERROR_TYPE_CRASH isEqualToString:[eventData valueForKey:@"type"]]);
    
    endPause = endPause || (self.currentPauseStartDate > 0 && episodeEnded);
    if (endPause)
    {
        self.endedPausesTime += (eventDate - self.currentPauseStartDate);
        self.currentPauseStartDate = 0;
    }
    
    NSString *errorMessage = nil;
    
    BOOL insertDb = [BL_EP_START isEqualToString:eventType];
    if (insertDb)
    {        
        [activityDatabase open];
        BOOL success = [activityDatabase executeUpdate:@"INSERT INTO NodePlays(episode_id, batch_id, user_id, node_id, start_date, last_event_date) VALUES(?,?,?,?,?,?)",
                                                                self.episodeId,
                                                                self.batchId,
                                                                self.userId,
                                                                self.nodeId,
                                                                @(self.lastEventDate),
                                                                @(self.lastEventDate)];
        [activityDatabase close];
        
        if (!success) errorMessage = [NSString stringWithFormat:@"SQL error. Failed INSERT INTO NodePlays. EpisodeId=%@", self.episodeId];
    }
    
    BOOL updateDb = episodeEnded || startPause || endPause || [BL_APP_ERROR isEqualToString:eventType];
    if (updateDb)
    {
        if ([BL_EP_END isEqualToString:eventType]) self.score = [eventData valueForKey:@"score"];
        
        [activityDatabase open];
        BOOL success = [activityDatabase executeUpdate:@"UPDATE NodePlays SET last_event_date=?, ended_pauses_time=?, curr_pause_start_date=?, score=? WHERE episode_id=?",
                                                                @(self.lastEventDate),
                                                                @(self.endedPausesTime),
                                                                @(self.currentPauseStartDate),
                                                                self.score,
                                                                self.episodeId];
        [activityDatabase close];
        
        if (!success) errorMessage = [NSString stringWithFormat:@"SQL error. Failed UPDATE NodePlays. EpisodeId=%@", self.episodeId];
    }
    
    if (errorMessage && error)
    {
        *error = [NSError errorWithDomain:@"NodePlay"
                                     code:0
                                 userInfo:@{@"type":BL_APP_ERROR_TYPE_SQL, NSLocalizedDescriptionKey:errorMessage}];
    }
    
    return episodeEnded;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"NodePlay: {\n\tepisodeId: %@\n\tbatchId: %@\n\tuserId: %@\n\tnodeId: %@\n\tstartDate: %f\n\tlastEventDate: %f\n\tendedPausesTime: %f\n\tcurrentPauseStartDate: %f\n\tscore: %d\n\tisPaused: %@\n\tisInBackground: %@\n}", self.episodeId, self.batchId, self.userId, self.nodeId, self.startDate, self.lastEventDate, self.endedPausesTime, self.currentPauseStartDate, [self.score intValue], (self.isPaused ? @"YES" : @"NO"), (self.isInBackground ? @"YES" : @"NO")];
}

-(void)dealloc
{
    self.episodeId = nil;
    self.batchId = nil;
    self.userId = nil;
    self.nodeId = nil;
    self.score = nil;
    if (activityDatabase)
    {
        [activityDatabase close];
        [activityDatabase release];
    }
    [super dealloc];
}

@end
