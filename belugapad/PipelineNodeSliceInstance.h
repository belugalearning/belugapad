//
//  PipelineNodeSliceInstance.h
//  belugapad
//
//  Created by Gareth Jenkins on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface PipelineNodeSliceInstance : CouchModel

@property (retain) NSString *nodeSliceId;
@property (retain) NSArray *pipeline;
@property (retain) NSString *type;

-(NSArray*)evaluatePreRequisites;

@end
