//
//  BlockHolder.m
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockHolder.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "BlockFloating.h"

@implementation BlockHolder

+(CCScene *) scene
{
    CCScene *scene=[CCScene node];
    
    BlockHolder *layer=[BlockHolder node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=NO;
     
        cx=[[CCDirector sharedDirector] winSize].width / 2.0f;
        cy=[[CCDirector sharedDirector] winSize].height / 2.0f;

        [self setupBkgAndTitle];
        
        [self setupAudio];
        
        [self setupSprites];
        
        [self setupGW];
        
        //psuedo placeholder -- this is where we break into logical model representation
        [self populateGW];
        
        //general go-oriented render, etc
        [gameWorld handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        [self schedule:@selector(doUpdate:) interval:1.0f/60.0f];
    }
    
    return self;
}

-(void)setupBkgAndTitle
{
    CCSprite *bkg=[CCSprite spriteWithFile:@"bg-ipad-blockholder.png"];
    [bkg setPosition:ccp(cx, cy)];
    [self addChild:bkg];
    
    CCLabelTTF *title=[CCLabelTTF labelWithString:@"Block Holder" fontName:TITLE_FONT fontSize:TITLE_SIZE];
    
    [title setColor:TITLE_COLOR3];
    [title setOpacity:TITLE_OPACITY];
    [title setPosition:ccp(cx, cy + (0.75f*cy))];
    
    [self addChild:title];    
    
    CCSprite *btnFwd=[CCSprite spriteWithFile:@"btn-fwd.png"];
    [btnFwd setPosition:ccp(1024-18-10, 768-28-5)];
    [self addChild:btnFwd z:2];
}

-(void)setupAudio
{
    //pre load sfx
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.wav"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"putdown.wav"];
}

-(void)setupSprites
{
    
}

-(void)setupGW
{
    gameWorld=[[DWGameWorld alloc]initWithGameScene:self];
    
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(touching)return;
    touching=YES;
    
    UITouch *touch=[touches anyObject];
    CGPoint location=[touch locationInView: [touch view]];
    location=[[CCDirector sharedDirector] convertToGL:location];
    

    if(location.x>975 & location.y>720)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFadeBL transitionWithDuration:0.4f scene:[BlockFloating scene]]];
    }
    else
    {
    tapCount = [touch tapCount];
        
        [gameWorld Blackboard].PickupObject=nil;
        
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        //broadcast search for pickup object gw
        [gameWorld handleMessage:kDWareYouAPickupTarget andPayload:pl withLogLevel:0];
        
        if([gameWorld Blackboard].PickupObject!=nil)
        {
            [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.wav"];
            NSLog(@"got a pickup object");
            
            //if double tapped return pickupGO to feature store 
            if(tapCount == 2)
            {
                DWGameObject *freeStoreMount = nil;
                
                for (DWGameObject *mount in [gameWorld Blackboard].AllStores)
                {
                    //check if free mount not already found and mount is free
                    if(freeStoreMount==nil)
                        if([[mount store] objectForKey:MOUNTED_OBJECT]==nil) 
                            freeStoreMount = mount;
                    
                    //check if pickupGO is not already in feature store
                    if([[[gameWorld Blackboard].PickupObject store] objectForKey:MOUNT]==mount)
                    {
                        freeStoreMount = nil;
                        break; //stop loop
                    }
                }
                
                if(freeStoreMount!=nil)
                {
                    [pl removeAllObjects]; 
                    [pl setObject:freeStoreMount forKey:MOUNT];
                    [[gameWorld Blackboard].PickupObject handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
                    
                    [gameWorld Blackboard].PickupObject = nil; //drop pickup object
                    NSLog(@"returned object to store");
                }
            }
        }
    }
}


-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
	CGPoint location=[touch locationInView: [touch view]];
	location=[[CCDirector sharedDirector] convertToGL:location];
    
    if([gameWorld Blackboard].PickupObject!=nil)
    {
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        [[gameWorld Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:pl withLogLevel:0];
    }
    
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touching=NO;
    
    UITouch *touch=[touches anyObject];
	CGPoint location=[touch locationInView: [touch view]];
	location=[[CCDirector sharedDirector] convertToGL:location];
	
    if([gameWorld Blackboard].PickupObject!=nil)
    {
        //look for player pickup / drops
        
        [gameWorld Blackboard].DropObject=nil;
        NSMutableDictionary *pl=[[NSMutableDictionary alloc] init];
        [pl setObject:[NSNumber numberWithFloat:location.x] forKey:POS_X];
        [pl setObject:[NSNumber numberWithFloat:location.y] forKey:POS_Y];
        
        //broadcast search for pickup object gw
        [gameWorld handleMessage:kDWareYouADropTarget andPayload:pl withLogLevel:0];
        
        if([gameWorld Blackboard].DropObject!=nil)
        {
            //we have a drop target, tell the pickGO to move to the dropGO
            [pl removeAllObjects];
            [pl setObject:[gameWorld Blackboard].DropObject forKey:MOUNT];
            [[gameWorld Blackboard].PickupObject handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
            
            NSLog(@"re-mounted pickupGO");
            [[SimpleAudioEngine sharedEngine] playEffect:@"putdown.wav"];
            
        }
        else
        {
            [[gameWorld Blackboard].PickupObject handleMessage:kDWupdateSprite andPayload:nil withLogLevel:0];
            
            NSLog(@"returned pickupGO");
        }
        
        [gameWorld Blackboard].PickupObject=nil;
    }
    
}

-(void)populateGW
{
    //mounts (containers)
    DWGameObject *m1=[gameWorld addGameObjectWithTemplate:@"Tcontainer"];
    [[m1 store] setObject:[NSNumber numberWithFloat:230.0f] forKey:POS_X];
    [[m1 store] setObject:[NSNumber numberWithFloat:283.0f] forKey:POS_Y];
    
    DWGameObject *m2=[gameWorld addGameObjectWithTemplate:@"Tcontainer"];
    [[m2 store] setObject:[NSNumber numberWithFloat:418.0f] forKey:POS_X];
    [[m2 store] setObject:[NSNumber numberWithFloat:283.0f] forKey:POS_Y];
    
    DWGameObject *m3=[gameWorld addGameObjectWithTemplate:@"Tcontainer"];
    [[m3 store] setObject:[NSNumber numberWithFloat:606.0f] forKey:POS_X];
    [[m3 store] setObject:[NSNumber numberWithFloat:283.0f] forKey:POS_Y];
    
    DWGameObject *m4=[gameWorld addGameObjectWithTemplate:@"Tcontainer"];
    [[m4 store] setObject:[NSNumber numberWithFloat:794.0f] forKey:POS_X];
    [[m4 store] setObject:[NSNumber numberWithFloat:283.0f] forKey:POS_Y];
    
    
    //stores -- 4 of them
    DWGameObject *s1=[gameWorld addGameObjectWithTemplate:@"Tstore"];
    [[s1 store] setObject:[NSNumber numberWithFloat:96.0f] forKey:POS_X];
    [[s1 store] setObject:[NSNumber numberWithFloat:670.0f] forKey:POS_Y];

    DWGameObject *s2=[gameWorld addGameObjectWithTemplate:@"Tstore"];
    [[s2 store] setObject:[NSNumber numberWithFloat:253.0f] forKey:POS_X];
    [[s2 store] setObject:[NSNumber numberWithFloat:670.0f] forKey:POS_Y];
    
    DWGameObject *s3=[gameWorld addGameObjectWithTemplate:@"Tstore"];
    [[s3 store] setObject:[NSNumber numberWithFloat:407.0f] forKey:POS_X];
    [[s3 store] setObject:[NSNumber numberWithFloat:670.0f] forKey:POS_Y];
    
    DWGameObject *s4=[gameWorld addGameObjectWithTemplate:@"Tstore"];
    [[s4 store] setObject:[NSNumber numberWithFloat:565.0f] forKey:POS_X];
    [[s4 store] setObject:[NSNumber numberWithFloat:670.0f] forKey:POS_Y];
    
    
    //objects -- create two for now
    DWGameObject *o1=[gameWorld addGameObjectWithTemplate:@"Tobject"];
    //send store 1 as mount for this object
    NSDictionary *pl1=[NSDictionary dictionaryWithObject:s1 forKey:MOUNT];
    [o1 handleMessage:kDWsetMount andPayload:pl1 withLogLevel:0];
        
    DWGameObject *o2=[gameWorld addGameObjectWithTemplate:@"Tobject"];
    //send store 1 as mount for this object
    NSDictionary *pl2=[NSDictionary dictionaryWithObject:s2 forKey:MOUNT];
    [o2 handleMessage:kDWsetMount andPayload:pl2 withLogLevel:0];
     
}

-(void)doUpdate:(ccTime)delta
{
    [gameWorld doUpdate:delta];
}


-(void)dealloc
{
    [super dealloc];
}

@end
