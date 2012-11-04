//
//  SGBtxeText.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeText.h"
#import "SGBtxeTextRender.h"

@implementation SGBtxeText

@synthesize size, position;
@synthesize text, textRenderComponent;
@synthesize container;

-(SGBtxeText*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
        position=CGPointZero;
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)setText:(NSString *)theText
{
    text=[theText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    [textRenderComponent fadeInElementsFrom:startTime andIncrement:incrTime];
}

-(void)attachToRenderBase:(CCNode*)renderBase;
{
    [renderBase addChild:textRenderComponent.label0];
    [renderBase addChild:textRenderComponent.label];
}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    
    //update positioning in text render
    [self.textRenderComponent updatePosition:position];
    
}

-(void)setupDraw
{
    //text render to create it's label
    [textRenderComponent setupDraw];
    
    //set size to size of cclabelttf
    self.size=self.textRenderComponent.label.contentSize;
}

-(void)dealloc
{
    self.text=nil;
    self.textRenderComponent=nil;
    self.container=nil;
    
    
    [super dealloc];
}

@end
