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
@synthesize useAlternateFont;
@synthesize useTheseAssets;

-(SGBtxeTextRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        self.label=nil;
        self.label0=nil;
        self.useAlternateFont=NO;
        self.useTheseAssets=@"Small";
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
    NSString *fontName=@"Source Sans Pro";
    float fontSize=24.0f;
    if(self.useAlternateFont) fontName=@"Chango";
    if([self.useTheseAssets isEqualToString:@"Medium"])
        fontSize=36.0f;
    else if([self.useTheseAssets isEqualToString:@"Large"])
        fontSize=48.0f;
    
    self.label0=[CCLabelTTF labelWithString:ParentGO.text fontName:fontName fontSize:fontSize];
    self.label0.position=ccp(0, -1);
    self.label0.color=ccc3(0, 0, 0);
    self.label0.opacity=178;
    
    self.label=[CCLabelTTF labelWithString:ParentGO.text fontName:fontName fontSize:fontSize];

}

-(void)updateLabel
{
    self.label.string=ParentGO.text;
    self.label0.string=ParentGO.text;
}

-(void)tagMyChildrenForIntro
{
    [self.label setTag:3];
    [self.label0 setTag:3];
    [self.label setOpacity:0];
    [self.label0 setOpacity:0];
}

-(void)updatePosition:(CGPoint)position
{
    self.label.position=position;
    self.label0.position=ccpAdd(position, ccp(0, -1));
}

-(void)inflateZindex
{
    self.label0.zOrder=99;
    self.label.zOrder=99;
}
-(void)deflateZindex
{
    self.label0.zOrder=0;
    self.label.zOrder=0;
}

-(void)dealloc
{
    self.label=nil;
    self.label0=nil;
    
    [super dealloc];
}

@end
