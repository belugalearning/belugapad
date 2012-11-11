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

@implementation SGDtoolContainer

@synthesize BlocksInShape, Label, BaseNode;
@synthesize BlockType;
@synthesize AllowDifferentTypes;
@synthesize LineType;

-(SGDtoolContainer*) initWithGameWorld:(SGGameWorld*)aGameWorld andLabel:(NSString*)aLabel andRenderLayer:(CCLayer*)aRenderLayer
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        if(aLabel){
            self.BaseNode=[[CCNode alloc]init];
            self.Label=[CCLabelTTF labelWithString:aLabel fontName:SOURCE fontSize:PROBLEM_DESC_FONT_SIZE];
            [self.Label setColor:ccc3(255,0,0)];
            [self.BaseNode addChild:self.Label];
            [aRenderLayer addChild:self.BaseNode z:500];
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
        [self destroyThisObject];

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
        
        if(Label)[self repositionLabel];
    //}
}

-(void)removeBlockFromMe:(id)thisBlock
{
    if(LineType==@"Unbreakable")return;
    
    if(((id<Configurable>)thisBlock).blockType!=self.BlockType)return;
    
    if([BlocksInShape containsObject:thisBlock])
        [BlocksInShape removeObject:thisBlock];
    
    ((id<Moveable>)thisBlock).MyContainer=nil;
    
    
    if([BlocksInShape count]==0)
        [self destroyThisObject];
    else
        if(Label)[self repositionLabel];
}

-(void)layoutMyBlocks
{
    if([BlocksInShape count]==0)return;
    NSArray *blockPos=[NumberLayout physicalLayoutUpToNumber:[BlocksInShape count] withSpacing:52.0f];
    
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
    
    [Label setPosition:ccp(x,y)];

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
