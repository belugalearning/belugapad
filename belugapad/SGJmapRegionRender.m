//
//  SGJmapRegionRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapRegionRender.h"
#import "SGJmapRegion.h"
#import "SGJmapMasteryNode.h"
#import "BLMath.h"
#import "global.h"

@implementation SGJmapRegionRender

-(SGJmapRegionRender*)initWithGameObject:(SGJmapRegion*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    if(messageType==kSGreadyRender)
    {
        [self readyRender];
    }
    
    if(messageType==kSGzoomOut)
    {
        [self setPointScalesAt:REGION_ZOOM_LEVEL];
        [rlabel runAction:[CCFadeIn actionWithDuration:0.5f]];
        [rlabelshadow runAction:[CCFadeIn actionWithDuration:0.75f]];
        
    }
    if(messageType==kSGzoomIn)
    {
        [self setPointScalesAt:1.0f];
        [rlabel runAction:[CCFadeOut actionWithDuration:0.25f]];
        [rlabelshadow runAction:[CCFadeOut actionWithDuration:0.15f]];    }
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)setPointScalesAt:(float)scale
{
    for(int i=0;i<perimCount; i++)
    {
        scaledPerimPoints[i]=[BLMath MultiplyVector:allPerimPoints[i] byScalar:scale];
    }
}

-(void)readyRender
{
    //disabling for the moment
//    return;
    
    //NSLog(@"ready to render region with %d mastery children", ParentGO.MasteryNodes.count);
    
    //===== get my position =============================================================
    float cumx=0.0f, cumy=0.0f;
    
    //crate avg node using node positions relative to first node -- then offset the original by the same amount
    CGPoint firstPos=ccp(0,0);
    if(ParentGO.MasteryNodes.count>0) firstPos=((SGJmapMasteryNode*)[ParentGO.MasteryNodes objectAtIndex:0]).Position;

    for(SGJmapMasteryNode *mnode in ParentGO.MasteryNodes)
    {
        CGPoint npos=[BLMath SubtractVector:firstPos from:mnode.Position];
        cumx+=npos.x;
        cumy+=npos.y;
    }
    
    CGPoint relpos=CGPointMake(cumx / (float)ParentGO.MasteryNodes.count, cumy / (float)ParentGO.MasteryNodes.count);
    ParentGO.Position=[BLMath AddVector:relpos toVector:firstPos];

    //NSLog(@"set my position to %@", NSStringFromCGPoint(ParentGO.Position));
    
    //====== region label ===============================================================

    rlabelshadow=[CCLabelTTF labelWithString:ParentGO.Name fontName:@"Chango" fontSize:22.0f];
    [rlabelshadow setScale:1 / REGION_ZOOM_LEVEL];
    [rlabelshadow setPosition:ccpAdd(ParentGO.Position, ccp(0, -10))];
    [rlabelshadow setColor:ccc3(0, 0, 0)];
    [rlabelshadow setOpacity:0];
    [ParentGO.RenderBatch.parent addChild:rlabelshadow z:5];
    
    rlabel=[CCLabelTTF labelWithString:ParentGO.Name fontName:@"Chango" fontSize:22.0f];
    [rlabel setScale:1 / REGION_ZOOM_LEVEL];
    [rlabel setPosition:ParentGO.Position];
    [rlabel setColor:ccc3(255, 255, 255)];
    [rlabel setOpacity:0];
    [ParentGO.RenderBatch.parent addChild:rlabel z:5];
    
    
//    //====== create list of vertices, sorted from mastery nodes =========================
//    NSMutableArray *verts=[[NSMutableArray alloc] init];
//    
//    //collect points from childen and sort on the way
//    for(SGJmapMasteryNode *mnode in ParentGO.MasteryNodes)
//    {
//        if(verts.count==0)
//        {
//            [verts addObject:[NSValue valueWithCGPoint:mnode.Position]];
//        }
//        else {
//            float thisA=[BLMath angleFromNorthToLineFrom:ParentGO.Position to:mnode.Position];
//            for(int i=0; i<verts.count; i++)
//            {
//                int insertat=0;
//                BOOL doinsert=NO;
//                
//                CGPoint snodePos=[[verts objectAtIndex:i] CGPointValue];
//                float nextA=[BLMath angleFromNorthToLineFrom:ParentGO.Position to:snodePos];
//                
//                if(nextA>thisA)
//                {
//                    //angle of next item in verts is greater, so insert before
//                    doinsert=YES;
//                    insertat=i;
//                }
//                else if(i==verts.count-1)
//                {
//                    //no more angles to compare to, so default insert last
//                    doinsert=YES;
//                    insertat=verts.count;
//                }
//                
//                if(doinsert)
//                {
//                    [verts insertObject:[NSValue valueWithCGPoint:mnode.Position] atIndex:insertat];
//                    break;
//                }
//            }
//        }
//    }
//    
////    for (NSValue *vp in verts) {
////        NSLog(@"point at %@", NSStringFromCGPoint([vp CGPointValue]));
////    }
//    
//    //====== insert spacers as required ===============================================
//    BOOL looking=YES;
//    do {
//        //step all verts
//        for(int i=0;i<verts.count;i++)
//        {
//            CGPoint thisP=[[verts objectAtIndex:i] CGPointValue];
//            float thisA=[BLMath angleFromNorthToLineFrom:ParentGO.Position to:thisP];
//            
//            CGPoint nextP;
//            float nextA;
//            if(i==verts.count-1)
//            {
//                //at last node, use first
//                nextP=[[verts objectAtIndex:0] CGPointValue];
//                nextA=360.0f+[BLMath angleFromNorthToLineFrom:ParentGO.Position to:nextP];
//            }
//            else {
//                nextP=[[verts objectAtIndex:i+1] CGPointValue];
//                nextA=[BLMath angleFromNorthToLineFrom:ParentGO.Position to:nextP];
//            }
//            
//            if((nextA-thisA) > 8.0f)
//            {
//                float lOfV=0.9f * [BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:thisP]];
//                float newRot=thisA + ((nextA-thisA)*0.35);
//                
//                CGPoint newPos=[BLMath AddVector:ParentGO.Position toVector:[BLMath ProjectMovementWithX:0 andY:lOfV forRotation:newRot]];
//                
//                if(newRot>=360.0f)
//                {
//                    [verts insertObject:[NSValue valueWithCGPoint:newPos] atIndex:0];
//                }
//                else {
//                    [verts insertObject:[NSValue valueWithCGPoint:newPos] atIndex:i+1];
//                }
//                
//                break;
//            }
//            
//            
//            //stop looking when one from end -- added hard stop at 100 (calculation overflow error in some datasets)
//            if(i==verts.count-1 || verts.count>100)
//            {
//                looking=NO;
//            }
//            
//        }
//    } while (looking);
//    
////    for (NSValue *vp in verts) {
////        NSLog(@"point or spacer at %@", NSStringFromCGPoint([vp CGPointValue]));
////    }
//    
//    //====== malloc array for points themselves =======================================
//    
//    allPerimPoints=malloc(sizeof(CGPoint) * verts.count);
//    scaledPerimPoints=malloc(sizeof(CGPoint) * verts.count);
//    perimCount=verts.count;
//    
//    
//    //====== iterate verts, scale up & out and add to the malloc'd array to render ====
//    //CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
//    CGPoint myWorldPos=ParentGO.Position;
//    
//    for (int i=0; i<verts.count; i++)
//    {
//        CGPoint p=[[verts objectAtIndex:i] CGPointValue];
//        //CGPoint pWP=[ParentGO.RenderBatch.parent convertToWorldSpace:p];
//        
//        CGPoint ep=[BLMath MultiplyVector:[BLMath SubtractVector:myWorldPos from:p] byScalar:2.5f];
//        allPerimPoints[i]=ep;
//        
//        //NSLog(@"extended point %@ at index %d", NSStringFromCGPoint(ep), i);
//    }
//
//    [self setPointScalesAt:1.0f];
//    
//    [verts release];
}

-(void)draw:(int)z
{
//    //disabling for the moment
////    return;
//    
//    if(z==0)
//    {
//        CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
//
//        CGPoint adjPoints[perimCount];
//        for(int i=0; i<perimCount; i++)
//        {
//            adjPoints[i]=[BLMath AddVector:myWorldPos toVector:scaledPerimPoints[i]];
//        }
//        
//        CGPoint *f=&adjPoints[0];
//        float incr=(ParentGO.RegionNumber+2) * 0.005f;
//        
//        ccColor4F c=ccc4FFromccc3B(ccc3(80, 110, 146));
//        
//        //todo: not doing with cocos2.1 -- needs replacing with CCDrawNode
//        //ccDrawFilledPoly(f, perimCount, ccc4f(c.r+incr, c.g+incr, c.b+(incr*2.0f), 1.0f));
//    }
}

-(void)dealloc
{
//    free(allPerimPoints);
//    free(scaledPerimPoints);
    
    [super dealloc];
}


@end
