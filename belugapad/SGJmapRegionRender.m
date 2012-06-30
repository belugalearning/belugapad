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

@implementation SGJmapRegionRender

-(SGJmapRegionRender*)initWithGameObject:(SGJmapRegion*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kSGreadyRender)
    {
        [self readyRender];
    }
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)readyRender
{
    NSLog(@"ready to render region with %d mastery children", ParentGO.MasteryNodes.count);
    
    //===== get my position =============================================================
    float cumx=0.0f, cumy=0.0f;
    for(SGJmapMasteryNode *mnode in ParentGO.MasteryNodes)
    {
        cumx+=mnode.Position.x;
        cumy+=mnode.Position.y;
    }
    
    ParentGO.Position=CGPointMake(cumx / (float)ParentGO.MasteryNodes.count, cumy / (float)ParentGO.MasteryNodes.count);
    
    
    //====== create list of vertices, sorted from mastery nodes =========================
    NSMutableArray *verts=[[NSMutableArray alloc] init];
    
    //collect points from childen and sort on the way
    for(SGJmapMasteryNode *mnode in ParentGO.MasteryNodes)
    {
        if(verts.count==0)
        {
            [verts addObject:[NSValue valueWithCGPoint:mnode.Position]];
        }
        else {
            float thisA=[BLMath angleFromNorthToLineFrom:ParentGO.Position to:mnode.Position];
            for(int i=0; i<verts.count; i++)
            {
                int insertat=0;
                BOOL doinsert=NO;
                
                CGPoint snodePos=[[verts objectAtIndex:i] CGPointValue];
                float nextA=[BLMath angleFromNorthToLineFrom:ParentGO.Position to:snodePos];
                
                if(nextA>thisA)
                {
                    //angle of next item in verts is greater, so insert before
                    doinsert=YES;
                    insertat=i;
                }
                else if(i==verts.count-1)
                {
                    //no more angles to compare to, so default insert last
                    doinsert=YES;
                    insertat=verts.count;
                }
                
                if(doinsert)
                {
                    [verts insertObject:[NSValue valueWithCGPoint:snodePos] atIndex:insertat];
                    break;
                }
            }
        }
    }
    
    //====== insert spacers as required ===============================================
    
    
    //====== malloc array for points themselves =======================================
    
    
    
    //====== iterate verts, scale up & out and add to the malloc'd array to render ====
    
    
    

}

-(void)draw:(int)z
{
}

-(void)dealloc
{
    
    [super dealloc];
}


@end
