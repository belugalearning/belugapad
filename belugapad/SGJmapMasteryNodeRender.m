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

-(SGJmapMasteryNodeRender*)initWithGameObject:(id<Transform>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
        
        [self setup];
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
    SGJmapMasteryNode *mparent=(SGJmapMasteryNode*)ParentGO;
    
    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
 
    //perim points
    CGPoint perimPoints[mparent.ChildNodes.count];
    int perimIx=0;

    for (id<Transform> prnode in mparent.ChildNodes) {
        //world space pos of child node
        CGPoint theirWorldPos=[mparent.RenderBatch.parent convertToWorldSpace:prnode.Position];
        
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
    
    //draw perim poly
    CGPoint *first=&perimPoints[0];
    ccDrawFilledPoly(first, mparent.ChildNodes.count,ccc4f(1.0f, 0.0f, 0.0f, 0.1f));
    
    
    //glLineWidth(6.0f);
//    ccDrawColor4B(255, 200, 200, 50);
//    ccDrawLine(myWorldPos, ccpAdd(myWorldPos, ccp(100,200)));
}

-(void)setup
{
    nodeSprite=[CCSprite spriteWithSpriteFrameName:@"mastery-incomplete.png"];
    [nodeSprite setPosition:ParentGO.Position];
    [ParentGO.RenderBatch addChild:nodeSprite];
}

@end
