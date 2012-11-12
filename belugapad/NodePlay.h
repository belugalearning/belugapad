//
//  NodePlay.h
//  belugapad
//
//  Created by Nicholas Cartwright on 07/11/2012.
//
//

#import <Foundation/Foundation.h>
@class FMResultSet;

@interface NodePlay : NSObject

@property (nonatomic, readonly, retain) NSString *episodeId;
@property (nonatomic, readonly, retain) NSString *batchId;
@property (nonatomic, readonly, retain) NSString *userId;
@property (nonatomic, readonly, retain) NSString *nodeId;
@property (nonatomic, readonly) double startDate;
@property (nonatomic, readonly) double lastEventDate;
@property (nonatomic, readonly) double endedPausesTime;
@property (nonatomic, readonly) double currentPauseStartDate;
@property (nonatomic, readonly, retain) NSNumber *score;
@property (nonatomic, readonly) double pauseTime;
@property (nonatomic, readonly) double playTime;


-(id)initFromFMResultSet:(FMResultSet*)rs;
-(id)initWithEpisode:(NSDictionary*)episode batchId:(NSString*)batchId;
-(BOOL)processEvent:(NSDictionary*)event error:(NSError**)error;

@end
