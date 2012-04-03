//
//  PartitionTool.m
//  belugapad
//
//  Created by David Amphlett on 29/03/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "PartitionTool.h"
#import "global.h"
#import "ToolHost.h"
#import "DWPartitionObjectGameObject.h"
#import "DWPartitionRowGameObject.h"
#import "DWPartitionStoreGameObject.h"
#import "SimpleAudioEngine.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"

@implementation PartitionTool
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    problemDef=pdef;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        gw = [[DWGameWorld alloc] initWithGameScene:self];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];

        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [self readPlist:pdef];
        [self populateGW];
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        gw.Blackboard.inProblemSetup = NO;
        
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    

}

-(void)readPlist:(NSDictionary*)pdef
{
    renderLayer = [[CCLayer alloc] init];
    [self.ForeLayer addChild:renderLayer];
    
    gw.Blackboard.ComponentRenderLayer = renderLayer;
    
    // All our stuff needs to go into vars to read later
    
    initBars = [pdef objectForKey:INIT_BARS];
    [initBars retain];
    initObjects = [pdef objectForKey:INIT_OBJECTS];
    [initObjects retain];
    initCages = [pdef objectForKey:INIT_CAGES];
    [initCages retain];
    solutionsDef = [pdef objectForKey:SOLUTIONS];
    [solutionsDef retain];
    
    [createdRows retain];
    
    
    problemDescLabel=[CCLabelTTF labelWithString:[pdef objectForKey:PROBLEM_DESCRIPTION] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
    [problemDescLabel setPosition:ccp(cx, kLabelTitleYOffsetHalfProp*cy)];
    //[problemDescLabel setColor:kLabelTitleColor];
    [problemDescLabel setTag:3];
    [problemDescLabel setOpacity:0];
    [self.ForeLayer addChild:problemDescLabel];
    
}

-(void)populateGW
{


    //DWPartitionStoreGameObject *psgo = 

    float yStartPos=582;
    // do stuff with our INIT_BARS (DWPartitionRowGameObject)
    for (int i=0;i<[initBars count]; i++)
    {
        //float xStartPos=512;
        float xStartPos=(cx-(([[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue]*50)/2)+25);
        for(int go=0;go<[[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue];go++) {
            DWPartitionRowGameObject *prgo = [DWPartitionRowGameObject alloc];
            [gw populateAndAddGameObject:prgo withTemplateName:@"TpartitionRow"];
            prgo.Position=ccp(xStartPos,yStartPos);
            prgo.Length = [[[initBars objectAtIndex:i] objectForKey:LENGTH] intValue];
            prgo.Locked = [[[initBars objectAtIndex:i] objectForKey:LOCKED] boolValue];
            if(go==0) prgo.LeftPiece=YES;
            if(go==prgo.Length-1 && prgo.Locked)prgo.RightPiece=YES;
        
            [createdRows addObject:prgo];
            xStartPos=xStartPos+50;
        }
        
        xStartPos = 512;
    yStartPos = yStartPos-100;
    }
    
    // do stuff with our INIT_CAGES (DWPartitionStoreGameObject)
    for (int i=0;i<[initCages count]; i++)
    {
        int qtyForThisStore=[[[initCages objectAtIndex:i] objectForKey:QUANTITY] intValue];
        for (int ic=0;ic<qtyForThisStore;ic++)
        {
            DWPartitionObjectGameObject *pogo = [DWPartitionObjectGameObject alloc];
            [gw populateAndAddGameObject:pogo withTemplateName:@"TpartitionObject"];
            //DWPartitionStoreGameObject *psgo = [DWPartitionStoreGameObject alloc];
            //[gw populateAndAddGameObject:psgo withTemplateName:@"TpartitionStore"];
            pogo.Position=ccp(100,184+(i*100));
            //pogo.Label=[[initCages objectAtIndex:i] objectForKey:LABEL];
            pogo.Length=[[[initCages objectAtIndex:i] objectForKey:LENGTH] intValue];
        }
    }
    
    // do stuff with our INIT_OBJECTS (DWPartitionObjectGameObject)    
    for (int i=0;i<[initObjects count]; i++)
    {
        //DWPartitionObjectGameObject *pogo = [DWPartitionObjectGameObject alloc];
        //[gw populateAndAddGameObject:pogo withTemplateName:@"TpartitionObject"];
        //pogo.Position=ccp(512,284);
    }

}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(isTouching)return;
    isTouching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];

    
    [gw Blackboard].PickupObject=nil;
    
    NSMutableDictionary *pl=[[[NSMutableDictionary alloc] init] autorelease];
    [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
    [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
    
    //broadcast search for pickup object gw
    [gw handleMessage:kDWareYouAPickupTarget andPayload:pl withLogLevel:-1];
    
    if([gw Blackboard].PickupObject!=nil)
    {
        gw.Blackboard.DropObject=nil;
        gw.Blackboard.PickupOffset = location;

        
        //this is just a signal for the GO to us, pickup object is retained on the blackboard
        [[gw Blackboard].PickupObject handleMessage:kDWpickedUp andPayload:nil withLogLevel:0];
        
        [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/pickup.wav")];
        
        [[gw Blackboard].PickupObject logInfo:@"this object was picked up" withData:0];
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    
    if([gw Blackboard].PickupObject != nil)
    {
        DWPartitionObjectGameObject *pogo = (DWPartitionObjectGameObject*)[gw Blackboard].PickupObject;
        pogo.MovePosition = location;
        [[gw Blackboard].PickupObject handleMessage:kDWmoveSpriteToPosition];
        
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    isTouching=NO;

    NSMutableDictionary *pl=[[[NSMutableDictionary alloc] init] autorelease];
    [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
    [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
    
    if([gw Blackboard].PickupObject!=nil)
    {
        [gw handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:-1];
        
        if([gw Blackboard].DropObject!=nil)
        {
            NSLog(@"got a dropobject!");
            //[gw handleMessage:kDWsetMount];
        }
        else
        {
            [[gw Blackboard].PickupObject handleMessage:kDWmoveSpriteToHome];
        }
    }
    
    [gw Blackboard].PickupObject=nil;

}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching=NO;
}

-(void) dealloc
{
    //write log on problem switch
    [gw writeLogBufferToDiskWithKey:@"PartitionTool"];
    
    //tear down
    [gw release];
    
    [self.ForeLayer removeAllChildrenWithCleanup:YES];
    [self.BkgLayer removeAllChildrenWithCleanup:YES];
    
    if(initBars) [initBars release];
    if(initObjects) [initObjects release];
    if(initCages) [initCages release];
    if(solutionsDef) [solutionsDef release];
    if(createdRows) [createdRows release];
    [super dealloc];
}

@end
