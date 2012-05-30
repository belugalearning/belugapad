//
//  UserSession.h
//  belugapad
//
//  Created by Nicholas Cartwright on 24/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>
@class User, Device;

@interface UserSession : CouchModel

@property (retain) NSString *type;
@property (retain) User *user;
@property (retain) Device *device;
@property (retain) NSString *contentSource;
@property (retain) NSDate *dateStart;
@property (retain) NSDate *dateEnd;

-(id)initWithNewDocumentInDatabase:(CouchDatabase*)database
            AndStartSessionForUser:(User*)user
                          onDevice:(Device*)device
                 withContentSource:(NSString*)source;
@end
