//
//  JourneyScene.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JourneyScene.h"

#import "UsersService.h"

#import "Daemon.h"
#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"
#import "ContentService.h"
#import "UsersService.h"

#import "ConceptNode.h"
#import "Pipeline.h"

#import "ToolHost.h"

#import "SimpleAudioEngine.h"

#import "SGGameWorld.h"
#import "SGJmapNode.h"
#import "SGJmapMasteryNode.h"
#import "SGJmapProximityEval.h"

#import "JSONKit.h"

static float kNodeScale=0.5f;
//static CGPoint kStartMapPos={-3576, -2557};
static CGPoint kStartMapPos={-611, 3713};
static float kPropXNodeHitDist=0.065f;


const float kLogOutBtnPadding = 8.0f;
const CGSize kLogOutBtnSize = { 120.0f, 43.0f };

static CGRect debugButtonBounds={{950, 0}, {100, 50}};
static BOOL debugRestrictMovement=NO;

typedef enum {
    kJuiStateNodeMap,
    kJuiStateNodeSliceTransition,
    kJuiStateNodeSlice
} JuiState;

@interface JourneyScene()
{
    @private
    ContentService *contentService;

    NSMutableArray *kcmNodes;
        
    JuiState juiState;
    
    float nMinX, nMinY, nMaxX, nMaxY;
    float scale;
    
    BOOL touchStartedInNodeMap;
        
    UsersService *usersService;
    
    float deltacum;
    
    CGPoint logOutBtnCentre;
    CGRect logOutBtnBounds;
    
    //game world
    SGGameWorld *gw;
    
    //game world rendering
    CCSpriteBatchNode *nodeRenderBatch;
    
    //debug stuff
    BOOL debugEnabled;
    CCMenu *debugMenu;
}

-(void)debugRelocate:(id)sender;
-(void)debugRebuildNodeTris:(id)sender;

@end

@implementation JourneyScene

#pragma mark - init

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    JourneyScene *layer=[JourneyScene node];
    [scene addChild:layer];
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        [[CCDirector sharedDirector] view].multipleTouchEnabled=NO;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx = lx / 2.0f;
        cy = ly / 2.0f;
        
        juiState=kJuiStateNodeMap;
        
        scale=1.0f;
        
        contentService = ((AppController*)[[UIApplication sharedApplication] delegate]).contentService; 
        usersService = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
        
        debugEnabled=!((AppController*)[[UIApplication sharedApplication] delegate]).ReleaseMode;
        if(debugEnabled) [self buildDebugMenu];
        
        [self setupMap];
        
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        [self schedule:@selector(doUpdateProximity:) interval:15.0f / 60.0f];
                
//        daemon=[[Daemon alloc] initWithLayer:foreLayer andRestingPostion:ccp(cx, cy) andLy:ly];
//        [daemon setMode:kDaemonModeFollowing];
        
        logOutBtnBounds=CGRectMake(kLogOutBtnPadding, winsize.height - kLogOutBtnSize.height - kLogOutBtnPadding, kLogOutBtnSize.width, kLogOutBtnSize.height);
//        
//        logOutBtnBounds = CGRectMake(winsize.width-kLogOutBtnSize.width - kLogOutBtnPadding, kLogOutBtnPadding, 
//                                     kLogOutBtnSize.width, kLogOutBtnSize.height);        
        logOutBtnCentre = CGPointMake(logOutBtnBounds.origin.x + kLogOutBtnSize.width/2, logOutBtnBounds.origin.y + kLogOutBtnSize.height/2);
        CCSprite *b=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/log-out.png")];
        [b setPosition:logOutBtnCentre];
        [foreLayer addChild:b];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/mood.mp3") loop:YES];
    }
    
    return self;
}

#pragma mark - setup and parse

-(void) setupGw;
{
    gw=[[SGGameWorld alloc] initWithGameScene:self];
    
    //setup render batch for nodes
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/jmap/node-icons.plist")];
    nodeRenderBatch=[CCSpriteBatchNode batchNodeWithFile:BUNDLE_FULL_PATH(@"/images/jmap/node-icons.png")];
    [mapLayer addChild:nodeRenderBatch];
    
}

-(void) setupMap
{
    [self createLayers];
    
    [self setupGw];
    
    NSLog(@"start build");
    
    kcmNodes=[NSMutableArray arrayWithArray:[contentService allConceptNodes]];
    [kcmNodes retain];
    
    NSLog(@"got kcm node");
    
    [self parseKcmForBounds];
    
    NSLog(@"got kcm bounds");
    
    [self createNodesInGameWorld];
    
    NSLog(@"created node, mastery game objects");
    
    [self parseNodesForEndPoints];
    
    NSLog(@"completed end point parse");
    NSLog(@"end build");
            
    //reposition if previous node
    if(contentService.currentNode)
    {
        //put map at this position
        CGPoint p=ccp(contentService.currentNode.x * kNodeScale, -(nMaxY - contentService.currentNode.y) * kNodeScale);
        p=ccpAdd(ccp(cx, cy), p);
        [mapLayer setPosition:p];
    }
    
    NSLog(@"node bounds are %f, %f -- %f, %f", nMinX, nMinY, nMaxX, nMaxY);
}

- (void)createLayers
{
    //base colour layer
    CCLayer *cLayer=[[CCLayerColor alloc] initWithColor:ccc4(54, 59, 59, 255) width:lx height:ly];
    [self addChild:cLayer z:-1];
    
    //base map layer
    mapLayer=[[CCLayer alloc] init];
    [mapLayer setPosition:kStartMapPos];        

    [self addChild:mapLayer z:-1];

    //fore layer
    foreLayer=[[CCLayer alloc] init];
    [self addChild:foreLayer z:-1];
    
}

- (void)createAllBackgroundTileSprites
{
    //add background to the map itself
    
    int rsize=(int)((nMaxY-nMinY) / ly);
    int csize=(int)((nMaxX-nMinX) / lx);
    
    for (int r=0; r<=rsize; r++) {
        for (int c=0; c<csize; c++) {
            CCSprite *btile=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/mapbase.png")];
            [btile setPosition:ccp((lx*c)+cx, (ly*r)+cy)];
            [mapLayer addChild:btile];
        }
    }
}

- (void)parseKcmForBounds
{
    //find bounds
    //set bounds to first element
    if(kcmNodes.count>0)
    {
        ConceptNode *n1=[kcmNodes objectAtIndex:0];
        nMinX=(float)n1.x;
        nMinY=(float)n1.y;
        nMaxX=nMinX;
        nMaxY=nMaxY;
        
        for (int i=1; i<[kcmNodes count]; i++) {
            ConceptNode *n=[kcmNodes objectAtIndex:i];
            
            if((float)n.x<nMinX)nMinX=(float)n.x;
            if((float)n.y<nMinY)nMinY=(float)n.y;
            if((float)n.x>nMaxX)nMaxX=(float)n.x;
            if((float)n.y>nMaxY)nMaxY=(float)n.y;
        }
    }
    
    nMinX=nMinX*kNodeScale;
    nMinY=nMinY*kNodeScale;
    nMaxX=nMaxX*kNodeScale;
    nMaxY=nMaxY*kNodeScale;
}

-(void)createNodesInGameWorld
{
    //create nodes
    for (int i=1; i<[kcmNodes count]; i++) {
        ConceptNode *n=[kcmNodes objectAtIndex:i];
        
        //node position
        CGPoint nodepos=ccp((float)n.x * kNodeScale, (nMaxY-(float)n.y) * kNodeScale);

        id<CouchDerived> newnode;
        
        //create a node go
        if(n.mastery)
        {
            newnode=[[SGJmapMasteryNode alloc] initWithGameWorld:gw andRenderBatch:nodeRenderBatch andPosition:nodepos];
        }
        else {
            newnode=[[SGJmapNode alloc] initWithGameWorld:gw andRenderBatch:nodeRenderBatch andPosition:nodepos];
        }   
        
        newnode._id=n._id;
    }
}

-(void)parseNodesForEndPoints
{
    NSArray *prereqs=[contentService relationMembersForName:@"Prerequisite"];
    for (NSString *rel in prereqs) {
        NSArray *pair=[rel objectFromJSONString];
        id leftgo=[self gameObjectForCouchId:[pair objectAtIndex:0]];
        SGJmapMasteryNode *rightgo=[self gameObjectForCouchId:[pair objectAtIndex:1]];
        
        [rightgo.PrereqNodes addObject:leftgo];
    }
}

-(id)gameObjectForCouchId:(NSString*)findId
{
    for (id go in [gw AllGameObjects]) {
        if([go conformsToProtocol:@protocol(CouchDerived)])
        {
            if([((id<CouchDerived>)go)._id isEqualToString:findId])
            {
                return go;
            }
        }
    }
    return nil;
}

#pragma mark drawing and sprite creation

-(CGPoint)currentCentre
{
    CGPoint c=ccp(-mapLayer.position.x + (0.5f*lx), -mapLayer.position.y + (0.5f*ly));
    return c;
}


#pragma mark loops

-(void) doUpdate:(ccTime)delta
{
    [gw doUpdate:delta];
    
    //[daemon doUpdate:delta];
    deltacum+=delta;
}

-(void) doUpdateProximity:(ccTime)delta
{
    CGPoint p=[self currentCentre];
    
    for (id go in [gw AllGameObjects]) {
        if([go conformsToProtocol:@protocol(ProximityResponder)])
        {
            [((id<ProximityResponder>)go).ProximityEvalComponent actOnProximityTo:p];
        }
    }
}

#pragma mark - draw

-(void)draw
{    
    for(id go in [gw AllGameObjects]) {
        if([go conformsToProtocol:@protocol(Drawing)])
            [((id<Drawing>)go) draw];
    }
}

#pragma mark - location testing and queries

-(ConceptNode*) nodeWithin:(float)distance ofLocation:(CGPoint)location
{
    //returns first node withing distance of location
    for(int i=0; i<kcmNodes.count; i++)
    {
        ConceptNode *n=[kcmNodes objectAtIndex:i];
        
        
        CGPoint nlpos=ccp((float)n.x * kNodeScale, (nMaxY-(float)n.y) * kNodeScale);
        float diff=[BLMath DistanceBetween:location and:nlpos];
        
        if(diff<distance)
        {
            return n;
        }
    }
    return nil;
}

#pragma mark transitions

//-(void)createNodeSliceFrom:(ConceptNode*)n
//{
//    //establish if there are problems
//    currentNodeSliceHasProblems=n.pipelines.count>0;
//    if(currentNodeSliceHasProblems)
//    {
//        currentNodeSliceHasProblems=NO;
//        for (int i=0; i<n.pipelines.count; i++) {
//            Pipeline *p = [contentService pipelineWithId:[n.pipelines objectAtIndex:i]];
//            
//            if(p.problems.count>0 && [p.name isEqualToString:@"25May"])
//            {
//                currentNodeSliceHasProblems=YES;
//                break;
//            }
//        }
//    }
//    
//    NSString *bpath=BUNDLE_FULL_PATH(@"/images/journeymap/nodeslice-bkg.png");
//    if(!currentNodeSliceHasProblems) bpath=BUNDLE_FULL_PATH(@"/images/journeymap/nodeslice-bkg-nopin.png");
//    
//    CCSprite *ns=[CCSprite spriteWithFile:bpath];
//    [ns setScale:kNodeSliceStartScale];
//    [ns setPosition:n.journeySprite.position];
//
//    [mapLayer addChild:ns];
//    [nodeSliceNodes addObject:n];
//    
//    n.nodeSliceSprite=ns;
//    
//    float time1=0.1f;
//    float time2=0.9f;
//    float time3=0.2f;
//    
//    CCScaleTo *scale1=[CCScaleTo actionWithDuration:time1 scale:0.3f];
//    CCScaleTo *scale2=[CCScaleTo actionWithDuration:time2 scale:0.5f];
//    CCEaseOut *ease2=[CCEaseOut actionWithAction:scale2 rate:0.5f];
//    CCScaleTo *scale3=[CCScaleTo actionWithDuration:time3 scale:1.0f];
//    CCSequence *scaleSeq=[CCSequence actions:scale1, ease2, scale3, nil];
//    
//    CCDelayTime *move1=[CCDelayTime actionWithDuration:time1 + time2];
//    CCMoveTo *move2=[CCMoveTo actionWithDuration:time3 position:[mapLayer convertToNodeSpace:kNodeSliceOrigin]];
//    CCSequence *moveSeq=[CCSequence actions:move1, move2, nil];
//    
//    [ns runAction:scaleSeq];
//    [ns runAction:moveSeq];
//}
//
//-(void)cancelNodeSliceTransition
//{
//    if(!currentNodeSliceNode) return;
//    
//    CCSprite *ns=currentNodeSliceNode.nodeSliceSprite;
//    
//    [ns stopAllActions];
//    
//    CCScaleTo *scaleto=[CCScaleTo actionWithDuration:0.2f scale:kNodeSliceStartScale];
//    CCFadeOut *fade=[CCFadeOut actionWithDuration:0.6f];
//    CCMoveTo *moveto=[CCMoveTo actionWithDuration:0.2f position:currentNodeSliceNode.journeySprite.position];
//    [ns runAction:scaleto];
//    [ns runAction:fade];
//    [ns runAction:moveto];
//    
//    currentNodeSliceNode=nil;
//}
//
//-(void)tidyUpRemovedNodeSlices
//{
//    NSMutableArray *removedS=[[NSMutableArray alloc] init];
//    
//    for (ConceptNode *n in nodeSliceNodes) {
//        if(n.nodeSliceSprite.opacity==0)
//        {
//            [mapLayer removeChild:n.nodeSliceSprite cleanup:YES];
//            //[n.nodeSliceSprite release];
//            n.nodeSliceSprite=nil;
//            [removedS addObject:n];
//            
//        }
//    }
//    
//    [nodeSliceNodes removeObjectsInArray:removedS];
//    [removedS release];
//}
//
//-(void)removeNodeSlices
//{
//    [self tidyUpRemovedNodeSlices];
//    
//    if([lightSprites containsObject:nodeSliceLight])[lightSprites removeObject:nodeSliceLight];
//    
//    for (ConceptNode *n in nodeSliceNodes) {
//        
//        CCSprite *ns=n.nodeSliceSprite;
//        
//        if(ns.opacity==255)
//        {
//            CCScaleTo *scaleto=[CCScaleTo actionWithDuration:0.2f scale:kNodeSliceStartScale];
//            CCFadeOut *fade=[CCFadeOut actionWithDuration:0.6f];
//            CCMoveTo *moveto=[CCMoveTo actionWithDuration:0.2f position:n.journeySprite.position];
//            [ns runAction:scaleto];
//            [ns runAction:fade];
//            [ns runAction:moveto];
//        }
//    }
//    
//}

#pragma mark user i/o

//-(void)startSeletedPin
//{
//    NSLog(@"starting pipeline 0 for node %@", currentNodeSliceNode._id);
//    
//    if (currentNodeSliceNode.pipelines.count>0) {
//        //need to get the right pipeline -- named @"25May"
//        for (NSString *pid in currentNodeSliceNode.pipelines) {
//            Pipeline *p=[contentService pipelineWithId:pid];
//            if([p.name isEqualToString:@"25May"])
//            {
//                [contentService startPipelineWithId:pid forNode:currentNodeSliceNode];
//                [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
//                break;
//            }
//        }
//    }
//    else {
//        NSLog(@"failed to start -- no pipelines found");
//    }
//}

#pragma mark touch handling



-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
    if(CGRectContainsPoint(logOutBtnBounds, l))
    {
        [usersService logProblemAttemptEvent:kProblemAttemptExitLogOut withOptionalNote:nil];
        usersService.currentUser = nil;
        [(AppController*)[[UIApplication sharedApplication] delegate] returnToLogin];
        return;
    }
    
    if(debugEnabled && CGRectContainsPoint(debugButtonBounds, l))
    {
        BOOL doat=!debugMenu.enabled;
        debugMenu.enabled=doat;
        debugMenu.visible=doat;
    }
 
    lastTouch=l;
    
    CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
 
    NSLog(@"touched at %@", NSStringFromCGPoint(lOnMap));
    
//    [daemon setTarget:l];
//    [daemon setRestingPoint:l];
    
    //assume touch didn't start in the node map
    touchStartedInNodeMap=NO;

    if (juiState==kJuiStateNodeMap) {
                
        touchStartedInNodeMap=YES;
    }
}

- (void)testForNodeSliceTransitionStartWithTouchAt:(CGPoint)lOnMap
{
    //test for node hit and start transition
    ConceptNode *n=[self nodeWithin:(kPropXNodeHitDist * lx) ofLocation:lOnMap];
    if(n)
    {
        //[self createNodeSliceFrom:n];
        NSLog(@"hit node %@", n._id);
        
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
    if (touches.count==1) {
        
        if(touchStartedInNodeMap)
        {
            CGPoint newpos=[BLMath AddVector:mapLayer.position toVector:[BLMath SubtractVector:lastTouch from:l]];
            
            if(debugRestrictMovement)
            {
                if (newpos.x > 100) newpos.x=100;
                if (newpos.y > 4000) newpos.y=4000;

                if (newpos.x < -1400) newpos.x=-1400;
                if (newpos.y < 2300) newpos.y=2300;
            }
            
            [mapLayer setPosition:newpos];

            lastTouch=l;
            
//            CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
            
//            [daemon setTarget:l];    
//            [daemon setRestingPoint:l];
        }
    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

}

#pragma mark - debug

-(void)buildDebugMenu
{
    CCMenuItemLabel *i1=[CCMenuItemFont itemWithString:@"relocate to home" target:self selector:@selector(debugRelocate:)];
    CCMenuItemLabel *i2=[CCMenuItemFont itemWithString:@"rebuild node tris" target:self selector:@selector(debugRebuildNodeTris:)];
    
    debugMenu =[CCMenu menuWithItems:i1, i2, nil];
    
    [debugMenu alignItemsVertically];
    
    [self addChild:debugMenu z:10];
    debugMenu.visible=NO;
    debugMenu.enabled=NO;
    
}

-(void)debugRelocate:(id)sender
{
    NSLog(@"debug did reset map position");
    [mapLayer setPosition:kStartMapPos];   
}

-(void)debugRebuildNodeTris:(id)sender
{
    NSLog(@"debug did rebuild node tris");
}

#pragma mark - tear down

-(void)dealloc
{
    [kcmNodes release];
    
    [super dealloc];
}

@end
