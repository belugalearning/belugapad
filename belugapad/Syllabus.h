//
//  Syllabus.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface Syllabus : CouchModel

@property (readonly, retain) NSString *name;
@property (readonly, retain) NSArray *topics;

@end