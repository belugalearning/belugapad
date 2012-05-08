//
//  ConceptNode.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConceptNode.h"
#import "User.h"

@implementation ConceptNode

@dynamic graffleId, nodeDescription, notes, pipelines, tags, x, y;

@synthesize journeySprite, nodeSliceSprite;

-(BOOL)isNodeCompleteForUser:(User*)user
{
    return NO;
}

@end
