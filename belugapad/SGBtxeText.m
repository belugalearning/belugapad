//
//  SGBtxeText.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeText.h"

@implementation SGBtxeText

@synthesize size;
@synthesize text;

-(SGBtxeText*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
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
    
    [super dealloc];
}

@end
