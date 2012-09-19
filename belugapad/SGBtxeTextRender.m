//
//  SGBtxeTextRender.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeTextRender.h"

@implementation SGBtxeTextRender

@synthesize label, label0;

-(SGBtxeTextRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        self.label=nil;
        self.label0=nil;
    }
    return self;

}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    [self.label0 setOpacity:0];
    [label0 runAction:[CCSequence actions:[CCDelayTime actionWithDuration:startTime + 0.25f], [CCFadeTo actionWithDuration:0.2f opacity:178], nil]];
    
    [self.label setOpacity:0];
    [label runAction:[CCSequence actions:[CCDelayTime actionWithDuration:startTime], [CCFadeTo actionWithDuration:0.2f opacity:255], nil]];
}

-(void)setupDraw
{
    self.label0=[CCLabelTTF labelWithString:ParentGO.text fontName:@"Source Sans Pro" fontSize:24];
    self.label0.position=ccp(0, -1);
    self.label0.color=ccc3(0, 0, 0);
    self.label0.opacity=178;
    
    self.label=[CCLabelTTF labelWithString:ParentGO.text fontName:@"Source Sans Pro" fontSize:24];

}

-(void)updatePosition:(CGPoint)position
{
    self.label.position=position;
    self.label0.position=ccpAdd(position, ccp(0, -1));
}

-(void)dealloc
{
    self.label=nil;
    self.label0=nil;
    
    [super dealloc];
}

@end
