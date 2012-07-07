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
#import "global.h"

static ccColor4B userCol={80, 110, 146, 255};
static ccColor4B userCol2={120, 168, 221, 255};
//static ccColor4B userCol={101, 140, 153, 255};
//static ccColor4B userCol={0, 51, 98, 255};
//static ccColor4B userCol={150,90,200,255};
//static ccColor4B userCol={150,90,200,255};
static ccColor4B userHighCol={255, 255, 255, 50};
//static ccColor4B userHighCol={239,119,82,255};
static int shadowSteps=10;

@interface SGJmapMasteryNodeRender()
{
    CCSprite *nodeSprite;
    CCSprite *labelSprite;
}

@end

@implementation SGJmapMasteryNodeRender

-(SGJmapMasteryNodeRender*)initWithGameObject:(id<Transform, CouchDerived>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=(SGJmapMasteryNode*)aGameObject;
        
        //[self setup];
        
        zoomedOut=NO;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    if(messageType==kSGreadyRender)
    {
        [self readyRender];
    }
    
    else if(messageType==kSGvisibilityChanged)
    {
        nodeSprite.visible=ParentGO.Visible;
        labelSprite.visible=ParentGO.Visible;
    }
    
    if(messageType==kSGzoomOut)
    {
        [self setPointScalesAt:REGION_ZOOM_LEVEL];
        [nodeSprite setVisible:NO];
        [labelSprite setVisible:NO];
        ParentGO.Visible=YES;
        zoomedOut=YES;
    }
    if(messageType==kSGzoomIn)
    {
        [self setPointScalesAt:1.0f];
        zoomedOut=NO;
    }
}

-(void)doUpdate:(ccTime)delta
{

}

-(void)draw:(int)z
{
    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
    
    if(z==1)
    {
        //upate position of all polys
        CGPoint adjPoints[shadowSteps*sortedChildren.count];
        for (int i=0; i<(shadowSteps*sortedChildren.count); i++) {
            adjPoints[i]=[BLMath AddVector:myWorldPos toVector:scaledPerimPoints[i]];
        }
        
        //perim polys -- overlapping
        for(int ip=(zoomedOut ? shadowSteps-1 : 0); ip<shadowSteps; ip++)
        {
            CGPoint *first=&adjPoints[(ip==0) ? 0 : (ip*sortedChildren.count)-1];
            
            ccColor4F col=ccc4FFromccc4B(stepColours[ip]);
            if(zoomedOut) col=ccc4f(col.r, col.g, col.b, 0.3f);
            
            ccDrawFilledPoly(first, sortedChildren.count, ccc4FFromccc4B(stepColours[ip]));
        }
        
        if(!zoomedOut)
        {
            for (id<Transform> prnode in ParentGO.ChildNodes) {
                //world space pos of child node
                CGPoint theirWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:prnode.Position];
                
                //draw prereq path to this node        
                ccDrawColor4B(userHighCol.r, userHighCol.g, userHighCol.b, userHighCol.a);
                ccDrawLine(myWorldPos, theirWorldPos);        
            }
        }
    }
    else if (z==2)
    {
        
        ccColor4F f4=ccc4FFromccc4B(currentCol);
        
        //lines to inter mastery nodes
        for(id<Transform> imnode in ParentGO.ConnectToMasteryNodes) {
            //world space of their pos
            CGPoint tWP=[ParentGO.RenderBatch.parent convertToWorldSpace:imnode.Position];
            
//            ccDrawColor4B(userCol.r, userCol.g, userCol.b, userCol.a);
//            ccDrawLine(myWorldPos, tWP);
            
            float x1=myWorldPos.x;
            float y1=myWorldPos.y;
            float x2=tWP.x;
            float y2=tWP.y;
            
            float L=sqrtf((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
            
            int lines=5;
            if(zoomedOut) lines=1;
            
            for (float width=-lines; width<(lines+1); width+=0.75f)
            {
                float x1p=x1+width * (y2-y1) / L;
                float x2p=x2+width * (y2-y1) / L;
                float y1p=y1+width * (x1-x2) / L;
                float y2p=y2+width * (x1-x2) / L;
                
                if(zoomedOut) ccDrawColor4F(f4.r, f4.g, f4.b, 0.15f);
                else ccDrawColor4F(f4.r, f4.g, f4.b, 0.35f);
                
                ccDrawLine(ccp(x1p, y1p), ccp(x2p, y2p));
            }
            
        }    
    }
}

-(void)setup
{
    
}

-(void)readyRender
{
    if(ParentGO.EnabledAndComplete)
    {
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"mastery-complete.png"];
    }
    else
    {
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"mastery-incomplete.png"];        
    }
    [nodeSprite setPosition:[BLMath AddVector:ParentGO.Position toVector:ccp(0, 50)]];
    [nodeSprite setVisible:ParentGO.Visible];
    if(ParentGO.Disabled) [nodeSprite setOpacity:100];
    [ParentGO.RenderBatch addChild:nodeSprite];
    
    labelSprite=[CCLabelTTF labelWithString:ParentGO.UserVisibleString fontName:@"Helvetica" fontSize:14.0f];
    [labelSprite setPosition:ccpAdd(ccp(0, -40), ParentGO.Position)];
    [labelSprite setVisible:ParentGO.Visible];
    if(ParentGO.Disabled) [labelSprite setOpacity:100];
    [ParentGO.RenderBatch.parent addChild:labelSprite];
    
    sortedChildren=[[NSMutableArray alloc] init];
 
    float r=userCol.r + (userCol2.r - userCol.r) * (ParentGO.PrereqPercentage / 100.0f);
    float g=userCol.g + (userCol2.g - userCol.g) * (ParentGO.PrereqPercentage / 100.0f);
    float b=userCol.b + (userCol2.b - userCol.b) * (ParentGO.PrereqPercentage / 100.0f);
    currentCol=ccc4(r, g, b, 255);
    
    //sort children
    for (id<Transform> prnode in ParentGO.ChildNodes) {
        float thisA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:prnode.Position] toMaxLength:1.0f]];
        
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
    
    if(sortedChildren.count==0)return;
    
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
    
    
    //================ calculate interior polys for drop shadow =============================
    //perim points
    CGPoint perimPoints[sortedChildren.count];
    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
    int perimIx=0;

    for (NSValue *cPosVal in sortedChildren) {
        //world space pos of child node
        CGPoint theirWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:[cPosVal CGPointValue]];
        
        //add to perim
        //get vector from here to there
        CGPoint vdiff=[BLMath SubtractVector:myWorldPos from:theirWorldPos];
        CGPoint ediff=[BLMath MultiplyVector:vdiff byScalar:1.5f];
        //CGPoint dest=[BLMath AddVector:ediff toVector:myWorldPos];
        
        perimPoints[perimIx]=ediff;
        perimIx++;
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
    
    ccColor4B stepColour=currentCol;
    stepColour.r=stepColour.r-5;
    stepColour.g=stepColour.g-5;
    stepColour.b=stepColour.b-10;
    if(stepColour.r>currentCol.r)stepColour.r=0;
    if(stepColour.g>currentCol.g)stepColour.g=0;
    if(stepColour.b>currentCol.b)stepColour.b=0;
    
    //step the colours
    for(int i=0; i<shadowSteps; i++)
    {
        stepColours[i]=stepColour;
        
        //adjust colour
        if(stepColour.r<252) stepColour.r+=0.5f;
        if(stepColour.g<252) stepColour.g+=0.5f;
        if(stepColour.b<252) stepColour.b+=1;
    }
    
    //create the total perim array -- polys * points
    
    //NSLog(@"mallocing at size %d with count %d for total %d", (int)(sizeof(CGPoint) * shadowSteps * sortedChildren.count), sortedChildren.count, shadowSteps*sortedChildren.count);
    
    allPerimPoints=malloc(sizeof(CGPoint) * shadowSteps * sortedChildren.count);
    scaledPerimPoints=malloc(sizeof(CGPoint) * shadowSteps * sortedChildren.count);
    
    //step the poly creation
    for(int ip=0; ip<shadowSteps; ip++)
    {
        for(int i=0; i<sortedChildren.count; i++)
        {
            CGPoint diff=[BLMath SubtractVector:pmid from:perimPoints[i]];
            CGPoint neardiff=[BLMath MultiplyVector:diff byScalar:(1-(0.01 * (ip+1)))];
            CGPoint aPos=[BLMath AddVector:neardiff toVector:pmid];
            //CGPoint prelPos=[BLMath SubtractVector:ParentGO.Position from:aPos];
            CGPoint newpos=aPos;
            
            int insertChildPos=ip*sortedChildren.count;
            if(ip>0)insertChildPos-=1;
            
            int actualinsert=insertChildPos+i;
            
            //NSLog(@"inserting at %d", actualinsert);
            allPerimPoints[actualinsert]=newpos;
            
            //allPerimPoints[(ip==0 ? 0 : ((ip*shadowSteps)-1))+i]=newpos;
        }
    }
    
    //=======================================================================================
    
    [self setPointScalesAt:1.0f];
    
}

-(void)setPointScalesAt:(float)scale
{
    for(int i=0;i<(sortedChildren.count * shadowSteps); i++)
    {
        scaledPerimPoints[i]=[BLMath MultiplyVector:allPerimPoints[i] byScalar:scale];
    }
}


-(void)dealloc
{
    free(allPerimPoints);
    free(scaledPerimPoints);
    
    [sortedChildren release];
    
    [super dealloc];
}

@end
