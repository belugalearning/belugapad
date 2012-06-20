//
//  UsersService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User, ProblemAttempt, CouchLiveQuery, CouchEmbeddedServer;

@interface UsersService : NSObject

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (retain, nonatomic) User *currentUser;
@property (readonly, retain) NSString *currentProblemAttemptID;

-(id)initWithProblemPipeline:(NSString*)source;

-(NSArray*)deviceUsersByLastSessionDate;
-(NSArray*)deviceUsersByNickName;

-(BOOL) nickNameIsAvailable:(NSString*)nickName;

-(User*) getNewUserWithNickName:(NSString*)nickName
                    andPassword:(NSString*)password
                   andZubiColor:(NSData*)color // rgba
              andZubiScreenshot:(UIImage*)image;

-(User*) userMatchingNickName:(NSString*)nickName
                  andPassword:(NSString*)password;

-(void)startProblemAttempt;
-(void)logEvent:(NSString*)event withAdditionalData:(NSObject*)additionalData;

-(void)addCompletedNodeId:(NSString*)nodeId;
-(BOOL)hasCompletedNodeId:(NSString*)nodeId;

@end