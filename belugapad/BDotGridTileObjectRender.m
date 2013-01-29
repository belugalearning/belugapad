//
//  BDotGridTileObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridTileObjectRender.h"
#import "DWDotGridTileGameObject.h"
#import "DWDotGridAnchorGameObject.h"
#import "DWDotGridShapeGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"


@implementation BDotGridTileObjectRender

-(BDotGridTileObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridTileObjectRender*)[super initWithGameObject:aGameObject withData:data];
    tile=(DWDotGridTileGameObject*)gameObject;
    
    //init pos x & y in case they're not set elsewhere
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller registerPollee:(id<LogPolling>)tile];
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!tile.myAnchor)return;
        if(!tile.mySprite) 
        {
            [self setSprite];
            [self setSpritePos:NO];            
        }
        else
        {
            [self resetSprite];
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
    if(messageType==kDWupdateSprite)
    {
        
        CCSprite *mySprite=tile.mySprite;
        if(!mySprite) { 
            [self setSprite];
        }
        
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
    if(messageType==kDWdismantle)
    {
        tile.Selected=NO;
        
        if(tile.myAnchor)
        {
            DWDotGridAnchorGameObject *anch=tile.myAnchor;
            anch.tile=nil;
        }
        

        [tile.mySprite removeFromParentAndCleanup:YES];
        [tile.selectedSprite removeFromParentAndCleanup:YES];
        [gameWorld delayRemoveGameObject:tile];
    }
}

-(tileProperties)decideTileType
{
    tileProperties thisTile;
    
    NSString *spriteFileName=@"";
    float reqRotation=0.0f;
    
    
    DWDotGridAnchorGameObject *fa=((DWDotGridShapeGameObject*)tile.myShape).firstAnchor;
    DWDotGridAnchorGameObject *la=((DWDotGridShapeGameObject*)tile.myShape).lastAnchor;
    
    if(((DWDotGridShapeGameObject*)tile.myShape).lastBoundaryAnchor)
    {
        fa=((DWDotGridShapeGameObject*)tile.myShape).firstBoundaryAnchor;
        la=((DWDotGridShapeGameObject*)tile.myShape).lastBoundaryAnchor;
    }
    
    CGPoint first=CGPointZero;
    CGPoint last=CGPointZero;
    
    if(fa.myYpos<la.myYpos)
    {
        if(fa.myXpos<la.myXpos){
            first=ccp(fa.myXpos,fa.myYpos);
            last=ccp(la.myXpos,la.myYpos);
        }
        else
        {
            first=ccp(la.myXpos,fa.myYpos);
            last=ccp(fa.myXpos,la.myYpos);
        }
    }
    else
    {
        if(fa.myXpos<la.myXpos){
            first=ccp(fa.myXpos,la.myYpos);
            last=ccp(la.myXpos,fa.myYpos);
        }
        else
        {
            first=ccp(la.myXpos,la.myYpos);
            last=ccp(fa.myXpos,fa.myYpos);
        }
    }
    
    CGPoint this=ccp(tile.myAnchor.myXpos, tile.myAnchor.myYpos);
    
    NSLog(@"firstAnch x %d y %d, lastAnch x %d y %d", fa.myXpos, fa.myYpos, la.myXpos, la.myYpos);
    
    float differenceX=fabsf(fa.myXpos-la.myXpos);
    float differenceY=fabsf(fa.myYpos-la.myYpos);
    
    BOOL isNormal=NO;
    BOOL is1pxX=NO;
    BOOL is1pxY=NO;
    BOOL is1x1=NO;
    
    if(differenceX>1 && differenceY>1)
        isNormal=YES;
    else if(differenceX>1 && differenceY==1)
        is1pxY=YES;
    else if(differenceX==1 && differenceY>1)
        is1pxX=YES;
    else if(differenceX==1 && differenceY==1)
        is1x1=YES;
    
    if(isNormal)
    {
        if(CGPointEqualToPoint(first, this))
            tile.tileType=kBottomLeft;
        else if(CGPointEqualToPoint(ccp(last.x-1,last.y-1), this))
            tile.tileType=kTopRight;
        else if(CGPointEqualToPoint(ccp(first.x,last.y-1), this))
            tile.tileType=kTopLeft;
        else if(CGPointEqualToPoint(ccp(last.x-1,first.y), this))
            tile.tileType=kBottomRight;
        else if(first.x==this.x && this.y!=first.y && this.y!=last.y)
            tile.tileType=kBorderLeft;
        else if(last.x-1==this.x && this.y!=first.y && this.y!=last.y)
            tile.tileType=kBorderRight;
        else if(first.y==this.y && this.x!=first.x && this.x!=last.x)
            tile.tileType=kBorderBottom;
        else if(last.y-1==this.y && this.x!=first.x && this.x!=last.x)
            tile.tileType=kBorderTop;
        else
            tile.tileType=kNoBorder;
    }
    else if(is1pxX)
    {
        if(CGPointEqualToPoint(first, this))
            tile.tileType=kEndCapBottom;
        else if(CGPointEqualToPoint(ccp(last.x-1,last.y-1), this))
            tile.tileType=kEndCapTop;
        else
            tile.tileType=kMidPieceVertical;
    }
    else if(is1pxY)
    {
        if(CGPointEqualToPoint(first, this))
            tile.tileType=kEndCapLeft;
        else if(CGPointEqualToPoint(ccp(last.x-1, last.y-1), this))
            tile.tileType=kEndCapRight;
        else
            tile.tileType=kMidPieceHorizontal;
    }
    else if(is1x1)
    {
        tile.tileType=kFullBorder;
    }
    
    // check the requested tile type, then like, set our sprite to reflect this
    if(tile.tileType==kTopLeft)
    {
        spriteFileName=@"/images/dotgrid/DG_Corner";
        reqRotation=0.0f;
    }
    if(tile.tileType==kTopRight)
    {
        spriteFileName=@"/images/dotgrid/DG_Corner";
        reqRotation=90.0f;
    }
    if(tile.tileType==kBottomLeft)
    {
        spriteFileName=@"/images/dotgrid/DG_Corner";
        reqRotation=270.0f;
    }
    if(tile.tileType==kBottomRight)
    {
        spriteFileName=@"/images/dotgrid/DG_Corner";
        reqRotation=180.0f;
    }
    if(tile.tileType==kBorderLeft)
    {
        spriteFileName=@"/images/dotgrid/DG_OneSide";
        reqRotation=270.0f;
    }
    if(tile.tileType==kBorderRight)
    {
        spriteFileName=@"/images/dotgrid/DG_OneSide";
        reqRotation=90.0f;
    }
    if(tile.tileType==kBorderTop)
    {
        spriteFileName=@"/images/dotgrid/DG_OneSide";
        reqRotation=0.0f;
    }
    if(tile.tileType==kBorderBottom)
    {
        spriteFileName=@"/images/dotgrid/DG_OneSide";
        reqRotation=180.0f;
    }
    if(tile.tileType==kNoBorder)
    {
        spriteFileName=@"/images/dotgrid/DG_Border_None";
    }
    if(tile.tileType==kFullBorder)
    {
        spriteFileName=@"/images/dotgrid/DG_Sq";
    }
    if(tile.tileType==kEndCapLeft)
    {
        spriteFileName=@"/images/dotgrid/DG_3sides";
        reqRotation=0.0f;
    }
    if(tile.tileType==kEndCapRight)
    {
        spriteFileName=@"/images/dotgrid/DG_3sides";
        reqRotation=180.0f;
    }
    if(tile.tileType==kEndCapTop)
    {
        spriteFileName=@"/images/dotgrid/DG_3sides";
        reqRotation=90.0f;
    }
    if(tile.tileType==kEndCapBottom)
    {
        spriteFileName=@"/images/dotgrid/DG_3sides";
        reqRotation=270.0f;
    }
    if(tile.tileType==kMidPieceHorizontal)
    {
        spriteFileName=@"/images/dotgrid/DG_Top&Bottom";
    }
    if(tile.tileType==kMidPieceVertical)
    {
        spriteFileName=@"/images/dotgrid/DG_Top&Bottom";
        reqRotation=90.0f;
    }


    
    thisTile.spriteFileName=spriteFileName;
    thisTile.Rotation=reqRotation;

    return thisTile;

}

-(void)resetSprite
{
    tileProperties thisTile=[self decideTileType];
    
    NSString *spriteFileName=[NSString stringWithFormat:@"%@%d.png", thisTile.spriteFileName, tile.tileSize];
    
    [tile.mySprite removeFromParentAndCleanup:YES];
    tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(spriteFileName)];
    [tile.mySprite setPosition:tile.Position];
    [tile.RenderLayer addChild:tile.mySprite];
    [tile.mySprite setRotation:thisTile.Rotation];
    
    NSLog(@"tile type: %@, rotation %f, scaleX %g, scaleY %g", spriteFileName, thisTile.Rotation, tile.mySprite.scaleX, tile.mySprite.scaleY);
}

-(void)setSprite
{    
    tileProperties thisTile=[self decideTileType];
    NSString *spriteFileName=thisTile.spriteFileName;
    float reqRotation=thisTile.Rotation;
    
    tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@%d.png", spriteFileName, tile.tileSize]))];
    [tile.mySprite setPosition:tile.Position];
    [tile.mySprite setRotation:reqRotation];
    
    tile.selectedSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/dotgrid/DG_Selected_Sq%d.png", tile.tileSize]))];
    [tile.selectedSprite setPosition:tile.Position];
    [tile.RenderLayer addChild:tile.selectedSprite];
    
    // THE TINTING BEHAVIOUR HERE CAN ALSO BE APPLIED BY THE SHAPE TOUCH BEHAVIOUR    
    if(tile.Selected)[tile.selectedSprite setVisible:YES];
    else([tile.selectedSprite setVisible:NO]);
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [tile.mySprite setTag:2];
        [tile.mySprite setOpacity:0];
    }
    
    
    
    
    
    
    [tile.RenderLayer addChild:tile.mySprite z:2];
    
    [spriteFileName release];
}

-(void)setSpritePos:(BOOL) withAnimation
{
    
    
}

-(void) dealloc
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller unregisterPollee:(id<LogPolling>)tile];
    [super dealloc];
}

@end
