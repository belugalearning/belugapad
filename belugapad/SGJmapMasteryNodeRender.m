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
    
    for (id<Transform> prnode in ParentGO.ChildNodes) {
        //world space pos of child node
        CGPoint theirWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:prnode.Position];
        
        //draw prereq path to this node        
        ccDrawColor4B(255, 255, 255, 255);
        ccDrawLine(myWorldPos, theirWorldPos);        
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
    ccDrawFilledPoly(first, sortedChildren.count,ccc4f(1.0f, 0.0f, 0.0f, 0.1f));
    
    
    //glLineWidth(6.0f);
//    ccDrawColor4B(255, 200, 200, 50);
//    ccDrawLine(myWorldPos, ccpAdd(myWorldPos, ccp(100,200)));
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
                    
//                    NSLog(@"%d inserted at %d with count %d", (int)ParentGO, insertat, sortedChildren.count);
//                    
//                    //look for angle on previous node
//                    float prevA=0.0f;
//                    if(insertat>0) prevA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector: ParentGO.Position from:[[sortedChildren objectAtIndex:insertat-1] CGPointValue]] toMaxLength:1.0f]];
//                    
//                    //insert any filler perimiter nodes
//                    if(thisA-prevA > 90.0f)
//                    {
//                        //insert new point                        
//                        float lOfV=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:prnode.Position]];
//                        //float newRot=lastA+((thisA-lastA)/2.0f);
//                        float newRot=prevA+((thisA-prevA)/2.0f);
//                        //float newRot=prevA+60.0f;
//                        
//                        CGPoint iPos=[BLMath ProjectMovementWithX:0 andY:lOfV forRotation:newRot];
//                        iPos=[BLMath AddVector:ParentGO.Position toVector:iPos];
//                        [sortedChildren insertObject:[NSValue valueWithCGPoint:iPos] atIndex:insertat];
//                        
//                        NSLog(@"%d inserted at %d with count %d << spacer", (int)ParentGO, insertat, sortedChildren.count);
//                        
//                        //NSLog(@"inserting %@ for diff of %f and %f with lOv %f and rot %f", NSStringFromCGPoint(iPos), thisA, lastA, lOfV, newRot);
//                        
//                    }
                    
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
                
//                NSLog(@"%d is inserting at pos %d with count %d and newrot %f from rot %f and %f at pos %@ from %@ and %@", ParentGO, i, sortedChildren.count, newrot, thisA, nextA, NSStringFromCGPoint(newpos), NSStringFromCGPoint(thisP), NSStringFromCGPoint(nextP));
                
//                if(i==sortedChildren.count-1) [sortedChildren addObject:[NSValue valueWithCGPoint:newpos]];
//                else [sortedChildren insertObject:[NSValue valueWithCGPoint:newpos] atIndex:i+1];
                
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
    
//    if([sortedChildren count]>0)
//    {
//        float firstnodeA=360+[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector: ParentGO.Position from:[[sortedChildren objectAtIndex:0] CGPointValue]] toMaxLength:1.0f]];
//        
//        float endnodeA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector: ParentGO.Position from:[[sortedChildren lastObject] CGPointValue]] toMaxLength:1.0f]];
//        
//        //insert any filler perimiter nodes
//        if(firstnodeA-endnodeA > 90.0f)
//        {
//            //insert new point                        
//            float lOfV=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:[[sortedChildren lastObject] CGPointValue]]];
//            //float newRot=lastA+((thisA-lastA)/2.0f);
//            float newRot=endnodeA+((firstnodeA-endnodeA)/2.0f);
//            //float newRot=prevA+60.0f;
//            
//            CGPoint iPos=[BLMath ProjectMovementWithX:0 andY:lOfV forRotation:newRot];
//            iPos=[BLMath AddVector:ParentGO.Position toVector:iPos];
//            [sortedChildren addObject:[NSValue valueWithCGPoint:iPos]];
//            
//            NSLog(@"%d inserted at %d with count %d << end spacer", (int)ParentGO, 999, sortedChildren.count);
//        }
//    }
}

-(void)dealloc
{
    [sortedChildren release];
    
    [super dealloc];
}

@end
