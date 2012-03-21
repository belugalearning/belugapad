//
//  Problem.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface Problem : CouchModel

@property (readonly, retain) NSString *syllabusId;
@property (readonly, retain) NSString *topicId;
@property (readonly, retain) NSString *moduleId;
@property (readonly, retain) NSString *elementId;
@property (readonly, retain) NSArray *assessmentCriteria;
@property (readonly) NSDictionary *pdef;
@property (readonly) NSData *expressionData;

@end
