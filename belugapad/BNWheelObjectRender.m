//
//  BNWheelObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "BNWheelObjectRender.h"
#import "DWNWheelGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BNWheelObjectRender()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BNWheelObjectRender

-(BNWheelObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNWheelObjectRender*)[super initWithGameObject:aGameObject withData:data];
    w=(DWNWheelGameObject*)gameObject;
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
    //init pos x & y in case they're not set elsewhere
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!w.mySprite)
        {
            [self setSprite];
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!w.mySprite) {
            [self setSprite];
        }
        
    }
    if(messageType==kDWmoveSpriteToPosition)
    {
        [self moveSprite];
    }
    if(messageType==kDWmoveSpriteToHome)
    {
        [self moveSpriteHome];
    }
    if(messageType==kDWdismantle)
    {
        [[w.mySprite parent] removeChild:w.mySprite cleanup:YES];
    }
    
}



-(void)setSprite
{
    NSString *spriteFileName=[[[NSString alloc]init] autorelease];
    
    if(w.SpriteFileName)
        spriteFileName=w.SpriteFileName;
    
    else
        spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice.png"];
    
    w.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];

    [w.mySprite setPosition:w.Position];
    
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [w.mySprite setTag:1];
        [w.mySprite setOpacity:0];
    }
    
    
    
}
-(void)moveSprite
{
    DWPieSplitterPieGameObject *pie=(DWPieSplitterPieGameObject*)slice.myPie;
    
    if(slice.myCont)
        [slice.mySprite setPosition:[slice.mySprite.parent convertToNodeSpace:slice.Position]];
    else
        [slice.mySprite setPosition:[pie.mySprite convertToNodeSpace:slice.Position]];
    
    
}
-(void)moveSpriteHome
{
    DWPieSplitterPieGameObject *myPie=(DWPieSplitterPieGameObject*)slice.myPie;
    if(slice.myPie) {
        //[slice.mySprite runAction:[CCRotateTo actionWithDuration:0.1f angle:(360/myPie.numberOfSlices)*[myPie.mySprite.children count]]];
        [slice.mySprite runAction:[CCMoveTo actionWithDuration:0.5f position:[slice.mySprite.parent convertToNodeSpace:myPie.Position]]];
    }
}
-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end
