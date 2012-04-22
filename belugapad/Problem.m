//
//  Problem.m
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Problem.h"
#import <CouchCocoa/CouchCocoa.h>

@implementation Problem

@dynamic syllabusId, topicId, moduleId, elementId, assessmentCriteria;

-(NSDictionary*)pdef    
{
    CouchAttachment *ca = [self attachmentNamed:@"pdef.plist"];
    if (!ca || !ca.body) return nil;
    
    NSString *errorStr = nil;
    NSPropertyListFormat format;
    return [NSPropertyListSerialization propertyListFromData:ca.body
                                            mutabilityOption:NSPropertyListImmutable
                                                      format:&format
                                            errorDescription:&errorStr];
}

-(NSData*)expressionData
{
    CouchAttachment *ca = [self attachmentNamed:@"expression.mathml"];
    if (!ca) return nil;
    return ca.body;
}

@end
