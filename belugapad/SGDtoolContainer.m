//
//  SGDtoolBlock.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGDtoolContainer.h"
#import "global.h"

@implementation SGDtoolContainer

@synthesize BlocksInShape, Label, BaseNode;

-(SGDtoolContainer*) initWithGameWorld:(SGGameWorld*)aGameWorld andLabel:(NSString*)aLabel andRenderLayer:(CCLayer*)aRenderLayer
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        if(aLabel){
            self.BaseNode=[[CCNode alloc]init];
            self.Label=[CCLabelTTF labelWithString:aLabel fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            self.BlocksInShape=[[NSMutableArray alloc]init];
            [self.BaseNode addChild:self.Label];
            [aRenderLayer addChild:self.BaseNode];
        }
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

}

-(void)draw:(int)z
{

}

-(void)addBlockToMe:(id)thisBlock
{
    if(![BlocksInShape containsObject:thisBlock])
        [BlocksInShape addObject:thisBlock];
    ((id<Moveable>)thisBlock).MyContainer=self;
    
    [self repositionLabel];
    NSLog(@"add block to shape %d blocks", [self.BlocksInShape count]);
}

-(void)removeBlockFromMe:(id)thisBlock
{
    if([BlocksInShape containsObject:thisBlock])
        [BlocksInShape removeObject:thisBlock];
    ((id<Moveable>)thisBlock).MyContainer=nil;
    [self repositionLabel];
    NSLog(@"remove block to shape %d blocks", [self.BlocksInShape count]);
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

-(void)dealloc
{
    self.BaseNode=nil;
    self.Label=nil;
    self.BlocksInShape=nil;
    
    [super dealloc];
}

@end
