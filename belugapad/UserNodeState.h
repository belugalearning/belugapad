//
//  UserNodeState.h
//  belugapad
//
//  Created by Nicholas Cartwright on 05/11/2012.
//
//

#import <Foundation/Foundation.h>
@class FMDatabase, FMResultSet, NodePlay;

@interface UserNodeState : NSObject

@property (nonatomic, readonly, retain) NSString *userId;
@property (nonatomic, readonly, retain) NSString *nodeId;
@property (nonatomic, readonly) NSTimeInterval timePlayed;
@property (nonatomic, readonly, retain) NSDate *lastPlayed;
@property (nonatomic, readonly) int lastScore;
@property (nonatomic, readonly) int totalAccumulatedScore;
@property (nonatomic, readonly) int highScore;
@property (nonatomic, readonly, retain) NSDate *firstCompleted;
@property (nonatomic, readonly, retain) NSDate *lastCompleted;
@property (nonatomic, readonly, retain) NSDate *artifact1LastAchieved;
@property (nonatomic, readonly, retain) NSDate *artifact2LastAchieved;
@property (nonatomic, readonly, retain) NSDate *artifact3LastAchieved;
@property (nonatomic, readonly, retain) NSDate *artifact4LastAchieved;
@property (nonatomic, readonly, retain) NSDate *artifact5LastAchieved;
@property (nonatomic, readonly, retain) NSArray *assignmentFlags;

-(id)initWithUserId:(NSString*)userId nodeId:(NSString*)nodeId database:(FMDatabase*)database;
-(id)initWithUserId:(NSString*)userId resultSet:(FMResultSet*)rs database:(FMDatabase*)database;
-(void)updateStateFromNodePlay:(NodePlay*)nodePlay;
-(BOOL)saveState;

@end
