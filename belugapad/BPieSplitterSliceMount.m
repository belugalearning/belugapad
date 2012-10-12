//
//  BPieSplitterSliceMount.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceMount.h"
#import "DWPieSplitterSliceGameObject.h"
#import "DWPieSplitterPieGameObject.h"
#import "DWPieSplitterContainerGameObject.h"
#import "global.h"
#import "SimpleAudioEngine.h"

@implementation BPieSplitterSliceMount

-(BPieSplitterSliceMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterSliceMount*)[super initWithGameObject:aGameObject withData:data];
    slice=(DWPieSplitterSliceGameObject*)gameObject;
    
    NSMutableArray *mo=[[NSMutableArray alloc] init];
    GOS_SET(mo, MOUNTED_OBJECTS);
    [mo release];
    
    return self;
}
-(void)doUpdate:(ccTime)delta
{

}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMount)
    {
        [self mountMeToContainer];
    }
    if(messageType==kDWunsetMount)
    {
        [self unMountMeFromContainer];
    }
}

-(void)mountMeToContainer
{
    if(slice.myCont){
        [slice.myCont handleMessage:kDWunsetMountedObject];
        slice.myCont=nil;
    }
    
    if(gameWorld.Blackboard.DropObject)
    {

        slice.myCont=gameWorld.Blackboard.DropObject;      
        DWPieSplitterContainerGameObject *c=(DWPieSplitterContainerGameObject*)slice.myCont;
        DWPieSplitterPieGameObject *p=(DWPieSplitterPieGameObject*)slice.myPie;
        
        
        //flip ownership of the sprite from the pie to the container
        [slice.mySprite removeFromParentAndCleanup:YES];
        slice.mySprite=nil;
        slice.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(slice.SpriteFileName)];
        [slice.mySprite runAction:[CCRotateTo actionWithDuration:0.5f angle:(360/p.numberOfSlices)*[c.mySlices count]]];

        
        [p.slicesInMe removeObject:slice];
        
        BOOL GotPlaceInNode;
        
        if(!c.Nodes)c.Nodes=[[[NSMutableArray alloc]init] autorelease];
        if([c.Nodes count]==0)
        {
            CCNode *thisNode=[[CCNode alloc]init];
            [c.Nodes addObject:thisNode];
            [c.BaseNode addChild:thisNode];
            [thisNode addChild:slice.mySprite];
            [thisNode release];
        }
        else {
            for(CCNode *n in c.Nodes)
            {
                if([n.children count]<[p.mySlices count])
                {
                    [n addChild:slice.mySprite];
                    return;
                }
                if([n.children count]==[p.mySlices count])
                {
                    CGPoint adjPos=ccp(0,0);
                    [n setPosition:ccp(adjPos.x, adjPos.y-(10*([c.Nodes indexOfObject:n]+1)))];
                    for(CCSprite *s in n.children)
                    {
                        [s setOpacity:150];
                    }
                }
            }
            
            if(!GotPlaceInNode)
            {
                CCNode *thisNode=[[CCNode alloc]init];
                [c.Nodes addObject:thisNode];
                [c.BaseNode addChild:thisNode];
                [thisNode addChild:slice.mySprite];
                [thisNode release];

            }
        
        }
    
    }
}
-(void)unMountMeFromContainer
{
    DWPieSplitterPieGameObject *p=(DWPieSplitterPieGameObject*)slice.myPie; 
    DWPieSplitterContainerGameObject *c=(DWPieSplitterContainerGameObject*)slice.myCont;
    [slice.mySprite removeFromParentAndCleanup:YES];
    slice.mySprite=nil;
    slice.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(slice.SpriteFileName)];
    [p.mySprite addChild:slice.mySprite];
    [slice.mySprite setPosition:[slice.mySprite.parent convertToNodeSpace:slice.Position]];
    [p.slicesInMe addObject:slice];
    
    // remove dead nodes from teh nodes array
    NSMutableArray *deleteNodes=[[NSMutableArray alloc]init];
    for(CCNode *n in c.Nodes)
    {
        if([n.children count]==0)
        {
            [deleteNodes addObject:n];
        }
    }
    
    if([deleteNodes count]>0)[c.Nodes removeObjectsInArray:deleteNodes];
    [deleteNodes release];

    // and after they're removed - loop BACK through - repositioning the stacks
    
    for(CCNode *n in c.Nodes)
    {
        if([n.children count]==[p.mySlices count])
        {
            // if there's only 1 node then set opacity to full
            if([c.Nodes count]<=1){
                [n setPosition:ccp(0,0)];
                for(CCSprite *s in n.children)
                {
                    [s setOpacity:255];
                }
            }
            else {
                // otherwise order them accordingly 
                
                // and if it's the last in the array, it'll be at the top, so set totally opaque
                if([c.Nodes indexOfObject:n]==[c.Nodes count]-1)
                {
                    [n setPosition:ccp(0,0)];
                    for(CCSprite *s in n.children)
                    {
                        [s setOpacity:255];
                    }
                }
                // but if it's not, leave it tinted
                else {
                    CGPoint adjPos=ccp(0,0);
                    [n setPosition:ccp(adjPos.x, adjPos.y-(10*([c.Nodes indexOfObject:n]+1)))];
                    for(CCSprite *s in n.children)
                    {
                        [s setOpacity:150];
                    }
                }
            }

        }
    }
    
    slice.myCont=nil;
}

-(void)dealloc
{
    
    [super dealloc];
}
@end
