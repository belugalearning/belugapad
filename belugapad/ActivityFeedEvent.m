//
//  ActivityFeedEvent.m
//  belugapad
//
//  Created by Nicholas Cartwright on 22/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ActivityFeedEvent.h"
#import "UsersService.h"
#import "User.h"
#import "Module.h"
#import "Element.h"
#import "Problem.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchModelFactory.h>

@implementation ActivityFeedEvent

@dynamic userId, type, eventType, entityId, text, dateTime, points;

- (id) initWithNewDocumentInDatabase:(CouchDatabase*)database
                        usersService:(UsersService*)usersService
                     contentDatabase:(CouchDatabase*)contentDatabase
                           eventType:(ActivityFeedEventTypes)eventType
                            entityId:(NSString*)entityId
                              points:(NSUInteger)points
{
    NSParameterAssert(database);
    self = [super initWithDocument: nil];
    if (self)
    {
        self.database = database;
        self.userId = usersService.currentUser.document.documentID;
        self.type = @"activity feed event";
        self.entityId = entityId;
        self.dateTime = [NSDate date];
        
        NSString *nickName = usersService.currentUser.nickName;
        
        Module *m = nil;
        Element *e = nil;
        Problem *p = nil;
        
        switch (eventType)
        {
            case kStartModule:
                self.eventType = @"started module";
                m = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:entityId]];
                self.text = [NSString stringWithFormat:@"%@ started %@", nickName, m.name];
                break;
            case kStartElement:
                self.eventType = @"started element";
                e = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:entityId]];
                self.text = [NSString stringWithFormat:@"%@ started %@", nickName, e.name];
                break;
            case kPlayingModule:
                self.eventType = @"playing module";
                m = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:entityId]];
                self.text = [NSString stringWithFormat:@"%@ playing %@", nickName, m.name];
                break;
            case kPlayingElement:
                self.eventType = @"playing element";
                e = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:entityId]];
                self.text = [NSString stringWithFormat:@"%@ playing %@", nickName, e.name];
                break;
            case kCompleteModule:
                self.eventType = @"completed module";
                m = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:entityId]];
                self.text = [NSString stringWithFormat:@"%@ completed %@", nickName, m.name];
                break;
            case kCompleteElement:
                self.eventType = @"completed element";
                e = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:entityId]];
                self.text = [NSString stringWithFormat:@"%@ completed %@", nickName, e.name];
                break;
            case kCompleteProblem:
                self.eventType = @"completed problem";
                p = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:entityId]];
                e = [[CouchModelFactory sharedInstance] modelForDocument:[contentDatabase documentWithID:p.elementId]];
                NSUInteger elCompletion = (NSUInteger)(100 * [usersService currentUserPercentageCompletionOfElement:e]);
                self.text = [NSString stringWithFormat:@"%@ +%d %@ (%d%%)", nickName, points, e.name, elCompletion];
                break;
            default:
                break;
        }        
    }
    return self;
}


@end
