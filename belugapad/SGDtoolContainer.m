//
//  SGDtoolBlock.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGDtoolContainer.h"
#import "SGDtoolBlock.h"
#import "SGDtoolObjectProtocols.h"
#import "global.h"
#import "NumberLayout.h"
#import "ToolConsts.h"
#import "DistributionTool.h"

@implementation SGDtoolContainer

@synthesize BlocksInShape, Label, BaseNode;
@synthesize BlockType;
@synthesize AllowDifferentTypes;
@synthesize LineType;
@synthesize ShowCount, CountLabel;

-(SGDtoolContainer*) initWithGameWorld:(SGGameWorld*)aGameWorld andLabel:(NSString*)aLabel andShowCount:(BOOL)showValue andRenderLayer:(CCLayer*)aRenderLayer
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.BaseNode=[[CCNode alloc]init];
        [aRenderLayer addChild:self.BaseNode z:500];
        self.ShowCount=showValue;
        
        if(aLabel){
            self.Label=[CCLabelTTF labelWithString:aLabel fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
            [self.Label setColor:ccc3(255,0,0)];
            [self.BaseNode addChild:self.Label];
            [self repositionLabel];
        }
        if(showValue)
        {
            CountLabel=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:25.0f];
            [self.BaseNode addChild:CountLabel];
            [self repositionLabel];
        }
            self.BlocksInShape=[[NSMutableArray alloc]init];
    }
    return self;
}


-(void)handleMessage:(SGMessageType)messageType
{
    //re-broadcast messages to components
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    if([self blocksInShape]==0)
    {
        if(self.Label){
            DistributionTool *dtScene=(DistributionTool*)gameWorld.GameScene;
            [dtScene addDestroyedLabel:Label.string];
        }
        [self destroyThisObject];
    }
}

-(void)draw:(int)z
{

}

-(void)addBlockToMe:(id)thisBlock
{

    NSLog(@"Allow Different types? %@ thisBlock %@, thatBlock %@",self.AllowDifferentTypes?@"YES":@"NO",((id<Configurable>)thisBlock).blockType,self.BlockType);
    if(![((id<Configurable>)thisBlock).blockType isEqualToString:self.BlockType] && !self.AllowDifferentTypes)return;
    
        if(![BlocksInShape containsObject:thisBlock])
            [BlocksInShape addObject:thisBlock];

        ((id<Moveable>)thisBlock).MyContainer=self;
        
        //self.BlockType=((id<Configurable>)thisBlock).blockType;
        
        if(Label||ShowCount)[self repositionLabel];
    //}
}

-(void)removeBlockFromMe:(id)thisBlock
{
    if(LineType==@"Unbreakable")return;
    
    if(![((id<Configurable>)thisBlock).blockType isEqualToString:self.BlockType] && !self.AllowDifferentTypes)return;
    
    if([BlocksInShape containsObject:thisBlock])
        [BlocksInShape removeObject:thisBlock];
    
    ((id<Moveable>)thisBlock).MyContainer=nil;
    
    
    if([BlocksInShape count]==0)
        [self destroyThisObject];
    else
        if(Label||ShowCount)[self repositionLabel];
}

-(void)layoutMyBlocks
{
    if([BlocksInShape count]==0)return;
    NSArray *blockPos=[NumberLayout physicalLayoutAcrossToNumber:[BlocksInShape count] withSpacing:52.0f];
    
    id<Moveable> firstBlock=[BlocksInShape objectAtIndex:0];
    float posX=firstBlock.Position.x;
    float posY=firstBlock.Position.y;
    
    
    for(int i=0;i<[BlocksInShape count];i++)
    {
        id<Moveable> thisBlock=[BlocksInShape objectAtIndex:i];
        CGPoint thisPos=[[blockPos objectAtIndex:i]CGPointValue];
        
        thisBlock.Position=ccp(posX+thisPos.x, posY+thisPos.y);
        [thisBlock.mySprite runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.3f position:thisBlock.Position] rate:2.0f]];
    }
    
    [self repositionLabel];
}

-(float)updateValue
{
    float totalValue;
    for(SGDtoolBlock *b in BlocksInShape)
    {
        if([b.blockType isEqualToString:@"Value_001"])
            totalValue+=kShapeValue001;
        else if([b.blockType isEqualToString:@"Value_01"])
            totalValue+=kShapeValue01;
        else if([b.blockType isEqualToString:@"Value_1"])
            totalValue+=kShapeValue1;
        else if([b.blockType isEqualToString:@"Value_10"])
            totalValue+=kShapeValue10;
        else if([b.blockType isEqualToString:@"Value_100"])
            totalValue+=kShapeValue100;
    }

    return totalValue;
}
-(void)repositionLabel
{
    float x=0;
    float y=0;

    for(id<Moveable> go in BlocksInShape)
    {
        x+=go.Position.x;
        y+=go.Position.y;
    }
    
    
    x=x/[BlocksInShape count];
    y=y/[BlocksInShape count];
    
    if(Label){
        [Label setPosition:ccp(x,y)];
    }
    if(ShowCount)
    {
        [CountLabel setString:[NSString stringWithFormat:@"%g", [self updateValue]]];
        [CountLabel setPosition:ccp(x,y-30)];
    }

}

-(int)blocksInShape
{
    return [self.BlocksInShape count];
}

-(void)destroyThisObject
{
    if(self.Label)[self.Label removeFromParentAndCleanup:YES];
    if(self.BaseNode)[self.BaseNode removeFromParentAndCleanup:YES];
    if(self.BlocksInShape)[self.BlocksInShape release];
    [gameWorld delayRemoveGameObject:self];
}

-(void)dealloc
{
    self.BaseNode=nil;
    self.Label=nil;
    self.BlocksInShape=nil;
    
    [super dealloc];
}

@end
