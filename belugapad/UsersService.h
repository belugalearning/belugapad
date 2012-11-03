//
//  UsersService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User, LoggingService, FMDatabase;

@interface UsersService : NSObject

typedef enum {
    BL_USER_CREATION_SUCCESS_NICK_AVAILABLE,
    BL_USER_CREATION_SUCCESS_NICK_AVAILABILITY_UNCONFIRMED,
    BL_USER_CREATION_FAILURE_NICK_UNAVAILABLE
} BL_USER_CREATION_STATUS;

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (readonly) NSDictionary *currentUserClone;
@property (readonly) FMDatabase *usersDatabase;
@property (readonly) NSString *currentUserId;

-(id)initWithProblemPipeline:(NSString*)source
           andLoggingService:(LoggingService*)ls;

-(void)setCurrentUserToUserWithId:(NSString*)urId;

-(void)setCurrentUserToNewUserWithNick:(NSString*)nick
                           andPassword:(NSString*)password
                              callback:(void (^)(BL_USER_CREATION_STATUS))callback;

-(NSArray*)deviceUsersByNickName;

-(void)flagRemoveUserFromDevice:(NSString*)userId;
-(void)syncDeviceUsers;

-(void)downloadUserMatchingNickName:(NSString*)nickName
                        andPassword:(NSString*)password
                           callback:(void (^)(NSDictionary*))callback;

-(void)addCompletedNodeId:(NSString*)nodeId;
-(BOOL)hasCompletedNodeId:(NSString*)nodeId;

-(void)onNewLogBatchWithId:(NSString*)batchId;
@end
