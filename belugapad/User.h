//
//  User.h
//  belugapad
//
//  Created by Nicholas Cartwright on 19/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface User : CouchModel

@property (retain) NSString *type;
@property (retain) NSString *nickName;
@property (retain) NSString *password;
@property (retain) NSDate *creationDateTime;
@property (retain) NSData *zubiColor; //(r,g,b,a) in const CGFLoat *
@property (retain) UIImage *zubiScreenshot;
@property (retain) NSArray *sessions;
@property (retain) NSArray *modulesStarted;
@property (retain) NSArray *elementsStarted;
@property (retain) NSArray *modulesCompleted;
@property (retain) NSArray *elementsCompleted;
@property (retain) NSString *currentModuleId;
@property (retain) NSString *currentElementId;

@end
