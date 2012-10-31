//
//  CouchDBDerivedDocument.h
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMResultSet;

@interface CouchDBDerivedDocument : NSObject

@property (readonly, retain) NSString *_id;
@property (readonly, retain) NSString *_rev;

-(id)initWithFMResultSetRow:(FMResultSet*)resultSet;

@end
