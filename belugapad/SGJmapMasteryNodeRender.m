//
//  SGJmapMNodeRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapMasteryNodeRender.h"
#import "SGJmapMasteryNode.h"
#import "BLMath.h"

@interface SGJmapMasteryNodeRender()
{
    CCSprite *nodeSprite;
}

@end

@implementation SGJmapMasteryNodeRender

-(SGJmapMasteryNodeRender*)initWithGameObject:(id<Transform, CouchDerived>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=(SGJmapMasteryNode*)aGameObject;
        
        //[self setup];
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)draw
{
    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
 
    //perim points
    CGPoint perimPoints[ParentGO.ChildNodes.count];
    int perimIx=0;

    //lines to my child nodes
    for (id<Transform> prnode in ParentGO.ChildNodes) {
        //world space pos of child node
        CGPoint theirWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:prnode.Position];
        
        //draw prereq path to this node        
        ccDrawColor4B(255, 255, 255, 255);
        ccDrawLine(myWorldPos, theirWorldPos);        
        
        //add to perim
        //get vector from here to there
        CGPoint vdiff=[BLMath SubtractVector:myWorldPos from:theirWorldPos];
        CGPoint ediff=[BLMath MultiplyVector:vdiff byScalar:1.5f];
        CGPoint dest=[BLMath AddVector:ediff toVector:myWorldPos];
        
        perimPoints[perimIx]=dest;
        perimIx++;
    }
    
    //lines to inter mastery nodes
    for(id<Transform> imnode in ParentGO.ConnectToMasteryNodes) {
        //world space of their pos
        CGPoint tWP=[ParentGO.RenderBatch.parent convertToWorldSpace:imnode.Position];
        
        ccDrawColor4B(255, 0, 0, 100);
        ccDrawLine(myWorldPos, tWP);
    }
    
    
    //draw perim poly
    CGPoint *first=&perimPoints[0];
    ccDrawFilledPoly(first, ParentGO.ChildNodes.count,ccc4f(1.0f, 0.0f, 0.0f, 0.1f));
    
    
    //glLineWidth(6.0f);
//    ccDrawColor4B(255, 200, 200, 50);
//    ccDrawLine(myWorldPos, ccpAdd(myWorldPos, ccp(100,200)));
}

-(void)setup
{
    nodeSprite=[CCSprite spriteWithSpriteFrameName:@"mastery-incomplete.png"];
    [nodeSprite setPosition:ParentGO.Position];
    [ParentGO.RenderBatch addChild:nodeSprite];
    
    CCLabelTTF *label=[CCLabelTTF labelWithString:ParentGO.UserVisibleString fontName:@"Helvetica" fontSize:12.0f];
    [label setPosition:ccpAdd(ccp(0, -40), ParentGO.Position)];
    [ParentGO.RenderBatch.parent addChild:label];
    
    sortedChildren=[[[NSMutableArray alloc] init] retain];
    
    //sort children
    for (id<Transform> prnode in ParentGO.ChildNodes) {
        if([sortedChildren count]==0)
        {
            //put this thing in the array at first position
            [sortedChildren addObject:prnode];
        }
        else {
            //iterate sorted array, looking for something larger (in rotation), or the end -- then insert
            
            //on insert, if increment from last is > 135, add an additional psuedo item
        }
    }
}

-(void)dealloc
{
    [sortedChildren release];
    
    [super dealloc];
}

@end
