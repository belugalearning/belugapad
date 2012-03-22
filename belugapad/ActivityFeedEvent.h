//
//  ActivityFeedEvent.h
//  belugapad
//
//  Created by Nicholas Cartwright on 22/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>
@class UsersService;

@interface ActivityFeedEvent : CouchModel

typedef enum {
    kStartModule,
    kStartElement,
    kPlayingModule,
    kPlayingElement,
    kCompleteModule,
    kCompleteElement,
    kCompleteProblem,
    kAppTimeMilestone
} ActivityFeedEventTypes;


@property (retain) NSString *userId;
@property (retain) NSString *type;
@property (retain) NSString *eventType;
@property (retain) NSString *entityId;
@property (retain) NSString *text;
@property (retain) NSDate *dateTime;
@property NSUInteger points;

- (id) initWithNewDocumentInDatabase:(CouchDatabase*)database
                        usersService:(UsersService*)usersService
                           eventType:(ActivityFeedEventTypes)eventType
                            entityId:(NSString*)entityId
                              points:(NSUInteger)points;

@end
