//
//  SGFractionBuilderChunk.m
//  belugapad
//
//  Created by David Amphlett on 24/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGFractionObjectProtocols.h"
#import "SGFractionBuilderChunkManager.h"
#import "SGFbuilderFraction.h"
#import "SGFbuilderChunk.h"
#import "BLMath.h"
#import "ToolConsts.h"

@interface SGFractionBuilderChunkManager()
{
    CCSprite *fractionSprite;
}

@end

@implementation SGFractionBuilderChunkManager

-(SGFractionBuilderChunkManager*)initWithGameObject:(id<Configurable, Moveable, Interactive>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(id)createChunk
{
    if(ParentGO.FractionMode==0 && ParentGO.MarkerPosition>0)
    {
        fractionSprite=ParentGO.FractionSprite;
        float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
//        float leftPos=fractionSprite.position.x;
        float posOnFraction=fractionSprite.contentSize.width/(ParentGO.MarkerPosition+1);
        float adjPosOnFraction=posOnFraction*([ParentGO.Chunks count]);
        CGPoint startPos=ccp(leftPos+adjPosOnFraction,fractionSprite.position.y);
        
        startPos=[fractionSprite.parent convertToWorldSpace:startPos];
 
        id<ConfigurableChunk> chunk;
        chunk=[[[SGFbuilderChunk alloc] initWithGameWorld:gameWorld andRenderLayer:ParentGO.RenderLayer andPosition:startPos] autorelease];
        chunk.MyParent=ParentGO;
        chunk.CurrentHost=ParentGO;
        chunk.ScaleX=20.0f/(ParentGO.MarkerPosition+1);
        NSLog(@"this chunk's scale is %f. 20/MarkerPos=%f, MarkerPos=%d", chunk.ScaleX, 20.0f/ParentGO.MarkerPosition, ParentGO.MarkerPosition);
        chunk.Value=ParentGO.Value/(ParentGO.MarkerPosition+1);
        
        
        [chunk setup];
        [ParentGO.Chunks addObject:chunk];
        
        return chunk;
    }

    [self orderChildrenToLeftOn:ParentGO];
    
    return nil;
}

-(void)removeChunks
{
    fractionSprite=ParentGO.FractionSprite;
    //float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
    NSMutableArray *removeObj=[[NSMutableArray alloc]init];
    if([ParentGO.Chunks count]>0)
    {
        for(id<ConfigurableChunk> go in ParentGO.Chunks)
        {
            CCSprite *s=go.MySprite;
            // animate the existing chunks off to the side to make it look super duper awesome
            CCFadeOut *fadeAct=[CCFadeOut actionWithDuration:0.3f];
            CCAction *cleanUp=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
            CCSequence *sequence=[CCSequence actions:fadeAct, cleanUp, nil];
            [removeObj addObject:go];
            [s runAction:sequence];
        }
        
        [ParentGO.Chunks removeAllObjects];
        
        for (id go in removeObj)
        {
            [gameWorld delayRemoveGameObject:go];
        }
    
    }  

    [removeObj release];
}

-(void)ghostChunk
{
    fractionSprite=ParentGO.FractionSprite;
    int adjMarkerPos=ParentGO.MarkerPosition+1;
    float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
    
    if([ParentGO.GhostChunks count]>0)
    {
        for(CCSprite *s in ParentGO.GhostChunks)
        {
            // animate the existing chunks off to the side to make it look super duper awesome
            CCFadeOut *fadeAct=[CCFadeOut actionWithDuration:0.3f];
            CCAction *cleanUp=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
            CCSequence *sequence=[CCSequence actions:fadeAct, cleanUp, nil];
            [s runAction:sequence];
        }
    }
    
    [ParentGO.GhostChunks removeAllObjects];
    
    for(int i=0;i<adjMarkerPos;i++)
    {
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/separator.png")];
        //float xPos=fractionSprite.position.x+(fractionSprite.contentSize.width/2);
        float sectionSize=fractionSprite.contentSize.width/adjMarkerPos;
        
        //[s setPosition:ccp(xPos, fractionSprite.position.y)];
        [s setPosition:ccp(leftPos+((i+1)*sectionSize),0)];
        [ParentGO.BaseNode addChild:s];
        //[s runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(leftPos+((i+1)*sectionSize),0)]];
        [s runAction:[CCFadeIn actionWithDuration:0.3f]];
        [ParentGO.GhostChunks addObject:s];
    }
}

-(void)changeChunk:(id<ConfigurableChunk>)thisChunk toBelongTo:(id<Interactive>)newFraction
{
    id<Interactive> oldFraction=thisChunk.CurrentHost;
    
    //
    
    [oldFraction.Chunks removeObject:thisChunk];
    thisChunk.CurrentHost=newFraction;
    [newFraction.Chunks addObject:thisChunk];
//    [self orderStepChildrenToRightOn:(id<Configurable,Interactive>)newFraction];
    [self orderChildrenToLeftOn:(id<Configurable,Interactive>)newFraction];
}

-(void)orderStepChildrenToRightOn:(id<Configurable,Interactive>)newFraction
{
    fractionSprite=newFraction.FractionSprite;
    int amountOfChunksThatDontBelongHere=0;
    int amountIveReorderedSoFar=0;
    float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
    float widthOfFraction=fractionSprite.contentSize.width;
    
    for(id<ConfigurableChunk> go in newFraction.Chunks)
    {
        if(go.CurrentHost!=go.MyParent)
            amountOfChunksThatDontBelongHere++;
            
    }
    
    for(id<ConfigurableChunk> go in newFraction.Chunks)
    {
        CGPoint myNewPos=ccp((leftPos+widthOfFraction)-(amountIveReorderedSoFar*go.MySprite.contentSize.width),fractionSprite.position.y);
        
        if(go.CurrentHost!=go.MyParent)
        {
            NSLog(@"thisPos: %@", NSStringFromCGPoint(myNewPos));
            [go.MySprite setPosition:[newFraction.BaseNode convertToWorldSpace:myNewPos]];
            
            amountIveReorderedSoFar++;
        }
        
    }
}

-(void)orderChildrenToLeftOn:(id<Configurable,Interactive>)newFraction
{
    fractionSprite=newFraction.FractionSprite;
//    int amountOfChunksThatBelongHere=0;
    int amountIveReorderedSoFar=0;
    float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);

//    for(id<ConfigurableChunk> go in newFraction.Chunks)
//    {
//        if(go.CurrentHost==go.MyParent)
//            amountOfChunksThatBelongHere++;
//        
//    }
    
    for(id<ConfigurableChunk> go in newFraction.Chunks)
    {
        //float adjLeftPos=leftPos+(go.MySprite.contentSize.width/2);
        //CGPoint myNewPos=ccp(adjLeftPos+(amountIveReorderedSoFar*(go.MySprite.contentSize.width*go.MySprite.scaleX)),fractionSprite.position.y);
        
        float halfOfChunk=(go.MySprite.contentSize.width*go.MySprite.scaleX)/2;
        float posOnFraction=fractionSprite.contentSize.width/(newFraction.MarkerPosition+1);
        float adjPosOnFraction=posOnFraction*[newFraction.Chunks indexOfObject:go];
//        float adjPosOnFraction=posOnFraction*[newFraction.Chunks indexOfObject:go];
        
        CGPoint myNewPos=ccp(leftPos+halfOfChunk+adjPosOnFraction,fractionSprite.position.y);
        
//        myNewPos=[newFraction.BaseNode convertToWorldSpace:myNewPos];
        
//        if(go.CurrentHost==go.MyParent)
//        {
            [go.MySprite setPosition:[newFraction.BaseNode convertToWorldSpace:myNewPos]];
            go.Position=myNewPos;
            amountIveReorderedSoFar++;
//        }
        
    }    
}

@end
