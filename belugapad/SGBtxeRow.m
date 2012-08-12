//
//  SGBtxeRow.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeRow.h"

@implementation SGBtxeRow

@synthesize children;   //Container properties
@synthesize size, position;       //Bounding properties

-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        children=[[NSMutableArray alloc] init];
        size=CGSizeZero;
        position=CGPointZero;
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)calculateSize
{
    
}

-(void)parseXML:(NSString *)xmlString
{
    
}


-(NSArray*)children
{
    return [NSArray arrayWithArray:children];
}

-(void)dealloc
{
    [children release];
    
    [super dealloc];
}

@end
