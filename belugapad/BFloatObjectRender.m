//
//  BFloatRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BFloatObjectRender.h"
#import "global.h"
#import "BLMath.h"

@implementation BFloatObjectRender

-(BFloatObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BFloatObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    amPickedUp=NO;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        //[self setSprite];
    }
    
    if(messageType==kDWupdateSprite)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(mySprite==nil) [self setSprite];
        [self setSpritePos:payload];
        
        //set phys position
        float x=[[payload objectForKey:POS_X]floatValue];
        float y=[[payload objectForKey:POS_Y]floatValue];
        
        if(physBody)
        {
            physBody->p=ccp(x, y);
        }
    }
    
    if(messageType==kDWupdatePosFromPhys)
    {
        if(amPickedUp==NO)
        {
            CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
            if(mySprite==nil) [self setSprite];
            [self setSpritePos:payload];            
        }
    }
    
    if(messageType==kDWsetPhysBody)
    {
        physBody=[[payload objectForKey:PHYS_BODY] pointerValue];
    }
    
    if(messageType==kDWpickedUp)
    {
        amPickedUp=YES;
    }
    
    if(messageType==kDWputdown)
    {
        amPickedUp=NO;
    }
    
    if(messageType==kDWsetMount || messageType==kDWdetachPhys)
    {
        //disable phys on this object
        if(physBody)
        {
            //be aware that other activators on the object will revert this
            cpBodySleep(physBody);
        }
        
        physDetached=YES;
    }
    if(messageType==kDWunsetMount || messageType==kDWattachPhys)
    {
        if(physBody && physDetached)
        {
            cpBodyActivate(physBody);
            physDetached=NO;
        }
    }
    
    if(messageType==kDWoperateAddTo)
    {
        [self addMeTo:[payload objectForKey:TARGET_GO]];
    }
    
    if(messageType==kDWoperateSubtractFrom)
    {
        [self subtractMeFrom:[payload objectForKey:TARGET_GO]];
    }
}

-(void)setPhysPos
{
    
}

-(void)setSprite
{
    CCSprite *mySprite=[CCSprite spriteWithFile:@"obj-float-45.png"];
    [[gameWorld GameScene] addChild:mySprite z:0];
    
    //if we're on an object > 1x1, render more sprites as children
    int r=[GOS_GET(OBJ_ROWS) intValue];
    int c=[GOS_GET(OBJ_COLS) intValue];
    
    //use r, c as template for object -- but store as matrix
    NSMutableArray *childMatrix=[[NSMutableArray alloc] init];

    //add this (primary sprite) a position to the child matrix
    NSMutableDictionary *primarychild=[[NSMutableDictionary alloc]init];
    [primarychild setObject:[NSValue valueWithCGPoint:CGPointMake(0, 0)] forKey:OBJ_MATRIXPOS];
    [primarychild setObject:mySprite forKey:MY_SPRITE];
    
    [childMatrix addObject:primarychild];
    
    //get unit size
    int unitSize=[[[gameObject store]objectForKey:OBJ_UNITCOUNT] intValue];
    
    if(unitSize>(r*c))
    {
        if(r>c) c++;
        else r++;
    }
    
    //add other children in rectangle fasion
    
    int unitsCreated=1; //we already have one unit
    
    for(int ri=0;ri<r;ri++)
    {
        for(int ci=0; ci<c;ci++)
        {
            if(ri>0 || ci>0)
            {
                if(unitsCreated<unitSize)
                {
                    CCSprite *cs=[CCSprite spriteWithFile:@"obj-float-45.png"];
                    [cs setPosition:ccp((ci*UNIT_SIZE)+HALF_SIZE, (ri*UNIT_SIZE)+HALF_SIZE)];
                    [mySprite addChild:cs];
                    
                    //add this as a position to the child matrix
                    NSMutableDictionary *child=[[NSMutableDictionary alloc]init];
                    [child setObject:[NSValue valueWithCGPoint:CGPointMake(ci, ri)] forKey:OBJ_MATRIXPOS];
                    [child setObject:cs forKey:MY_SPRITE];
                    
                    [childMatrix addObject:child];                
                    
                    unitsCreated++;
                }
            }
        }
    }
    
    //update object data -- e.g.
    [gameObject handleMessage:kDWupdateObjectData andPayload:nil withLogLevel:0];
    
    //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
    [[gameObject store] setObject:mySprite forKey:MY_SPRITE];
    
    [[gameObject store] setObject:childMatrix forKey:OBJ_CHILDMATRIX];
}

-(void)setSpritePos:(NSDictionary *)position
{
    if(position != nil)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        
        float x=[[position objectForKey:POS_X] floatValue];
        float y=[[position objectForKey:POS_Y] floatValue];
        
        if ([position objectForKey:ROT]) {
            float r=[[position objectForKey:ROT]floatValue];
            [mySprite setRotation:r];
        }
        
        //also set posx/y on store
        GOS_SET([NSNumber numberWithFloat:x], POS_X);
        GOS_SET([NSNumber numberWithFloat:y], POS_Y);
        
        //set sprite position
        [mySprite setPosition:ccp(x, y)];
    }
}

-(CGPoint)avgPosForFloatObject:(DWGameObject *)go
{
    NSMutableArray *matrix=[[go store] objectForKey:OBJ_CHILDMATRIX];

    float total=[matrix count];
    
    //initialize average with the (already) world pos of primary sprite
    CCSprite *pSprite=[[matrix objectAtIndex:0] objectForKey:MY_SPRITE];
    CGPoint accumPos=[BLMath MultiplyVector:[pSprite position] byScalar:1.0f/total];
    
    //avg the localised position of children
    for (int i=1; i<[matrix count]; i++) {
        NSDictionary *child=[matrix objectAtIndex:i];
        CCSprite *childSprite=[child objectForKey:MY_SPRITE];
        CGPoint globalSpos=[pSprite convertToWorldSpace:[childSprite position]];
        accumPos=[BLMath AddVector:accumPos toVector:[BLMath MultiplyVector:globalSpos byScalar:1.0f/total]];
    }
    return accumPos;
}

-(void)addMeTo:(DWGameObject*)targetGo
{
    CGPoint offsetPos=[BLMath offsetPosFrom:[self avgPosForFloatObject:gameObject] to:[self avgPosForFloatObject:targetGo]];
    DLog(@"add operation from %@", NSStringFromCGPoint(offsetPos));
    
}

-(void)subtractMeFrom:(DWGameObject*)targetGo
{
    CGPoint offsetPos=[BLMath offsetPosFrom:[self avgPosForFloatObject:gameObject] to:[self avgPosForFloatObject:targetGo]];
    DLog(@"subtract operation from %@", NSStringFromCGPoint(offsetPos));
    
}


-(void) dealloc
{
    [super dealloc];
}

@end
