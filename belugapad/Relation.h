//
//  Relation.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface Relation : CouchModel

@property (readonly, retain) NSArray *members;
@property (readonly, retain) NSString *name;
@property (readonly, retain) NSString *relationDescription;
@property (readonly, retain) NSString *relationType;

@end
