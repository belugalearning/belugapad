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
@synthesize x, y, mastery, jtd;
@synthesize regions;

@synthesize isLit;

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
        
        NSArray *jtds=[[resultSet stringForColumn:@"jtd"] objectFromJSONString];
        if(jtds.count>0) jtd=[jtds objectAtIndex:0];
        else jtd=@"";
        
        regions=[[resultSet stringForColumn:@"region"] objectFromJSONString];
        [regions retain];
    }
    return self;
}

-(void) dealloc
{
    [pipelines release];
    [super dealloc];
}

@end
