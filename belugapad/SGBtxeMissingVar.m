//
//  SGBtxeMissingVar.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeMissingVar.h"

@implementation SGBtxeMissingVar

@synthesize size;
@synthesize text;
@synthesize enabled, tag;

-(SGBtxeMissingVar*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
        tag=@"";
        enabled=YES;
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

-(void)dealloc
{
    self.text=nil;
    self.tag=nil;
    
    [super dealloc];
}

@end
