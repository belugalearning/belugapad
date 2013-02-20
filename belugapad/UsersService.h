//
//  UsersService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User, LoggingService, FMDatabase, UserNodeState;

@interface UsersService : NSObject

typedef enum {
    BL_USER_CREATION_SUCCESS_NICK_AVAILABLE,
    BL_USER_CREATION_SUCCESS_NICK_AVAILABILITY_UNCONFIRMED,
    BL_USER_CREATION_FAILURE_NICK_UNAVAILABLE
} BL_USER_CREATION_STATUS;

typedef enum {
    BL_USER_NICK_CHANGE_ERROR,
    BL_USER_NICK_CHANGE_CONFLICT,
    BL_USER_NICK_CHANGE_SUCCESS
} BL_USER_NICK_CHANGE_RESULT;

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (readonly) NSDictionary *currentUserClone;
@property (readonly) FMDatabase *allUsersDatabase;
@property (readonly) NSString *currentUserId;
@property int lastStarAchieved;
@property int lastScoreAchieved;

-(id)initWithProblemPipeline:(NSString*)source
           andLoggingService:(LoggingService*)ls;

-(void)setCurrentUserToUserWithId:(NSString*)urId;

-(void)createNewUserWithNick:(NSString*)nick
                 andPassword:(NSString*)password
                    callback:(void (^)(BL_USER_CREATION_STATUS))callback;

-(void)changeCurrentUserNick:(NSString*)newNick
                    callback:(void(^)(BL_USER_NICK_CHANGE_RESULT))callback;

-(NSMutableArray*)deviceUsersByNickName;

-(void)flagRemoveUserFromDevice:(NSString*)userId;
-(void)syncDeviceUsers;

-(void)downloadUserMatchingNickName:(NSString*)nickName
                        andPassword:(NSString*)password
                           callback:(void (^)(NSDictionary*))callback;

-(void)applyDownloadedStateUpdatesForCurrentUser;

-(BOOL)hasCompletedNodeId:(NSString*)nodeId;
-(UserNodeState*)currentUserStateForNodeWithId:(NSString *)nodeId;
-(NSDictionary*)currentUserAllNodesState;

-(BOOL)hasEncounteredFeatureKey:(NSString*)key;
-(void)addEncounterWithFeatureKey:(NSString*)key date:(NSDate*)date;
-(void)notifyStartingFeatureKey:(NSString*)featureKey;

-(void)purgePotentialFeatureKeys;
-(NSString*)shouldInsertWhatFeatureKey;

@end
