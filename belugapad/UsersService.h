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

// use a static dict instead?
typedef enum {
    kUserEventCompleteProblem
    , kUserEventCompleteNode
} UserEvents;

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (retain, nonatomic) User *currentUser;

+(NSString*)userEventString:(UserEvents)event;

-(NSArray*)deviceUsersByLastSessionDate;

-(BOOL) nickNameIsAvailable:(NSString*)nickName;

-(User*) createUserWithNickName:(NSString*)nickName
                    andPassword:(NSString*)password
                   andZubiColor:(NSData*)color // rgba
              andZubiScreenshot:(UIImage*)image;

-(User*) userMatchingNickName:(NSString*)nickName
                  andPassword:(NSString*)password;

-(NSUInteger)currentUserTotalExp;
-(double)currentUserTotalTimeInApp;

-(void)startProblemAttempt;
-(void)togglePauseProblemAttempt;
-(void)endProblemAttempt:(BOOL)success;

-(void)addCompletedNodeId:(NSString *)nodeId;
-(BOOL)hasCompletedNodeId:(NSString *)nodeId;

@end