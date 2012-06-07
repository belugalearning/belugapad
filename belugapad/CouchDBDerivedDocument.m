//
//  CouchDBDerivedDocument.m
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CouchDBDerivedDocument.h"
#import "FMDatabase.h"

@implementation CouchDBDerivedDocument

@synthesize _id, _rev;

-(id)initWithFMResultSetRow:(FMResultSet*)resultSet
{
    self=[super init];
    if (self)
    {
        _id = [resultSet stringForColumn:@"id"];
        _rev = [resultSet stringForColumn:@"rev"];
        [_id retain];
        [_rev retain];
    }
    return self;
}

-(void) dealloc
{
    [_id release];
    [_rev release];
    [super dealloc];
}

@end
