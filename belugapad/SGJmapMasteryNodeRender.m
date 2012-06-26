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

static ccColor4B userCol={241,90,36,255};
static ccColor4B userHighCol={239,119,82,255};

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
    if(messageType==kSGreadyRender)
    {
        [self readyRender];
    }
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)draw
{
    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
 
    //perim points
    CGPoint perimPoints[sortedChildren.count];
    int perimIx=0;

    //lines to my child nodes
    for (NSValue *cPosVal in sortedChildren) {
        //world space pos of child node
        CGPoint theirWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:[cPosVal CGPointValue]];
        
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
        
        ccDrawColor4B(userCol.r, userCol.g, userCol.b, userCol.a);
        ccDrawLine(myWorldPos, tWP);
        
    }
    
    
    
    //get avg position of points
    float xmean=0.0f;
    float ymean=0.0f;
    for(int i=0; i<sortedChildren.count; i++)
    {
        xmean+=perimPoints[i].x;
        ymean+=perimPoints[i].y;
    }
    xmean=xmean/(float)sortedChildren.count;
    ymean=ymean/(float)sortedChildren.count;
    CGPoint pmid=ccp(xmean,ymean);
    
    ccColor4B stepColour=userCol;
    stepColour.r=stepColour.r-40;
    stepColour.g=stepColour.g-40;
    stepColour.b=stepColour.b-40;
    if(stepColour.r>userCol.r)stepColour.r=0;
    if(stepColour.g>userCol.g)stepColour.g=0;
    if(stepColour.b>userCol.b)stepColour.b=0;
    
    //draw first perim poly
    CGPoint *first=&perimPoints[0];
    ccDrawFilledPoly(first, sortedChildren.count, ccc4FFromccc4B(stepColour));

    //draw interior versions of poly
    for(int ip=0; ip<10; ip++)
    {
        for(int i=0; i<sortedChildren.count; i++)
        {
            CGPoint diff=[BLMath SubtractVector:pmid from:perimPoints[i]];
            CGPoint neardiff=[BLMath MultiplyVector:diff byScalar:0.99f];
            CGPoint newpos=[BLMath AddVector:neardiff toVector:pmid];
            perimPoints[i]=newpos;
        }
        
        //adjust colour
        if(stepColour.r<252) stepColour.r+=4;
        if(stepColour.g<252) stepColour.g+=4;
        if(stepColour.b<252) stepColour.b+=4;

        //draw poly
        CGPoint *first=&perimPoints[0];
        ccDrawFilledPoly(first, sortedChildren.count, ccc4FFromccc4B(stepColour));
    }
    

    for (id<Transform> prnode in ParentGO.ChildNodes) {
        //world space pos of child node
        CGPoint theirWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:prnode.Position];
        
        //draw prereq path to this node        
        ccDrawColor4B(userHighCol.r, userHighCol.g, userHighCol.b, userHighCol.a);
        ccDrawLine(myWorldPos, theirWorldPos);        
    }    
}

-(void)setup
{
    
}

-(void)readyRender
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
        float thisA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:prnode.Position] toMaxLength:1.0f]];
        
        if([ParentGO.UserVisibleString isEqualToString:@"counting forward"])
        {
            NSLog(@"counting forward");
        }
        
        if([sortedChildren count]==0)
        {
            //put this thing in the array at first position
            [sortedChildren addObject:[NSValue valueWithCGPoint:prnode.Position]];
        }
        else {
            //iterate sorted array, looking for something larger (in rotation), or the end -- then insert
            
            for(int i=0; i<sortedChildren.count; i++)
            {
                int insertat=0;
                BOOL doInsert=NO;
                
                CGPoint snodePos=[[sortedChildren objectAtIndex:i] CGPointValue];
                
                float nextA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:snodePos] toMaxLength:1.0f]];
                
                if(nextA>thisA)
                {
                    doInsert=YES;
                    insertat=i; //insert before node
                }
                else if (i==sortedChildren.count-1)
                {
                    doInsert=YES;
                    insertat=sortedChildren.count; //insert at end of list
                }
                    
                if(doInsert)
                {
                    //insert the node itself
                    [sortedChildren insertObject:[NSValue valueWithCGPoint:prnode.Position] atIndex:insertat];
                    
                    break;

                }
            }
            
            //on insert, if increment from last is > 135, add an additional psuedo item
        }
    }
    
    //iterate over sorted children repeatedly until we can't add any more spacers
    BOOL looking=YES;
    do {
        for (int i=0; i<sortedChildren.count; i++) {
            CGPoint thisP=[[sortedChildren objectAtIndex:i] CGPointValue];
            float thisA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:thisP] toMaxLength:1.0f]];
            
            CGPoint nextP;
            float nextA;
            if (i==sortedChildren.count-1) {
                //at end node, use position of first
                nextP=[[sortedChildren objectAtIndex:0] CGPointValue];
                nextA=360.0f + [BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:nextP] toMaxLength:1.0f]];
            }
            else {
                nextP=[[sortedChildren objectAtIndex:i+1] CGPointValue];
                nextA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:nextP] toMaxLength:1.0f]];
            }
            
            if((nextA-thisA) > 90.0f)
            {
                float lOfV=0.85f * [BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:thisP]];
                float newrot=thisA + ((nextA-thisA)*0.35f);
                //float newrot=thisA+ 50.0f;
                
                CGPoint newpos=[BLMath AddVector:ParentGO.Position toVector:[BLMath ProjectMovementWithX:0 andY:lOfV forRotation:newrot]];
                
                if(newrot>=360.0f)
                {
                    [sortedChildren insertObject:[NSValue valueWithCGPoint:newpos] atIndex:0];
                }
                else {
                    [sortedChildren insertObject:[NSValue valueWithCGPoint:newpos] atIndex:i+1];
                }
                    
                break;
            }
            
            //if we got to the last node and didn't add a spacer and break, stop looking for new spacer requirements
            if(i==sortedChildren.count-1)
            {
                looking=NO;    
            }
        }
    } while (looking);
    
    
    //
    
}

-(void)dealloc
{
    [sortedChildren release];
    
    [super dealloc];
}

@end
