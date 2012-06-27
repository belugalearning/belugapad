//
//  UsersService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User, LoggingService;

@interface UsersService : NSObject

typedef enum {
    BL_USER_NICK_IS_AVAILABLE,
    BL_USER_NICK_IS_UNAVAILABLE,
    BL_USER_NICK_AVAILABILITY_UNCONFIRMED
} BL_USER_NICK_AVAILABILITY;

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (retain, nonatomic) NSDictionary *currentUser;

-(id)initWithProblemPipeline:(NSString*)source
           andLoggingService:(LoggingService*)ls;

-(NSArray*)deviceUsersByNickName;

-(void) nickNameIsAvailable:(NSString*)nickName callback:(void (^)(BL_USER_NICK_AVAILABILITY))callback;

-(NSDictionary*) getNewUserWithNickName:(NSString*)nickName
                            andPassword:(NSString*)password
                           andZubiColor:(NSData*)color // rgba
                      andZubiScreenshot:(UIImage*)image;

-(NSDictionary*) userMatchingNickName:(NSString*)nickName
                          andPassword:(NSString*)password;

-(void)addCompletedNodeId:(NSString*)nodeId;
-(BOOL)hasCompletedNodeId:(NSString*)nodeId;

-(void)syncDeviceUsers;

@end