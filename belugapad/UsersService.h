//
//  UsersService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User, ProblemAttempt, Element, CouchLiveQuery;

@interface UsersService : NSObject

typedef enum {
    kUserEventFirstStartTopic,
    kUserEventFirstStartModule,
    kUserEventFirstStartElement,
    kUserEventNowPlayingTopic,
    kUserEventNowPlayingModule,
    kUserEventNowPlayingElement,
    kUserEventCompleteTopic,
    kUserEventCompleteModule,
    kUserEventCompleteElement,  
    kUserEventCompleteProblem   
} UserEvents;

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (retain, nonatomic) User *currentUser;

+(NSString*)userEventString:(UserEvents)event;

-(NSArray*) deviceUsersByLastSessionDate;

-(BOOL) nickNameIsAvailable:(NSString*)nickName;

-(User*) createUserWithNickName:(NSString*)nickName
                    andPassword:(NSString*)password
                   andZubiColor:(NSData*)color // rgba
              andZubiScreenshot:(UIImage*)image;

-(User*) userMatchingNickName:(NSString*)nickName
                  andPassword:(NSString*)password;

-(NSUInteger)currentUserTotalExp;
-(double)currentUserPercentageCompletionOfElement:(Element*)elementId;
-(double)currentUserTotalTimeInApp;
-(double)currentUserTotalPlayingElement:(NSString*)element;

-(NSString*) lastCompletedProblemIdInElementWithId:(NSString*)elementId
                                         andUserId:(NSString*)userId;

-(void)startProblemAttempt;
-(void)togglePauseProblemAttempt;
-(void)endProblemAttempt:(BOOL)success;

@end