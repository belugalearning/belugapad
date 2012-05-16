//
//  NodeSlice.h
//  belugapad
//
//  Created by Gareth Jenkins on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface NodeSlice : CouchModel

@property (retain) NSString *userId;
@property (retain) NSString *nodeId;
@property (retain) NSArray *pipelines;
@property (retain) NSString *type;

-(void)populateNode;

@end
