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
@synthesize x, y, mastery, jtd, utd;
@synthesize regions;
@synthesize renderLayout, renderBase;
@synthesize comingSoon;
@synthesize isLit;

-(id)initWithFMResultSetRow:(FMResultSet*)resultSet
{
    self=[super initWithFMResultSetRow:resultSet];
    if (self)
    {
        NSString *pstring=[resultSet stringForColumn:@"pipelines"];
        NSData  *pdata=[pstring dataUsingEncoding:NSUTF8StringEncoding];
        pipelines=[pdata objectFromJSONData];
        
        x = [resultSet intForColumn:@"x"];
        y = [resultSet intForColumn:@"y"];
        mastery = [resultSet boolForColumn:@"mastery"];
        comingSoon=[resultSet boolForColumn:@"cs"];
        comingSoon2=[resultSet boolForColumn:@"cs2"];
        
        NSArray *jtds=[[resultSet stringForColumn:@"jtd"] objectFromJSONString];
        if(jtds.count>0) jtd=[jtds objectAtIndex:0];
        else jtd=@"";
        
        NSArray *utds=[[resultSet stringForColumn:@"utd"] objectFromJSONString];
        if(utds.count>0) utd=[utds objectAtIndex:0];
        else utd=@"";
        
        NSArray *renderBases=[[resultSet stringForColumn:@"renderbase"] objectFromJSONString];
        if(renderBases.count>0) renderBase=[[renderBases objectAtIndex:0] integerValue];
        
        NSArray *renderLayouts=[[resultSet stringForColumn:@"renderlayout"] objectFromJSONString];
        if(renderLayouts.count>0) renderLayout=[[renderLayouts objectAtIndex:0] integerValue];
        
        NSString *rstring=[resultSet stringForColumn:@"region"];
        NSData *rdata=[rstring dataUsingEncoding:NSUTF8StringEncoding];
        regions=[rdata objectFromJSONData];
        
        
    }
    
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

@end
