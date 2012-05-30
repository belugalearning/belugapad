//
//  UserSession.m
//  belugapad
//
//  Created by Nicholas Cartwright on 24/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserSession.h"
#import "User.h"
#import "Device.h"

@implementation UserSession

@dynamic type, user, device, contentSource, dateStart, dateEnd;

-(id)initWithNewDocumentInDatabase:(CouchDatabase*)database
            AndStartSessionForUser:(User*)user
                          onDevice:(Device*)device
                 withContentSource:(NSString*)source
{
    self = [super initWithDocument: nil];
    if (self)
    {
        self.database = database;
        self.type = @"user session";        
        self.user = user;
        self.device = device;
        self.contentSource = source;
        self.dateStart = [NSDate date];
        
        [[self save] wait];
    }
    return self;
}

@end
