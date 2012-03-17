//
//  UsersService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User, CouchLiveQuery;

@interface UsersService : NSObject

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (retain, nonatomic) User *currentUser;

-(NSArray*) deviceUsersByLastSessionDate;

-(BOOL) nickNameIsAvailable:(NSString*)nickName;

-(User*) createUserWithNickName:(NSString*)nickName
                    andZubiColor:(NSData*)color // rgba
               andZubiScreenshot:(UIImage*)image;

-(User*) userMatchingNickName:(NSString*)nickName
                     andPassword:(NSString*)password;

@end