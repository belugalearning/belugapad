//
//  BFloatRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
#import "chipmunk.h"


@interface BFloatObjectRender : DWBehaviour
{
    
    BOOL amPickedUp;
    cpBody *physBody;
    
    BOOL physDetached;
    
    NSMutableArray *occSeparators;
    BOOL enableOccludingSeparators;
}

-(BFloatObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setSpritePos:(NSDictionary *)position;
-(CGPoint)avgPosForFloatObject:(DWGameObject *)go;
-(void)addMeTo:(DWGameObject*)targetGo;
-(void)subtractMeFrom:(DWGameObject*)targetGo;
-(void)multiplyWithMeTo:(DWGameObject*)targetGo;
-(void)divideWithMeTo:(DWGameObject*)targetGo;

-(void)addThisChild:(NSDictionary *)child;
-(void)subtractWithThisChild:(NSDictionary *)child;
-(void)multiplyWithThisChild:(NSMutableArray*)child;
-(void)divideWithThisChild:(NSMutableArray*)child;

-(NSMutableArray *)getMatrixContainingChildren;

-(CGPoint)findMatrixFreePos;

-(void)addOccludingSeparators;
-(void)removeOccludingSeparators;
-(void)removeChildSprites;
-(void)removeThisManyChildren: (int)removeCount;

-(void)swapObjSpritesTo:(NSString*)spriteFile;

@end
