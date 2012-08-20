//
//  SGJmapMNodeRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapMasteryNodeRender.h"
#import "SGJmapMasteryNode.h"
#import "PRFilledPolygon.h"
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
static int shadowSteps=5;

@interface SGJmapMasteryNodeRender()
{
    CCSprite *nodeSprite;
    CCSprite *labelSprite;
}

@end

@implementation SGJmapMasteryNodeRender

@synthesize ParentGO, sortedChildren, allPerimPoints, scaledPerimPoints, zoomedOut;

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

    
//    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
    
    if(z==1)
    {
        //this was island base colour -- now in render node
    }
    else if (z==2)
    {
        
//        ccColor4F f4=ccc4FFromccc4B(currentCol);
//        
//        //lines to inter mastery nodes
//        for(id<Transform> imnode in ParentGO.ConnectToMasteryNodes) {
//            //world space of their pos
//            CGPoint tWP=[ParentGO.RenderBatch.parent convertToWorldSpace:imnode.Position];
//            
////            ccDrawColor4B(userCol.r, userCol.g, userCol.b, userCol.a);
////            ccDrawLine(myWorldPos, tWP);
//            
//            float x1=myWorldPos.x;
//            float y1=myWorldPos.y;
//            float x2=tWP.x;
//            float y2=tWP.y;
//            
//            float L=sqrtf((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
//            
//            int lines=5;
//            if(zoomedOut) lines=1;
//            
//            for (float width=-lines; width<(lines+1); width+=0.75f)
//            {
//                float x1p=x1+width * (y2-y1) / L;
//                float x2p=x2+width * (y2-y1) / L;
//                float y1p=y1+width * (x1-x2) / L;
//                float y2p=y2+width * (x1-x2) / L;
//                
//                if(zoomedOut) ccDrawColor4F(f4.r, f4.g, f4.b, 0.15f);
//                else ccDrawColor4F(f4.r, f4.g, f4.b, 0.35f);
//                
//                ccDrawLine(ccp(x1p, y1p), ccp(x2p, y2p));
//            }
//            
//        }    
    }
}

-(void)setup
{
    
}

-(void)readyRender
{
    
    sortedChildren=[[NSMutableArray alloc] init];
 
    float r=userCol.r + (userCol2.r - userCol.r) * (ParentGO.PrereqPercentage / 100.0f);
    float g=userCol.g + (userCol2.g - userCol.g) * (ParentGO.PrereqPercentage / 100.0f);
    float b=userCol.b + (userCol2.b - userCol.b) * (ParentGO.PrereqPercentage / 100.0f);
    currentCol=ccc4(r, g, b, 255);
    
    // ------- force points into bottom section of island ---------------------------------------------------
    
    //range of nodes is 140deg from 110 to 250 (direction doesn't matter here as they're sorted later)
    
    for(id<Transform>prnode in ParentGO.ChildNodes)
    {
        CGPoint diff=[BLMath SubtractVector:ParentGO.Position from:prnode.Position];
        float startAngle=[BLMath angleForVector:diff];
        float startLength=[BLMath LengthOfVector:diff];
        float angleInRange=startAngle * (140.0f / 360.0f) + 110.0f;
        CGPoint newPos=[BLMath AddVector:[BLMath ProjectMovementWithX:0 andY:startLength forRotation:angleInRange] toVector:ParentGO.Position];
        prnode.Position=newPos;
        
//        NSLog(@"parentGO.pos %@ prnode pos %@", NSStringFromCGPoint(ParentGO.Position), NSStringFromCGPoint(prnode.Position));
//        NSLog(@"diff is %@, startAngle %f, startLength %f, angleInRange %f, newPos %@", NSStringFromCGPoint(diff), startAngle, startLength, angleInRange, NSStringFromCGPoint(newPos));
    }
    
    // ------------------------------------------------------------------------------------------------------
    
    
    
    //sort children
    for (id<Transform> prnode in ParentGO.ChildNodes) {
        //NSLog(@"parentGO.pos %@ prnode pos %@", NSStringFromCGPoint(ParentGO.Position), NSStringFromCGPoint(prnode.Position));
        
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
    
    //insert top positions?

    float ildwidth= 30 + (2 * ParentGO.UserVisibleString.length);
    
    [sortedChildren insertObject:[NSValue valueWithCGPoint:[BLMath AddVector:ParentGO.Position toVector:ccp(-ildwidth, 10)]] atIndex:0];
//    [sortedChildren insertObject:[NSValue valueWithCGPoint:[BLMath AddVector:ParentGO.Position toVector:ccp(0, 10)]] atIndex:0];
    [sortedChildren insertObject:[NSValue valueWithCGPoint:[BLMath AddVector:ParentGO.Position toVector:ccp(ildwidth, 10)]] atIndex:0];
    
    //big spacers
    [self insertSpacerPointsWithRotGap:40.0f andScale:1.25f];
    
    //[self insertSpacerPointsWithRotGap:10.0f andScale:1.0f];
    
    //start smooth from avg
//    float avgL=0.0f;
//    for (NSValue *p in sortedChildren)
//    {
//        float l=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:[p CGPointValue]]];
//        avgL+=l;
//    }
//    avgL=avgL / (float)sortedChildren.count;
//    

    //start smooth from max
    float avgL=0.0f;
    for (NSValue *p in sortedChildren)
    {
        float l=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:[p CGPointValue]]];
        if(l>avgL)avgL=l;
    }
    avgL=avgL*1.25f;
    //avgL=avgL / (float)sortedChildren.count;
    
    
    float seekr=110.0f;
    
    NSMutableArray *newChildren=[[NSMutableArray alloc] init];
    for(int r=0; r<360; r+=2)
    {
        float newL=avgL;
        
        //look for close rotations and adjust
        for (NSValue *p in sortedChildren)
        {
            CGPoint inspd=[BLMath SubtractVector:ParentGO.Position from:[p CGPointValue]];
            float inspr=[BLMath angleForVector:inspd];
            
            float rdiff=fabsf(inspr-r);
            if(inspr<seekr && r>(360-seekr)) rdiff=fabsf((inspr+360) - r);
            if(r<seekr && inspr>(360-seekr)) rdiff=fabsf(inspr - (360+r));

            if(rdiff<seekr)
            {
                float inspl=[BLMath LengthOfVector:inspd];
                newL=newL+((inspl-newL) * ((seekr-rdiff) / seekr));
            }
        }
        
        CGPoint pos=[BLMath AddVector:ParentGO.Position toVector:[BLMath ProjectMovementWithX:0 andY:newL forRotation:r]];
        [newChildren addObject:[NSValue valueWithCGPoint:pos]];
    }
    
    [sortedChildren release];
    sortedChildren=newChildren;
    
    
    //================ calculate interior polys for drop shadow =============================
    //perim points
    CGPoint perimPoints[sortedChildren.count];
    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
    int perimIx=0;
    
    //CGPoint offsetForTexture=[BLMath SubtractVector:myWorldPos from:ParentGO.Position];

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

    // === stepping colour creation -- not used currently due to fixed colouring of islands ===
//    ccColor4B stepColour=currentCol;
//    stepColour.r=stepColour.r-5;
//    stepColour.g=stepColour.g-5;
//    stepColour.b=stepColour.b-10;
//    if(stepColour.r>currentCol.r)stepColour.r=0;
//    if(stepColour.g>currentCol.g)stepColour.g=0;
//    if(stepColour.b>currentCol.b)stepColour.b=0;
//    
//    //step the colours
//    for(int i=0; i<shadowSteps; i++)
//    {
//        stepColours[i]=stepColour;
//        
//        //adjust colour
//        if(stepColour.r<252) stepColour.r+=3.5f;
//        if(stepColour.g<252) stepColour.g+=3.5f;
//        if(stepColour.b<252) stepColour.b+=7;
//    }
    // =========================================================================================
    
    //create the total perim array -- polys * points
    allPerimPoints=malloc(sizeof(CGPoint) * shadowSteps * sortedChildren.count);
    scaledPerimPoints=malloc(sizeof(CGPoint) * shadowSteps * sortedChildren.count);
    
    texturePoints=[[NSMutableArray alloc] init];
    
    //step the poly creation
    for(int ip=0; ip<shadowSteps; ip++)
    {
        for(int i=0; i<sortedChildren.count; i++)
        {
            CGPoint diff=[BLMath SubtractVector:pmid from:perimPoints[i]];
            
            CGPoint neardiff=CGPointZero;
            if(ip<3) // first two blue bands + the dark blue band
                neardiff=[BLMath MultiplyVector:diff byScalar:(1-(0.04 * (ip+1)))];
            if(ip==3) // the sand band
            {
                neardiff=[BLMath MultiplyVector:diff byScalar:(1-(0.042 * (ip)))];
                neardiff=CGPointMake(neardiff.x-2, neardiff.y-6);
            }
            if(ip==4) // the grass
            {
                neardiff=[BLMath MultiplyVector:diff byScalar:(1-(0.043 * (ip-1)))];
                neardiff=CGPointMake(neardiff.x-1, neardiff.y+1);
            }
            
            
            //CGPoint neardiff=diff; //don't scale -- just offset it
            
            CGPoint aPos=[BLMath AddVector:neardiff toVector:pmid];
            //CGPoint prelPos=[BLMath SubtractVector:ParentGO.Position from:aPos];
            
            //also offset the thing
            //aPos=[BLMath AddVector:ccp(5, 5) toVector:aPos];
            
            CGPoint newpos=aPos;
            
            int insertChildPos=ip*sortedChildren.count;
            if(ip>0)insertChildPos-=1;
            
            int actualinsert=insertChildPos+i;
            
            //NSLog(@"inserting at %d", actualinsert);
            allPerimPoints[actualinsert]=newpos;
            
            if(ip==4)
            {
                //newpos is point on this poly -- adjusted to what? * see the draw code
                
                CGPoint offp=[BLMath AddVector:newpos toVector:ParentGO.Position];
                [texturePoints addObject:[NSValue valueWithCGPoint:offp]];
            }
            
            //allPerimPoints[(ip==0 ? 0 : ((ip*shadowSteps)-1))+i]=newpos;
        }
    }
    
    //=======================================================================================
    
    [self setPointScalesAt:1.0f];

    //====== create nodes and such ==========================================================
    
    //add a draw node the for the above
    
    [ParentGO.RenderBatch.parent addChild:[[MasteryDrawNode alloc] initWithParent:self]];
    
    int texID=(abs((int)ParentGO.Position.x) % 9) + 1;
    
    NSLog(@"%@ texture %d", ParentGO.UserVisibleString, texID);
    
    NSString *file=[NSString stringWithFormat:@"/images/jmap/island-tex%d.png", texID];
    PRFilledPolygon *poly=[PRFilledPolygon filledPolygonWithPoints:texturePoints andTexture:[[CCTextureCache sharedTextureCache] textureForKey:BUNDLE_FULL_PATH(file)]];
    
    [ParentGO.RenderBatch.parent addChild:poly];
    
    if(ParentGO.EnabledAndComplete)
    {
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"mastery-complete.png"];
    }
    else
    {
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"mastery-incomplete.png"];
    }
    [nodeSprite setPosition:[BLMath AddVector:ParentGO.Position toVector:ccp(0, 0)]];
    [nodeSprite setVisible:ParentGO.Visible];
    if(ParentGO.Disabled) [nodeSprite setOpacity:100];
    [ParentGO.RenderBatch addChild:nodeSprite];
    
    CGPoint labelCentre=ccpAdd(ccp(0,60), ParentGO.Position);
    labelCentre=ccp((int)labelCentre.x, (int)labelCentre.y);
    
    labelSprite=[CCLabelTTF labelWithString:[ParentGO.UserVisibleString uppercaseString] fontName:@"Source Sans Pro" fontSize:14.0f];
    [labelSprite setPosition:ccpAdd(labelCentre, ccp(-2, 4))];
    [labelSprite setVisible:ParentGO.Visible];
    if(ParentGO.Disabled) [labelSprite setOpacity:100];
    
    [ParentGO.RenderBatch.parent addChild:labelSprite z:2];
    
    //left end
    CCSprite *lend=[CCSprite spriteWithSpriteFrameName:@"sign-left.png"];
    CGPoint loffset=ccp(-labelSprite.contentSize.width / 2.0f - 6.0f, 0);
    [lend setPosition:ccpAdd(labelCentre, loffset)];
    [ParentGO.RenderBatch addChild:lend];

//    CCSprite *mid=[CCSprite spriteWithSpriteFrameName:@"sign-middle.png"];
//    [mid setScaleX: labelSprite.contentSize.width / mid.contentSize.width];
//    [mid setPosition: labelCentre];
//    [ParentGO.RenderBatch addChild:mid];
    
    //mid
    for (int i=0; i<labelSprite.contentSize.width+3; i++)
    {
        CCSprite *mid=[CCSprite spriteWithSpriteFrameName:@"sign-middle.png"];
        //[mid setScaleX: labelSprite.contentSize.width / mid.contentSize.width];
        [mid setPosition:ccp((labelCentre.x - (labelSprite.contentSize.width / 2.0f)) + i, labelCentre.y)];
        [ParentGO.RenderBatch addChild:mid];
    }

    
    //right end
    CCSprite *rend=[CCSprite spriteWithSpriteFrameName:@"sign-right.png"];
    CGPoint roffset=ccp(labelSprite.contentSize.width / 2.0f + 6.0f, 0);
    [rend setPosition:ccpAdd(labelCentre, roffset)];
    [ParentGO.RenderBatch addChild:rend];
    
    //=======================================================================================
    
}

- (void)insertSpacerPointsWithRotGap:(float)rotGap andScale:(float)scale
{
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
            
            if((nextA-thisA) > rotGap)
            {
                float lOfThisV=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:thisP]];
                float lOfNextV=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:nextP]];
                
                float rotOffset=0.5f;
                float lOfV=(lOfThisV * rotOffset) + (lOfNextV * (1-rotOffset));
                
                lOfV=lOfV * scale;
                
                //float lOfV=scale * [BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:thisP]];
                
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
    [texturePoints release];
    
    [super dealloc];
}

@end




@implementation MasteryDrawNode

-(MasteryDrawNode*)initWithParent:(SGJmapMasteryNodeRender*)masteryNodeRender;
{
    if(self=[super init])
    {
        renderParent=masteryNodeRender;
    }
    return self;
}

-(void) draw
{
//    CGPoint myWorldPos=[renderParent.ParentGO.RenderBatch.parent convertToWorldSpace:renderParent.ParentGO.Position];

    CGPoint myWorldPos=renderParent.ParentGO.Position;
    
    //upate position of all polys
    CGPoint adjPoints[shadowSteps*renderParent.sortedChildren.count];
    for (int i=0; i<(shadowSteps*renderParent.sortedChildren.count); i++) {
        adjPoints[i]=[BLMath AddVector:myWorldPos toVector:renderParent.scaledPerimPoints[i]];
    }
    
    //perim polys -- overlapping
    for(int ip=0; ip<shadowSteps; ip++)
    {
        CGPoint *first=&adjPoints[(ip==0) ? 0 : (ip*renderParent.sortedChildren.count)-1];
        
        //ccColor4F col=ccc4FFromccc4B(stepColours[ip]);

        //opacity-based were white, 0.15f
        //ccColor4F col=ccc4f(1.0f, 1.0f, 1.0f, 0.15f);
        
        ccColor4F col=ccc4f(0.343f, 0.520f, 0.641, 1.0f);
        if (ip==1) col=ccc4f(0.402f, 0.563f, 0.676f, 1.0f);
        
        if (ip==2) col=ccc4f(0.220f, 0.373f, 0.471f, 1.0f);
        if (ip==3) col=ccc4f(0.851f, 0.780f, 0.624f, 1.0f);
        if (ip==4) col=ccc4f(0.451f, 0.608f, 0.259f, 1.0f);
        
        //if(renderParent.zoomedOut) col=ccc4f(col.r, col.g, col.b, 0.3f);
        
        ccDrawFilledPoly(first, renderParent.sortedChildren.count, col);
    }

    
    // ======= mastery > node lines -- not currently used ===============================
    
//    if(!renderParent.zoomedOut)
//    {
//        for (id<Transform> prnode in renderParent.ParentGO.ChildNodes) {
//            //world space pos of child node
//            CGPoint theirWorldPos=[renderParent.ParentGO.RenderBatch.parent convertToWorldSpace:prnode.Position];
//            
//            //draw prereq path to this node
//            ccDrawColor4B(userHighCol.r, userHighCol.g, userHighCol.b, userHighCol.a);
//            ccDrawLine(myWorldPos, theirWorldPos);
//        }
//    }
    
    // ==================================================================================
}

@end
