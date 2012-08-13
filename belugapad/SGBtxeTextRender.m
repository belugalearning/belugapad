//
//  SGBtxeTextRender.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeTextRender.h"

@implementation SGBtxeTextRender

@synthesize label;

-(SGBtxeTextRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        self.label=nil;
    }
    return self;
    
}

-(void)setupDraw
{
    self.label=[CCLabelTTF labelWithString:ParentGO.text fontName:@"Helvetica" fontSize:18];
}

-(void)dealloc
{
    self.label=nil;
    
    [super dealloc];
}

@end
