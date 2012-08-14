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
        ParentGO=aGameObject;
        self.label=nil;
    }
    return self;

}

-(void)setupDraw
{
    self.label=[CCLabelTTF labelWithString:ParentGO.text fontName:@"Helvetica" fontSize:24];
}

-(void)updatePosition:(CGPoint)position
{
    self.label.position=position;
}

-(void)dealloc
{
    self.label=nil;
    
    [super dealloc];
}

@end
