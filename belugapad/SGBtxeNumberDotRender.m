//
//  SGBtxeNumberDotRender.m
//  belugapad
//
//  Created by gareth on 23/11/2012.
//
//

#import "SGBtxeNumberDotRender.h"
#import "global.h"
#import "NumberLayout.h"

@implementation SGBtxeNumberDotRender

-(SGBtxeNumberDotRender*)initWithGameObject:(id<Value>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    return self;
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    for(CCSprite *s in self.baseNode.children)
    {
        [s setOpacity:0];
        [s runAction:[CCSequence actions:[CCDelayTime actionWithDuration:startTime + 0.25f], [CCFadeTo actionWithDuration:0.2f opacity:255], nil]];
        
    }
}

-(void)setupDraw
{
    self.baseNode=[CCNode node];
    
    
    [self drawDotsOnBase];
}

-(void)updateDraw
{
    [self.baseNode removeAllChildrenWithCleanup:YES];
    
    [self drawDotsOnBase];

}

-(void)drawDotsOnBase
{
    int count=[ParentGO.value intValue];
    float spacing=20.0f;
    id<MovingInteractive>pgo=(id<MovingInteractive>)ParentGO;
    
    if([pgo.assetType isEqualToString:@"Large"])
        spacing=40.0f;
    
    NSArray *positions=[NumberLayout physicalLayoutAcrossToNumber:count withSpacing:spacing];
    NSString *str=[NSString stringWithFormat:@"/images/btxe/Number_Dot_%@.png",pgo.assetType];
    
    for(int i=0; i<count; i++)
    {
        CCSprite *dot=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(str)];
        dot.position=[[positions objectAtIndex:i] CGPointValue];
        [self.baseNode addChild:dot];
    }
}

-(CGSize)size
{
    int count=[ParentGO.value intValue];
    NSArray *positions=[NumberLayout physicalLayoutAcrossToNumber:count withSpacing:20.0f];
    CGPoint s=[[positions lastObject] CGPointValue];
    return CGSizeMake(fabsf(s.x) + 40.0f, fabsf(s.y));
}


-(void)inflateZindex
{
    self.baseNode.zOrder=99;
}

-(void)deflateZindex
{
    self.baseNode.zOrder=0;
}

-(void)updatePosition:(CGPoint)thePosition
{
    self.baseNode.position=ccpAdd(thePosition, ccp(self.size.width / 2.0f, self.size.height / 2.0f));
}

-(void)dealloc
{
    self.baseNode=nil;
    
    [super dealloc];
}

@end
