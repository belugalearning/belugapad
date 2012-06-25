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

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (retain, nonatomic) NSDictionary *currentUser;

-(id)initWithProblemPipeline:(NSString*)source
           andLoggingService:(LoggingService*)ls;

-(NSArray*)deviceUsersByNickName;

-(BOOL) nickNameIsAvailable:(NSString*)nickName;

-(NSDictionary*) getNewUserWithNickName:(NSString*)nickName
                            andPassword:(NSString*)password
                           andZubiColor:(NSData*)color // rgba
                      andZubiScreenshot:(UIImage*)image;

-(NSDictionary*) userMatchingNickName:(NSString*)nickName
                          andPassword:(NSString*)password;

-(void)addCompletedNodeId:(NSString*)nodeId;
-(BOOL)hasCompletedNodeId:(NSString*)nodeId;

@end