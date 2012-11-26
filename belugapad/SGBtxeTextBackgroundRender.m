//
//  SGBtxeTextBackgroundRender.m
//  belugapad
//
//  Created by gareth on 14/08/2012.
//
//

#import "SGBtxeTextBackgroundRender.h"
#import "SGBtxePlaceholder.h"
#import "global.h"

@implementation SGBtxeTextBackgroundRender

@synthesize backgroundNode;

-(SGBtxeTextBackgroundRender*)initWithGameObject:(id<Bounding, Text>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        self.backgroundNode=nil;
    }
    return self;
}

-(void)setColourOfBackgroundTo:(ccColor3B)thisColour
{
    for(CCSprite *s in backgroundNode.children)
    {
        [s setColor:thisColour];
    }
}

-(ccColor3B)returnColourOfBackground
{
    CCSprite *s=[[self.backgroundNode children]objectAtIndex:0];
    return s.color;
}

-(void)setContainerVisible:(BOOL)visible
{
    if([(id<NSObject>)ParentGO isKindOfClass:[SGBtxePlaceholder class]])
    {
        [self.backgroundNode setVisible:visible];
    }
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    for(CCSprite *s in backgroundNode.children)
    {
        [s setOpacity:0];
        [s runAction:[CCSequence actions:[CCDelayTime actionWithDuration:startTime + 0.25f], [CCFadeTo actionWithDuration:0.2f opacity:178], nil]];
    }
}


-(void)setupDrawWithSize:(CGSize)size
{
    BOOL isLarge=NO;
    
    if([((id<NSObject>)ParentGO) conformsToProtocol:@protocol(MovingInteractive)])
    {
        if(!((id<MovingInteractive>)ParentGO).interactive)return;
        isLarge=((id<MovingInteractive>)ParentGO).isLargeObject;
    }
    
    BOOL isPlaceholder=NO;
    backgroundNode=[[CCNode alloc]init];
    CCSprite *lh=nil;
    CCSprite *m=nil;
    CCSprite *rh=nil;
    
    if([(id<NSObject>)ParentGO isKindOfClass:[SGBtxePlaceholder class]])
    {
        isPlaceholder=YES;
        isLarge=((SGBtxePlaceholder*)ParentGO).isLargeObject;
    }
    if(isPlaceholder)
    {
        if(isLarge)
        {
            lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Left.png")];
            m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Middle.png")];
            rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Right.png")];
        }
        else
        {
            lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Left.png")];
            m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Middle.png")];
            rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Holder_Large_Right.png")];
        }
//        [rh setPosition:ccp(((m.contentSize.width)*m.scaleX)+(rh.contentSize.width)*2, 0)];
    }
    else
    {
        if(isLarge)
        {
            lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Large_Left.png")];
            m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Large_Middle.png")];
            rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Large_Right.png")];
        }
        else
        {
            lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Left.png")];
            m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Middle.png")];
            rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Right.png")];
        }
//        [rh setPosition:ccp(m.contentSize.width/2+(rh.contentSize.width/2), 0)];
    }
    
    m.scaleX=size.width / m.contentSize.width;
    //m.scaleY=size.height / m.contentSize.height;
    
    //lh.scaleY=size.height / m.contentSize.height;
    //rh.scaleY=size.height / m.contentSize.height;
    
    [self.backgroundNode setPosition:ccp(0, -3)];
    [lh setPosition:ccp(-((m.contentSize.width/2)*m.scaleX)-(lh.contentSize.width/2),0)];
    [rh setPosition:ccp(((m.contentSize.width/2)*m.scaleX)+(rh.contentSize.width/2),0)];

    [backgroundNode addChild:lh];
    [backgroundNode addChild:m];
    [backgroundNode addChild:rh];
    
//    backgroundNode=[[CCNode alloc]init];
//    CCSprite *lh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Left.png")];
//    CCSprite *m=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Middle.png")];
//    CCSprite *rh=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/btxe/SB_Block_Question_Right.png")];
//    
//    m.scaleX=size.width / m.contentSize.width;
//    m.scaleY=size.height / m.contentSize.height;
//    
//    lh.scaleY=size.height / m.contentSize.height;
//    rh.scaleY=size.height / m.contentSize.height;
//    
//    [self.backgroundNode setPosition:ccp(0, -3)];
//    [lh setPosition:ccp(-((m.contentSize.width/2)*m.scaleX)-(lh.contentSize.width/2),0)];
//    [rh setPosition:ccp(((m.contentSize.width/2)*m.scaleX)+(rh.contentSize.width/2), 0)];
//    [backgroundNode addChild:lh];
//    [backgroundNode addChild:m];
//    [backgroundNode addChild:rh];
}

-(void)redrawBkgWithSize:(CGSize)size
{
    CCSprite *lh=[backgroundNode.children objectAtIndex:0];
    CCSprite *m=[backgroundNode.children objectAtIndex:1];
    CCSprite *rh=[backgroundNode.children objectAtIndex:2];
    m.scaleX=size.width / m.contentSize.width;
    //m.scaleY=size.height / m.contentSize.height;
    
    //lh.scaleY=size.height / m.contentSize.height;
    //rh.scaleY=size.height / m.contentSize.height;
    
    //[self.backgroundNode setPosition:ccp(0, -3)];
    [lh setPosition:ccp(-((m.contentSize.width/2)*m.scaleX)-(lh.contentSize.width/2),0)];
    [rh setPosition:ccp(((m.contentSize.width/2)*m.scaleX)+(rh.contentSize.width/2),0)];
}

-(void)updatePosition:(CGPoint)position
{
    self.backgroundNode.position=ccpAdd(position, ccp(0, -3));
}

-(void)dealloc
{
    self.backgroundNode=nil;
    
    [super dealloc];
}

@end
