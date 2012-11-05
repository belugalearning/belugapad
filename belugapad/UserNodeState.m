//
//  UserNodeState.m
//  belugapad
//
//  Created by Nicholas Cartwright on 05/11/2012.
//
//

#import "UserNodeState.h"
#import "FMDatabase.h"

@interface UserNodeState()
{
    @private
    FMDatabase *db;
}
@property (nonatomic, readwrite, retain) NSString *userId;
@property (nonatomic, readwrite, retain) NSString *nodeId;
@property (nonatomic, readwrite) NSTimeInterval timePlayed;
@property (nonatomic, readwrite, retain) NSDate *lastPlayed;
@property (nonatomic, readwrite) int lastScore;
@property (nonatomic, readwrite) int totalAccumulatedScore;
@property (nonatomic, readwrite) int highScore;
@property (nonatomic, readwrite, retain) NSDate *artifact1LastAchieved;
@property (nonatomic, readwrite, retain) NSDate *artifact2LastAchieved;
@property (nonatomic, readwrite, retain) NSDate *artifact3LastAchieved;
@property (nonatomic, readwrite, retain) NSDate *artifact4LastAchieved;
@property (nonatomic, readwrite, retain) NSDate *artifact5LastAchieved;
@end


@implementation UserNodeState

-(id) initWithUserId:(NSString*)userId nodeId:(NSString*)nodeId database:(FMDatabase*)database
{
    [database open];
    FMResultSet *rs = [database executeQuery:@"SELECT * FROM Nodes WHERE id=?", nodeId];
    self = [rs next] ? [self initWithUserId:userId resultSet:rs database:database] : nil;
    [rs close];
    [database close];
    return self;
}

-(id) initWithUserId:(NSString*)userId resultSet:(FMResultSet*)rs database:(FMDatabase *)database
{
    self = [super init];
    if (self)
    {
        db = [database retain];
        
        self.userId = userId;
        self.nodeId = [rs stringForColumn:@"id"];
        self.timePlayed = [rs doubleForColumn:@"time_played"];
        
        double lp = [rs intForColumn:@"last_played"];
        if (lp > 0) self.lastPlayed = [NSDate dateWithTimeIntervalSince1970:lp];
        
        self.lastScore = [rs intForColumn:@"last_score"];
        self.totalAccumulatedScore = [rs intForColumn:@"total_accumulated_score"];
        self.highScore = [rs intForColumn:@"high_score"];
        
        NSTimeInterval artifact1Date = [rs doubleForColumn:@"artifact_1_last_achieved"];
        NSTimeInterval artifact2Date = [rs doubleForColumn:@"artifact_2_last_achieved"];
        NSTimeInterval artifact3Date = [rs doubleForColumn:@"artifact_3_last_achieved"];
        NSTimeInterval artifact4Date = [rs doubleForColumn:@"artifact_4_last_achieved"];
        NSTimeInterval artifact5Date = [rs doubleForColumn:@"artifact_5_last_achieved"];
        
        if (artifact1Date) self.artifact1LastAchieved = [NSDate dateWithTimeIntervalSince1970:artifact1Date];
        if (artifact2Date) self.artifact2LastAchieved = [NSDate dateWithTimeIntervalSince1970:artifact2Date];
        if (artifact3Date) self.artifact3LastAchieved = [NSDate dateWithTimeIntervalSince1970:artifact3Date];
        if (artifact4Date) self.artifact4LastAchieved = [NSDate dateWithTimeIntervalSince1970:artifact4Date];
        if (artifact5Date) self.artifact5LastAchieved = [NSDate dateWithTimeIntervalSince1970:artifact5Date];
        
    }
    return self;
}

@end