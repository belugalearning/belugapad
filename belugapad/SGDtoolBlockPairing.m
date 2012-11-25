//
//  SGDtoolBlockPairing.m
//  belugapad
//
//  Created by David Amphlett on 06/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGDtoolBlockPairing.h"
#import "SGDtoolBlock.h"
#import "SGDtoolContainer.h"
#import "SGDtoolObjectProtocols.h"
#import "BLMath.h"

@interface SGDtoolBlockPairing()
{
    CCSprite *blockSprite;
}

@end

@implementation SGDtoolBlockPairing

-(SGDtoolBlockPairing*)initWithGameObject:(id<Pairable>)aGameObject
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

-(void)draw:(int)z
{
//    if(z==0)
//    {
//        if([ParentGO.PairedObjects count]>0)
//        {
//            for(int i=0;i<[ParentGO.PairedObjects count];i++)
//            {
//                id<Transform, Moveable, Pairable> curObj=[ParentGO.PairedObjects objectAtIndex:i];
//                float dist=[BLMath DistanceBetween:curObj.Position and:ParentGO.Position];
//                int linesToDraw=0;
//                
//                if(dist<10.0f){
//                    linesToDraw=31;
//                }
//                else if(dist>10.0f<30.0f){
//                    linesToDraw=25;
//                }
//                else if(dist>30.0f<50.0f){
//                    linesToDraw=15;
//                }
//                else if(dist>75.0f){
//                    linesToDraw=2;
//                }
//                else if(ParentGO.LineType==1)
//                {
//                    linesToDraw=60;
//                }
//                else{
//                    linesToDraw=2;
//                }
//                
//                if(dist<=70 && ParentGO.SeekingPair)
//                    ccDrawColor4F(0, 255, 0, 255);
//                else if(dist>70 && ParentGO.SeekingPair)
//                    ccDrawColor4F(255, 0, 0, 255);
//                else
//                    ccDrawColor4F(255, 255, 255, 255);
//                
//
//                
//                for(int i=0;i<linesToDraw/2;i++)
//                {
//                        ccDrawLine(curObj.Position, ParentGO.Position);
//                        ccDrawLine(ccp(curObj.Position.x-i, curObj.Position.y-i), ccp(ParentGO.Position.x-i, ParentGO.Position.y-i));
//                        ccDrawLine(ccp(curObj.Position.x+i, curObj.Position.y+i), ccp(ParentGO.Position.x+i, ParentGO.Position.y+i));
//                }
//            }
//        }
//    }
}

-(void)pairMeWith:(id)thisObject
{
    
}

-(void)pairPickupObjectToMe:(id)pickupObject
{
}

-(void)unpairMeFrom:(id)thisObject
{

}

-(void)unpairPickupObjectFromMe:(id)pickupObject
{


}

//-(void)createContainerAndAdd:(NSArray*)theseObjects
//{
//    id<Container> container;
//    container=[[SGDtoolContainer alloc]initWithGameWorld:gameWorld andLabel:nil andRenderLayer:nil];
//    
//    for(id go in theseObjects)
//        [container addBlockToMe:go];
//    
//}
//
//-(void)addObjectToContainer:(id)thisObject
//{
//    if(((id<Moveable>)ParentGO).MyContainer)
//    {
//        if(((id<Moveable>)ParentGO).MyContainer!=((id<Moveable>)thisObject).MyContainer)
//        {
//            id<Container> myContainer=((id<Moveable>)ParentGO).MyContainer;
//            [myContainer addBlockToMe:thisObject];
//        }
//    }
//    else
//    {
//        [self createContainerAndAdd:[NSArray arrayWithObjects:ParentGO, thisObject, nil]];
//    }
//}
//
//-(void)removeObjectFromContainer:(id)pickupObject
//{
//    id<Container> myContainer=((id<Moveable>)ParentGO).MyContainer;
//    
//    if(myContainer)
//        [myContainer removeBlockFromMe:pickupObject];
//}
 
@end

