//
//  ConceptNode.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface ConceptNode : CouchModel

@property (readonly, retain) NSNumber *graffleId;
@property (readonly, retain) NSString *nodeDescription;
@property (readonly, retain) NSString *notes;
@property (readonly, retain) NSArray *pipelines;
@property (readonly, retain) NSArray *tags;
@property (readonly, retain) NSNumber *x;
@property (readonly, retain) NSNumber *y;

@end
