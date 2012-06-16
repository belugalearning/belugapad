//
//  ConceptNode.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConceptNode.h"
#import "FMDatabase.h"
#import "JSONKit.h"

@implementation ConceptNode

@synthesize pipelines;
@synthesize x, y, mastery;
@synthesize journeySprite, nodeSliceSprite, lightSprite;

@dynamic isLit;

-(id)initWithFMResultSetRow:(FMResultSet*)resultSet
{
    self=[super initWithFMResultSetRow:resultSet];
    if (self)
    {
        pipelines = [[resultSet stringForColumn:@"pipelines"] objectFromJSONString];
        [pipelines retain];
        
        x = [resultSet intForColumn:@"x"];
        y = [resultSet intForColumn:@"y"];
        mastery = [resultSet boolForColumn:@"mastery"];
                
    }
    return self;
}

-(void) dealloc
{
    [pipelines release];
    if (journeySprite) [journeySprite release];
    if (nodeSliceSprite) [nodeSliceSprite release];
    if (lightSprite) [lightSprite release];
    [super dealloc];
}

@end
