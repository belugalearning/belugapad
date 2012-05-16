//
//  Device.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface Device : CouchModel

@property (retain) NSDate *firstLaunchDateTime;
@property (retain) NSArray *userSessions;

@end
