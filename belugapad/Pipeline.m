//
//  Pipeline.m
//  belugapad
//
//  Created by Gareth Jenkins on 08/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Pipeline.h"
#import "FMDatabase.h"
#import "JSONKit.h"

@implementation Pipeline

@synthesize name, problems;

-(id)initWithFMResultSetRow:(FMResultSet *)resultSet
{
    self=[super initWithFMResultSetRow:resultSet];
    if (self)
    {
        name = [resultSet stringForColumn:@"name"];
        [name retain];
        
        problems = [[resultSet stringForColumn:@"problems"] objectFromJSONString];
        [problems retain];
    }
    return self;
}

-(void)dealloc
{
    [name release];
    [problems release];
    [super dealloc];
}

@end
