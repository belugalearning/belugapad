//
//  SGBtxeObjectText.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeObjectText.h"

@implementation SGBtxeObjectText

@synthesize size, position;
@synthesize text;
@synthesize enabled, tag;

-(SGBtxeObjectText*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
        position=CGPointZero;
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
