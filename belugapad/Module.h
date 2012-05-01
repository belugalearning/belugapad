//
//  Module.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface Module : CouchModel

@property (readonly, retain) NSString *name;
@property (readonly, retain) NSString *syllabusId;
@property (readonly, retain) NSString *topicId;
@property (readonly, retain) NSArray *elements;

@end