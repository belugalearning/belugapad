//
//  SGBtxeTextBackgroundRender.m
//  belugapad
//
//  Created by gareth on 14/08/2012.
//
//

#import "SGBtxeTextBackgroundRender.h"

@implementation SGBtxeTextBackgroundRender

@synthesize sprite;

-(SGBtxeTextBackgroundRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        self.sprite=nil;
    }
    return self;
}

-(void)setupDrawWithSize:(CGSize)size
{
    
}

-(void)updatePosition:(CGPoint)position
{
    
}

-(void)dealloc
{
    self.sprite=nil;
    
    [super dealloc];
}

@end
