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
#import "SGBtxeProtocols.h"
#import "SGBtxeContainerMgr.h"
#import "SGBtxeRow.h"
#import "SGBtxeObjectIcon.h"

@implementation SGDtoolContainer

@synthesize BlocksInShape, Label, BaseNode, BTXELabel, BTXERow;
@synthesize BlockType;
@synthesize AllowDifferentTypes;
@synthesize LineType;
@synthesize ShowCount, CountLabel;
@synthesize RenderLayer;
@synthesize IsEvalTarget;
@synthesize Selected;

-(SGDtoolContainer*) initWithGameWorld:(SGGameWorld*)aGameWorld andLabel:(NSString*)aLabel andShowCount:(BOOL)showValue andRenderLayer:(CCLayer*)aRenderLayer
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.BaseNode=[[[CCNode alloc]init]autorelease];
        [aRenderLayer addChild:self.BaseNode z:500];
        self.ShowCount=showValue;
        self.RenderLayer=aRenderLayer;
        self.IsEvalTarget=NO;
        self.Selected=NO;
        
        if(aLabel){
            
            NSString *answerLabelString=[NSString stringWithFormat:@"%@", aLabel];
            
            if(answerLabelString.length<3)
            {
                //this can't have a <b:t> at the begining
                
                //assume the string needs wrapping in b:t
                answerLabelString=[NSString stringWithFormat:@"<b:t>%@</b:t>", answerLabelString];
            }
            else if([[answerLabelString substringToIndex:3] isEqualToString:@"<b:"])
            {
                //doesn't need wrapping
            }
            else
            {
                //assume the string needs wrapping in b:t
                answerLabelString=[NSString stringWithFormat:@"<b:t>%@</b:t>", answerLabelString];
            }
            
            SGBtxeRow *row=[[SGBtxeRow alloc] initWithGameWorld:gameWorld andRenderLayer:self.RenderLayer];
            
            row.forceVAlignTop=NO;
            
            [row parseXML:answerLabelString];
            [row setupDraw];
            [self repositionLabel];
            
            BTXERow=row;
            BTXELabel=[[row children]objectAtIndex:0];
            [row inflateZindex];
            
        }
        if(showValue)
        {
            CountLabel=[CCLabelTTF labelWithString:@"" fontName:SOURCE fontSize:25.0f];
            [self.BaseNode addChild:CountLabel];
            [self repositionLabel];
        }
            self.BlocksInShape=[[[NSMutableArray alloc]init]autorelease];
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
    if([LineType isEqualToString:@"Unbreakable"])return;
    
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
    
    //build an array of current positions
    NSMutableArray *previousPositions=[[NSMutableArray alloc] init];
    for(int i=0;i<[BlocksInShape count];i++)
    {
        id<Moveable> thisBlock=[BlocksInShape objectAtIndex:i];
        CGPoint thisPos=thisBlock.Position;
        [previousPositions addObject:[NSValue valueWithCGPoint:thisPos]];
    }
    
    NSArray *blockPos=[NumberLayout physicalLayoutAcrossToNumber:[BlocksInShape count] withSpacing:kDistanceBetweenBlocks];
    
    id<Moveable> firstBlock=[BlocksInShape objectAtIndex:0];
    float posX=firstBlock.Position.x;
    float posY=firstBlock.Position.y;
    
    
    for(int i=0;i<[BlocksInShape count];i++)
    {
        id<Moveable> thisBlock=[BlocksInShape objectAtIndex:i];
        CGPoint thisPos=[[blockPos objectAtIndex:i]CGPointValue];
        
        thisBlock.Position=ccp(posX+thisPos.x, posY+thisPos.y);
        
        //establish if this was a previously used location
        BOOL wasPreviouslyUsed=NO;
        for(NSValue *v in previousPositions)
        {
            CGPoint pcomp=[v CGPointValue];
            if(pcomp.x==thisBlock.Position.x && pcomp.y==thisBlock.Position.y)
            {
                wasPreviouslyUsed=YES;
            }
        }
        
        if(wasPreviouslyUsed)
            thisBlock.mySprite.position=thisBlock.Position;
        else
            [thisBlock.mySprite runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.3f position:thisBlock.Position] rate:2.0f]];

    }
    
    [self repositionLabel];
}

-(float)updateValue
{
    float totalValue=0;
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
        [Label setPosition:ccp(x,y+80)];
    }
    if(ShowCount)
    {
        [CountLabel setString:[NSString stringWithFormat:@"%g", [self updateValue]]];
        [CountLabel setPosition:ccp(x,y-80)];
    }
    
    if(BTXERow)
    {
        BTXERow.position=ccp(x,y+80);
        
    }

}

-(void)setGroupBTXELabel:(id)thisLabel
{
    if(BTXERow)
    {
        if([BTXELabel isKindOfClass:[SGBtxeObjectIcon class]])
           [(SGBtxeObjectIcon*)BTXELabel destroy];
        
        BTXERow=nil;
        BTXELabel=nil;
        
    }
        BTXELabel=thisLabel;
//    else
//    {
        SGBtxeRow *row=[[SGBtxeRow alloc] initWithGameWorld:gameWorld andRenderLayer:self.RenderLayer];
        row.forceVAlignTop=NO;
        SGBtxeContainerMgr *rowContMgr=row.containerMgrComponent;
        
        [rowContMgr addObjectToContainer:BTXELabel];
        
        [row setupDraw];
        BTXERow=row;
        
//    }
    [self repositionLabel];
}

-(int)blocksInShape
{
    return [self.BlocksInShape count];
}

-(void)selectMyBlocks
{
    if(!self.Selected)
        self.Selected=YES;
    else if(self.Selected)
        self.Selected=NO;
        
    for(id<Moveable> go in self.BlocksInShape)
    {
        [go selectMe];
    }
}

-(void)setGroupLabelString:(NSString*)toThisString
{
    if(!Label)
    {
        self.Label=[CCLabelTTF labelWithString:toThisString fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
        [self.Label setColor:ccc3(255,0,0)];
        [self.BaseNode addChild:self.Label];
    }
    else
    {
        [self.Label setString:toThisString];
    }
    
    [self repositionLabel];
}

-(void)destroyThisObject
{
    if(self.Label)[self.Label removeFromParentAndCleanup:YES];
    if(self.BaseNode)[self.BaseNode removeFromParentAndCleanup:YES];
    if(self.BlocksInShape) self.BlocksInShape=nil;
    if(self.BTXERow){
        for(id o in BTXERow.children)
        {
            if([o conformsToProtocol:@protocol(Interactive) ])
                [o destroy];
        }
    }
    
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
