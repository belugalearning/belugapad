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
#import "ToolScene.h"

@implementation BFloatObjectRender

-(BFloatObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BFloatObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    amPickedUp=NO;
    
    occSeparators=[[NSMutableArray alloc] init];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        [self setSprite];
        [self addOccludingSeparators];
    }
    
    if(messageType==kDWenableOccludingSeparators)
    {
        enableOccludingSeparators=YES;
    }
    
    if(messageType==kDWupdateSprite)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(mySprite==nil) 
        {
            [self setSprite];
            [self addOccludingSeparators];
        }
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
            if(mySprite==nil) 
            {
                [self setSprite];   
                [self addOccludingSeparators];
            }
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
        
        [self removeOccludingSeparators];
    }
    
    if(messageType==kDWputdown)
    {
        amPickedUp=NO;
        
        [self addOccludingSeparators];
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
    
    //source object receivers for operation initiation
    if(messageType==kDWoperateAddTo)
    {
        [self addMeTo:[payload objectForKey:TARGET_GO]];
    }
    if(messageType==kDWoperateSubtractFrom)
    {
        [self subtractMeFrom:[payload objectForKey:TARGET_GO]];
    }
    if(messageType==kDWoperateMultiplyBy)
    {
        [self multiplyWithMeTo:[payload objectForKey:TARGET_GO]];
    }
    if(messageType==kDWoperateDivideBy)
    {
        [self divideWithMeTo:[payload objectForKey:TARGET_GO]];
    }
    
    
    //destination object receivers for operation actions
    if(messageType==kDWfloatAddThisChild)
    {
        [self addThisChild:[payload objectForKey:OBJ_CHILD]];
    }
    if (messageType==kDWfloatSubtractThisChild) 
    {
        [self subtractWithThisChild:[payload objectForKey:OBJ_CHILD]];
    }
    if(messageType==kDWfloatMultiplyWithThisChild)
    {
        [self  multiplyWithThisChild:[payload objectForKey:OBJ_CHILDMATRIX]];
    }
    if(messageType==kDWfloatDivideWithThisChild)
    {
        [self divideWithThisChild:[payload objectForKey:OBJ_CHILDMATRIX]];
    }
}

-(void)setPhysPos
{
    
}

-(void)setSprite
{
    //CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/blocks/obj-float-45.png")];
    CCNode *mySprite=[[CCNode alloc] init];
    [[gameWorld GameScene].ForeLayer addChild:mySprite z:1];
    
    //if we're on an object > 1x1, render more sprites as children
    int r=[GOS_GET(OBJ_ROWS) intValue];
    int c=[GOS_GET(OBJ_COLS) intValue];
    
    //use r, c as template for object -- but store as matrix
    NSMutableArray *childMatrix=[[NSMutableArray alloc] init];
    
    //get unit size
    int unitSize=[[[gameObject store]objectForKey:OBJ_UNITCOUNT] intValue];
    
    if(unitSize>(r*c))
    {
        if(r>c) c++;
        else r++;
    }
    
    //add children in rectangle fasion
    
    int unitsCreated=0;
    
    for(int ri=0;ri<r;ri++)
    {
        for(int ci=0; ci<c;ci++)
        {
            if(unitsCreated<unitSize)
            {
                CCSprite *cs=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[gameObject store] objectForKey:SPRITE_FILENAME])];
//                [cs setPosition:ccp((ci*UNIT_SIZE)+HALF_SIZE, (ri*UNIT_SIZE)+HALF_SIZE)];
                [cs setPosition:ccp((ci*UNIT_SIZE), (ri*UNIT_SIZE))]; 
                if(gameWorld.Blackboard.inProblemSetup)
                {
                    [cs setTag:2];
                    [cs setOpacity:0];
                }
                [mySprite addChild:cs];
                
                //add this as a position to the child matrix
                NSMutableDictionary *child=[[NSMutableDictionary alloc]init];
                [child setObject:[NSValue valueWithCGPoint:CGPointMake(ci, ri)] forKey:OBJ_MATRIXPOS];
                [child setObject:cs forKey:MY_SPRITE];
                
                [childMatrix addObject:child];                
                [child release];
                
                unitsCreated++;
            }
        }
    }
    
    if([[gameObject store] objectForKey:OBJECT_OVERLAY_FILENAME] && ([[mySprite children]count]>0))
    {
        CCSprite *ol=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[gameObject store] objectForKey:OBJECT_OVERLAY_FILENAME])];
        float scalar = (1.0f/(float)[[mySprite children]count]);
        CGPoint avg = ccp(0,0);
        
        for(int i=0; i<[[mySprite children]count]; i++)
        {
            CCSprite *cs = [[mySprite children] objectAtIndex:i];
            avg = [BLMath AddVector:cs.position toVector:avg];
        }
        avg = [BLMath MultiplyVector:avg byScalar:scalar];
        [ol setPosition:avg];
        [mySprite addChild:ol];
    }
    //update object data -- e.g.
    [gameObject handleMessage:kDWupdateObjectData andPayload:nil withLogLevel:0];
    
    //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
    [[gameObject store] setObject:mySprite forKey:MY_SPRITE];
    [mySprite release];
    
    [[gameObject store] setObject:childMatrix forKey:OBJ_CHILDMATRIX];
    [childMatrix release];
    
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
    CGPoint accumPos=CGPointMake(0, 0);
    
    //avg the localised position of children
    for (int i=0; i<[matrix count]; i++) {
        NSDictionary *child=[matrix objectAtIndex:i];
        CCSprite *childSprite=[child objectForKey:MY_SPRITE];
        CGPoint globalSpos=[pSprite convertToWorldSpace:[childSprite position]];
        accumPos=[BLMath AddVector:accumPos toVector:[BLMath MultiplyVector:globalSpos byScalar:1.0f/total]];
    }
    return accumPos;
}

-(void)addOccludingSeparators
{
    if(!enableOccludingSeparators) return;
    
    NSMutableArray *flatChildren=[[gameObject store] objectForKey:OBJ_CHILDMATRIX];
    NSMutableArray *matrix=[self getMatrixContainingChildren];
    CCNode *objectNode=[[gameObject store] objectForKey:MY_SPRITE];
    
    for (int c=0; c<[matrix count]; c++) {    // iterate to one from last column
        for(int r=0; r<[[matrix objectAtIndex:0] count]; r++)
        {
            int flatIndex=[[[matrix objectAtIndex:c] objectAtIndex:r] intValue];
            if(flatIndex >= 0)
            {
                //is there an object in the next space on this row
                if(r<[[matrix objectAtIndex:0] count]-1)
                {
                    int nextRowFlatIndex=[[[matrix objectAtIndex:c] objectAtIndex:r+1] intValue];
                    if(nextRowFlatIndex>=0)
                    {
                        //there's an object adjacent on this row, draw an occlusion separator
                        CCSprite *rowSep=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[gameObject store] objectForKey:SEPARATOR_FILENAME])];
                        if(gameWorld.Blackboard.inProblemSetup)
                        {
                            [rowSep setTag:2];
                            [rowSep setOpacity:0];
                        }
                        
                        [rowSep setRotation:90.0f];
                        [objectNode addChild:rowSep];
                        
                        CGPoint thisRowObjPos=[[[flatChildren objectAtIndex:flatIndex] objectForKey:MY_SPRITE] position];
                        [rowSep setPosition:[BLMath AddVector:ccp(0, HALF_SIZE) toVector:thisRowObjPos]];   
                        
                        [occSeparators addObject:rowSep];
                    }
                }
                
                if(c<[matrix count]-1)
                {
                    //is there an object in the next column
                    int nextColFlatIndex=[[[matrix objectAtIndex:c+1] objectAtIndex:r] intValue];
                    if(nextColFlatIndex>=0)
                    {
                        CCSprite *colSep=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[gameObject store] objectForKey:SEPARATOR_FILENAME])];
                        [objectNode addChild:colSep];
                        if(gameWorld.Blackboard.inProblemSetup)
                        {
                            [colSep setTag:2];
                            [colSep setOpacity:0];
                        }
                        
                        CGPoint thisRowObjPos=[[[flatChildren objectAtIndex:flatIndex] objectForKey:MY_SPRITE] position];
                        [colSep setPosition:[BLMath AddVector:ccp(HALF_SIZE, 0) toVector:thisRowObjPos]];                        
                        
                        [occSeparators addObject:colSep];
                    }
                }
                
                if((r<[[matrix objectAtIndex:0] count]-1) && (c<[matrix count]-1))
                {
                    int nextRowFlatIndex=[[[matrix objectAtIndex:c] objectAtIndex:r+1] intValue];
                    int nextColFlatIndex=[[[matrix objectAtIndex:c+1] objectAtIndex:r] intValue];
                    int diagFlatIndex=[[[matrix objectAtIndex:c+1] objectAtIndex:r+1] intValue];
                    
                    if(nextColFlatIndex>=0 && nextRowFlatIndex >=0 && diagFlatIndex >=0)
                    {
                        CCSprite *diagSep=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[gameObject store] objectForKey:SEPARATOR_FILENAME])];
                        [objectNode addChild:diagSep];
                        if(gameWorld.Blackboard.inProblemSetup)
                        {
                            [diagSep setTag:2];
                            [diagSep setOpacity:0];
                        }
                        
                        CGPoint thisRowObjPos=[[[flatChildren objectAtIndex:flatIndex] objectForKey:MY_SPRITE] position];
                        [diagSep setPosition:[BLMath AddVector:ccp(HALF_SIZE, HALF_SIZE) toVector:thisRowObjPos]];                        
                        
                        [occSeparators addObject:diagSep];
                    }
                }
            }
        }
    }
}

-(void)removeOccludingSeparators
{
    if(!enableOccludingSeparators) return;
    
    CCNode *n=[[gameObject store] objectForKey:MY_SPRITE];
    
    for (CCNode *s in occSeparators) {
        [n removeChild:s cleanup:YES];
    }
    
    [occSeparators removeAllObjects];
}

-(void)removeChildSprites
{
    for (NSDictionary *d in [[gameObject store] objectForKey:OBJ_CHILDMATRIX]) {
        CCSprite *s=[d objectForKey:MY_SPRITE];
        [[s parent] removeChild:s cleanup:YES];
    }
}

-(void)removeThisManyChildren: (int)removeCount
{
    NSMutableArray *cMatrix=[[gameObject store] objectForKey:OBJ_CHILDMATRIX];
    
    for (int i=0;i<removeCount;i++)
    {
        NSDictionary *d=[cMatrix lastObject];
        CCSprite *s=[d objectForKey:MY_SPRITE];
        [[s parent] removeChild:s cleanup:YES];
        [cMatrix removeLastObject];
    }
}

-(void)addMeTo:(DWGameObject*)targetGo
{
//    CGPoint offsetPos=[BLMath offsetPosFrom:[self avgPosForFloatObject:gameObject] to:[self avgPosForFloatObject:targetGo]];

    for (NSDictionary *child in [[gameObject store] objectForKey:OBJ_CHILDMATRIX]) {
        [targetGo handleMessage:kDWfloatAddThisChild andPayload:[NSDictionary dictionaryWithObject:child forKey:OBJ_CHILD] withLogLevel:0];
    }
    
    //relinquish ownership of all these children
    //[[[gameObject store] objectForKey:OBJ_CHILDMATRIX] release];
    
    //destroy myself
    [gameObject handleMessage:kDWdetachPhys];
    [gameWorld delayRemoveGameObject:gameObject];
}

-(void)multiplyWithMeTo:(DWGameObject*)targetGo
{
    [targetGo handleMessage:kDWfloatMultiplyWithThisChild andPayload:[NSDictionary dictionaryWithObject:[[gameObject store] objectForKey:OBJ_CHILDMATRIX] forKey:OBJ_CHILDMATRIX] withLogLevel:0];
    
    [self removeOccludingSeparators];
    [self removeChildSprites];
    
    //destroy myself
    [gameObject handleMessage:kDWdetachPhys];
    [gameWorld delayRemoveGameObject:gameObject];    
}

-(void)divideWithMeTo:(DWGameObject*)targetGo
{
    int myCount=[[[gameObject store] objectForKey:OBJ_CHILDMATRIX] count];
    int theirCount=[[[targetGo store] objectForKey:OBJ_CHILDMATRIX] count];
    int rem=myCount % theirCount;
    if (myCount<theirCount) rem=theirCount-myCount;
    
    [targetGo handleMessage:kDWfloatDivideWithThisChild andPayload:[NSDictionary dictionaryWithObject:[[gameObject store] objectForKey:OBJ_CHILDMATRIX] forKey:OBJ_CHILDMATRIX] withLogLevel:0];
    
    
    if(rem==0)
    {
        [self removeOccludingSeparators];
        [self removeChildSprites];
        
        //destroy myself
        [gameObject handleMessage:kDWdetachPhys];
        [gameWorld delayRemoveGameObject:gameObject];        
    }
    else {
        //just remove remainder
        [self removeThisManyChildren:myCount-rem];
    }
}

-(void)subtractMeFrom:(DWGameObject*)targetGo
{
    CGPoint offsetPos=[BLMath offsetPosFrom:[self avgPosForFloatObject:gameObject] to:[self avgPosForFloatObject:targetGo]];
    DLog(@"subtract operation from %@", NSStringFromCGPoint(offsetPos));
    
    int removeCount=0;
    
    for(NSDictionary *child in [[gameObject store] objectForKey:OBJ_CHILDMATRIX]){
        [targetGo handleMessage:kDWfloatSubtractThisChild andPayload:[NSDictionary dictionaryWithObject:child forKey:OBJ_CHILD] withLogLevel:0];
    
        removeCount++;
        
        [child release];
        
        if([[[targetGo store] objectForKey:OBJ_CHILDMATRIX] count]==0)
        {
            [targetGo handleMessage:kDWdetachPhys];
            [gameWorld delayRemoveGameObject:targetGo];
            break;
        }
    }

    if(removeCount==[[[gameObject store] objectForKey:OBJ_CHILDMATRIX] count])
    {
        //relinquish ownership of all these children (technically already done above)
        //[[[gameObject store] objectForKey:OBJ_CHILDMATRIX] release];
        
        //destroy myself
        [gameObject handleMessage:kDWdetachPhys];
        [gameWorld delayRemoveGameObject:gameObject];

    }
}

-(void)multiplyWithThisChild:(NSMutableArray*)child
{
    int multiple=[child count];
    CCNode *myNode=[[gameObject store] objectForKey:MY_SPRITE];
    NSMutableArray *myMatrix=[[gameObject store] objectForKey:OBJ_CHILDMATRIX];
    int baseCount=[myMatrix count];
    
    for(int i=0; i<multiple-1; i++)
    {
        for(int b=0; b<baseCount; b++)
        {
            CGPoint newPos=[self findMatrixFreePos];
            int ci=newPos.x;
            int ri=newPos.y;
            
            //create new objects
            CCSprite *cs=[CCSprite spriteWithFile:BUNDLE_FULL_PATH([[gameObject store] objectForKey:SPRITE_FILENAME])];
            [cs setPosition:ccp((ci*UNIT_SIZE), (ri*UNIT_SIZE))]; 
            
            [cs setOpacity:0];
            
            CCDelayTime *dt=[CCDelayTime actionWithDuration:i*0.5f];
            CCFadeIn *fi=[CCFadeIn actionWithDuration:0.2f];
            CCSequence *seq=[CCSequence actions:dt, fi, nil];
            [cs runAction:seq];
            
            [myNode addChild:cs];
            
            //add this as a position to the child matrix
            NSMutableDictionary *child=[[NSMutableDictionary alloc]init];
            [child setObject:[NSValue valueWithCGPoint:CGPointMake(ci, ri)] forKey:OBJ_MATRIXPOS];
            [child setObject:cs forKey:MY_SPRITE];
            
            [myMatrix addObject:child];                
            [child release];
        }
    }
}

-(void)divideWithThisChild:(NSMutableArray*)child
{
    int divisor=[child count];
    NSMutableArray *myMatrix=[[gameObject store] objectForKey:OBJ_CHILDMATRIX];
    int myCount=[myMatrix count];
    
    int result=myCount/divisor;
    [self removeThisManyChildren:myCount-result];
    
    //remove children to achieve result
    
}

-(CGPoint)findMatrixFreePos
{
    NSMutableArray *matrix=[self getMatrixContainingChildren];
    
    int matrixX=[matrix count];
    int matrixY=[[matrix objectAtIndex:0] count];
    
    CGPoint newPos=CGPointMake(-1, -1);
    
    for(int ix=0; ix<matrixX; ix++)
    {
        for(int iy=0; iy<matrixY; iy++)
        {
            if([[[matrix objectAtIndex:ix] objectAtIndex:iy] intValue]<0)
            {
                //this position is empty -- fill it
                newPos=CGPointMake(ix, iy);
            }
        }
    }
    
    if(newPos.x<0)  // no empty space was found
    {
        //extend the matrix
        if(matrixX<=matrixY)
        {
            //add another x col
            NSMutableArray *newCol=[[NSMutableArray alloc] init];
            [matrix addObject:newCol];
            for(int newy=0; newy<matrixY; newy++)
            {
                [newCol addObject:[NSNumber numberWithInt:-1]];
            }
            
            //set first row in new col as position
            newPos=CGPointMake(matrixX, 0);
            
            [newCol release];
        }
        else
        {
            //add a row to each current col
            for(int newx=0; newx<matrixX; newx++)
            {
                [[matrix objectAtIndex:newx] addObject:[NSNumber numberWithInt:-1]];
            }
            //set first col in new row as position
            newPos=CGPointMake(0, matrixY);
        }
    }

    return newPos;
}

-(void)addThisChild:(NSMutableDictionary *)child
{
    CGPoint newPos=[self findMatrixFreePos];

    //move object to this new position
    NSMutableArray *flatChildren=[[gameObject store] objectForKey:OBJ_CHILDMATRIX];
    [flatChildren addObject:child];
    [child setObject:[NSValue valueWithCGPoint:newPos] forKey:OBJ_MATRIXPOS];

    //move sprite ownership
    CCSprite *childSprite=[child objectForKey:MY_SPRITE];
    CCNode *masterNode=[[gameObject store] objectForKey:MY_SPRITE];
    
    [[childSprite parent] removeChild:childSprite cleanup:NO];
    [masterNode addChild:childSprite];
    
    //actually animte/move this object to this thing
    CGPoint newCPos=CGPointMake(newPos.x*UNIT_SIZE, newPos.y*UNIT_SIZE);
    [childSprite setColor:ccc3(0, 255, 0)];
    [childSprite runAction:[CCMoveTo actionWithDuration:0.4f position:newCPos]];
    [childSprite runAction:[CCTintTo actionWithDuration:1.0f red:255 green:255 blue:255]];
 
    //update the count on this object
    [[gameObject store] setObject:[NSNumber numberWithInt:[flatChildren count]] forKey:OBJ_UNITCOUNT];
    
    //update separators
    [self removeOccludingSeparators];
    [self addOccludingSeparators];
}
    

-(void)subtractWithThisChild:(NSDictionary *)child
{
    NSMutableArray *flatChildren=[[gameObject store] objectForKey:OBJ_CHILDMATRIX];
    NSDictionary *localRemove=[flatChildren objectAtIndex:[flatChildren count]-1];
    NSDictionary *remoteRemove=child;
    
    CCSprite *localSprite=[localRemove objectForKey:MY_SPRITE];
    CCSprite *remoteSprite=[remoteRemove objectForKey:MY_SPRITE];
    CCNode *objectNode=[[gameObject store] objectForKey:MY_SPRITE];
    
    CGPoint localPos=[objectNode convertToWorldSpace:[localSprite position]];
    CGPoint remotePos=[[remoteSprite parent] convertToWorldSpace:[remoteSprite position]];
    
    //we'll copy texture and then use this to animate delete
    CCSprite *subSprite=[CCSprite spriteWithTexture:[remoteSprite texture]];
    CCSprite *holdSprite=[CCSprite spriteWithTexture:[localSprite texture]];
    
    [flatChildren removeObject:localRemove];

    //put a placeholder in original position
    [holdSprite setPosition:localPos];
//    [holdSprite setPosition:[localSprite position]];
//    [holdSprite setAnchorPoint:[objectNode position]];
//    [holdSprite setRotation:[localSprite rotation]];
    [[gameWorld GameScene].ForeLayer addChild:holdSprite];
    CCDelayTime *t0=[CCDelayTime actionWithDuration:1.0f];
    CCFadeOut *t1=[CCFadeOut actionWithDuration:0.1f];
    CCSequence *tseq=[CCSequence actions:t0, t1, nil];
    [holdSprite runAction:tseq];
    
    //animate a subtraction from remotePos to localPos
    [subSprite setColor:ccc3(255, 0, 0)];
    [subSprite setPosition:remotePos];
//    [subSprite setPosition:[remoteSprite position]];
//    [subSprite setAnchorPoint:[[remoteSprite parent] position]];
//    [subSprite setRotation:[remoteSprite rotation]];
    CCDelayTime *s0=[CCDelayTime actionWithDuration:0.5f];
    CCMoveTo *s1=[CCMoveTo actionWithDuration:0.3f position:localPos];
    CCDelayTime *s2=[CCDelayTime actionWithDuration:0.3f];
    CCFadeOut *s3=[CCFadeOut actionWithDuration:1.5f];
    CCSequence *seq=[CCSequence actions:s0, s1, s2, s3, nil];
    [[gameWorld GameScene].ForeLayer addChild:subSprite];
    [subSprite runAction:seq];

    
    [localSprite setVisible:NO];
    [remoteSprite setVisible:NO];
    
    [[gameWorld GameScene].ForeLayer removeChild:localSprite cleanup:YES];
    [[gameWorld GameScene].ForeLayer removeChild:remoteSprite cleanup:YES];
    
    //update count
    [[gameObject store] setObject:[NSNumber numberWithInt:[flatChildren count]] forKey:OBJ_UNITCOUNT];
    
    //update separators
    [self removeOccludingSeparators];
    [self addOccludingSeparators];
}

-(NSMutableArray *)getMatrixContainingChildren
{
    NSMutableArray *flatChildren=[[gameObject store] objectForKey:OBJ_CHILDMATRIX];
    NSMutableArray *matrix=[[NSMutableArray alloc] init];

    //get min/max x/y
    int maxx=0;
    int maxy=0;
    
    for (NSDictionary *d in flatChildren) {
        CGPoint matrixPos=[[d objectForKey:OBJ_MATRIXPOS] CGPointValue];
        if(matrixPos.x>maxx) maxx=matrixPos.x;
        if(matrixPos.y>maxy) maxy=matrixPos.y;
    }

    //build matrix
    for(int ix=0; ix<=maxx; ix++)
    {
        NSMutableArray *col=[[NSMutableArray alloc] init];
        [matrix addObject:col];
        
        for(int iy=0; iy<=maxy; iy++)
        {
            //add an invalid (-1) pointer to flat array
            [col addObject:[NSNumber numberWithInt:-1]];
        }
        
        [col release];
    }
    
    //populate matrix
    for(int i=0; i<[flatChildren count]; i++) {
        NSDictionary *d=[flatChildren objectAtIndex:i];
        CGPoint matrixPos=[[d objectForKey:OBJ_MATRIXPOS] CGPointValue];
     
        //change that entry in matrix to an indexed pointer to this flat child
        [[matrix objectAtIndex:matrixPos.x] replaceObjectAtIndex:matrixPos.y withObject:[NSNumber numberWithInt:i]];
    }
    
    [matrix autorelease];
    
    return matrix;
}


-(void) dealloc
{
    [super dealloc];
}

@end
