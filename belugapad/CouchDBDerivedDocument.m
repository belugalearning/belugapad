//
//  CouchDBDerivedDocument.m
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CouchDBDerivedDocument.h"
#import "FMDatabase.h"

@interface CouchDBDerivedDocument()
@property (readwrite, retain) NSString *_id;
@property (readwrite, retain) NSString *_rev;
@end


@implementation CouchDBDerivedDocument

-(id)initWithFMResultSetRow:(FMResultSet*)resultSet
{
    self=[super init];
    if (self)
    {
        self._id = [resultSet stringForColumn:@"id"];
        self._rev = [resultSet stringForColumn:@"rev"];
    }
    return self;
}

-(void) dealloc
{
    self._id = nil;
    self._rev = nil;
    [super dealloc];
}

@end
