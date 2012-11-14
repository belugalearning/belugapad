//
//  JourneyScene.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JMap.h"

#import "UsersService.h"
#import "ToolHost.h"

#import "Daemon.h"
#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"
#import "LoggingService.h"
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
#import "SGJmapNodeSelect.h"
#import "SGJmapRegion.h"
#import "SGJmapCloud.h"

#import "JSONKit.h"
#import "TestFlight.h"


#define DRAW_DEPTH 3

static float kNodeScale=0.5f;
//static CGPoint kStartMapPos={-3576, -2557};
static CGPoint kStartMapPos={-611, 3713};
//static float kPropXNodeHitDist=0.065f;


const float kLogOutBtnPadding = 8.0f;
const CGSize kLogOutBtnSize = { 80.0f, 33.0f };

static CGRect debugButtonBounds={{950, 0}, {100, 50}};
static BOOL debugRestrictMovement=NO;

typedef enum {
    kJuiStateNodeMap,
    kJuiStateNodeSliceTransition,
    kJuiStateNodeSlice
} JuiState;

@interface JMap()
{
@private
    LoggingService *loggingService;
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
    
    CCSprite *backarrow;
}

-(void)debugRelocate:(id)sender;
-(void)debugRebuildNodeTris:(id)sender;

@end

@implementation JMap

#pragma mark - init

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    JMap *layer=[JMap node];
    [scene addChild:layer];
    return scene;
}

-(id) init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx = lx / 2.0f;
        cy = ly / 2.0f;
        
        dragVel=ccp(0,0);
        dragLast=ccp(0,0);
        
        juiState=kJuiStateNodeMap;
        
        zoomedOut=NO;
        
        scale=1.0f;
        
        [TestFlight passCheckpoint:@"STARTING_JMAP"];
        
        ac = (AppController*)[[UIApplication sharedApplication] delegate];
        loggingService = ac.loggingService;
        usersService = ac.usersService;
        contentService = ac.contentService;
        
        [usersService syncDeviceUsers];
        
        [loggingService logEvent:BL_JS_INIT withAdditionalData:nil];
        [loggingService sendData];
        
        debugEnabled=!((AppController*)[[UIApplication sharedApplication] delegate]).ReleaseMode;
        if(debugEnabled) [self buildDebugMenu];
        
        [self setupMap];
        
        [self setupUI];
        
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        [self schedule:@selector(doUpdateProximity:) interval:15.0f / 60.0f];
                
//        daemon=[[Daemon alloc] initWithLayer:foreLayer andRestingPostion:ccp(cx, cy) andLy:ly];
//        [daemon setMode:kDaemonModeFollowing];
//        
//        logOutBtnBounds=CGRectMake(kLogOutBtnPadding, winsize.height - kLogOutBtnSize.height - kLogOutBtnPadding, kLogOutBtnSize.width, kLogOutBtnSize.height);
////        
////        logOutBtnBounds = CGRectMake(winsize.width-kLogOutBtnSize.width - kLogOutBtnPadding, kLogOutBtnPadding, 
////                                     kLogOutBtnSize.width, kLogOutBtnSize.height);        
//        logOutBtnCentre = CGPointMake(logOutBtnBounds.origin.x + kLogOutBtnSize.width/2, logOutBtnBounds.origin.y + kLogOutBtnSize.height/2);
//        CCSprite *b=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/log-out.png")];
//        [b setPosition:logOutBtnCentre];
//        [foreLayer addChild:b];
        
        //[[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/mood.mp3") loop:YES];
        
        [TestFlight passCheckpoint:@"STARTED_JMAP"];
        
    }
    
    return self;
}

#pragma mark - transitions

-(void)startTransitionToToolHostWithPos:(CGPoint)pos
{
//    mapLayer.anchorPoint=ccp(cx, cy);
//    
//    CCEaseInOut *ease=[CCEaseInOut actionWithAction:[CCScaleBy actionWithDuration:0.5f scale:4.0f] rate:2.0f];
//    [mapLayer runAction:ease];
//    
//    [self scheduleOnce:@selector(gotoToolHost:) delay:0.5f];
    
    [self gotoToolHost:0];
}

-(void)gotoToolHost:(ccTime)delta
{
    //[[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
    
    [TestFlight passCheckpoint:@"PROCEEDING_TO_TOOLHOST_FROM_JMAP"];
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_enter_question.wav")];
    contentService.resetPositionAfterTH=YES;
    contentService.lastMapLayerPosition=mapLayer.position;
    
    AppController *ac=(AppController*)[[UIApplication sharedApplication] delegate];
    
    if(ac.IsIpad1)
    {
        [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];        
    }
    else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:0.5f scene:[ToolHost scene]]];
    }
}

#pragma mark - setup and parse

-(void) setupGw;
{
    gw=[[SGGameWorld alloc] initWithGameScene:self];
    
    gw.Blackboard.RenderLayer=mapLayer;
    
}

-(void)populateImageCache
{
    //load some cached images
    
    //island texture bases (determined id generated from mastery pos)
    for(int i=1; i<10; i++)
    {
        NSString *file=[NSString stringWithFormat:@"/images/jmap/island-tex%d.png", i];
        [[CCTextureCache sharedTextureCache] addImage:BUNDLE_FULL_PATH(file)];
    }

    //water / base tile
    [[CCTextureCache sharedTextureCache] addImage:BUNDLE_FULL_PATH(@"/image/jmap/base-tile.png")];
    
}

-(void) setupMap
{
    [self populateImageCache];
 
    [self createLayers];
    
    [self setupGw];
    
    kcmNodes=[NSMutableArray arrayWithArray:[contentService allConceptNodes]];
    [kcmNodes retain];
    
    [self parseKcmForBounds];
    
    [self createNodesInGameWorld];
    
    [self parseNodesForEndPoints];
    
    //get nodes to calculate their offset from parent / mastery
    [gw handleMessage:kSGretainOffsetPosition];
    
    //force layout mastery
    for(int i=0; i<50; i++)
    {
        [gw handleMessage:kSGforceLayout];
    }
    
    //re-set node positions
    [gw handleMessage:kSGresetPositionUsingOffset];
    
    [self createRegions];
    
    //setup rendering -- needs all node connections built
    [gw handleMessage:kSGreadyRender];

    // position map so that bottom-most included node in view, bottom-left
    if (!contentService.resetPositionAfterTH)
    {
        CGPoint p = ccp(NSIntegerMax, NSIntegerMax);
        for (id go in [gw AllGameObjects]) {
            if([go isKindOfClass:[SGJmapMasteryNode class]])
            {
                CGPoint mnpos = ((SGJmapMasteryNode*)go).Position;
                if (mnpos.y < p.y || (mnpos.y == p.y && mnpos.x < p.x)) p = mnpos;
            }
        }
        if (p.y != NSIntegerMax) [mapLayer setPosition:ccp(300-p.x, 300-p.y)]; // offset to make most of node visible
    }
    
    [self buildSearchIndex];
        
    NSLog(@"node bounds are %f, %f -- %f, %f", nMinX, nMinY, nMaxX, nMaxY);
}

- (void)createLayers
{
    underwaterLayer=[[CCLayer alloc] init];
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/water_whitebkg.png") rect:CGRectMake(0, 0, 10*cx, 10*cy)];
    [s setPosition:ccp(-5*cx,-5*cy)];
    [s setAnchorPoint:ccp(0,0)];
    ccTexParams params={GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
    [s.texture setTexParameters:&params];
    [underwaterLayer addChild:s];
    
    [self addChild:underwaterLayer];
    
    //base map layer
    mapLayer=[[CCLayer alloc] init];
    if(contentService.resetPositionAfterTH)
        [mapLayer setPosition:contentService.lastMapLayerPosition];
    else
        [mapLayer setPosition:kStartMapPos];        

    [self addChild:mapLayer z:1];
    
    //setup render batch for nodes
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:BUNDLE_FULL_PATH(@"/images/jmap/jmapsm.plist")];
    nodeRenderBatch=[CCSpriteBatchNode batchNodeWithFile:BUNDLE_FULL_PATH(@"/images/jmap/jmapsm.png")];
    
    [mapLayer addChild:nodeRenderBatch z:2];

    //fore layer
    foreLayer=[[CCLayer alloc] init];
    [self addChild:foreLayer z:1];
    
    CCSprite *topsprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/HR_HeaderBar_JMAP.png")];
    [topsprite setPosition:ccp(cx, 2*cy-(65.0f/2))];
    [foreLayer addChild:topsprite];
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
    for (int i=0; i<[kcmNodes count]; i++) {
        ConceptNode *n=[kcmNodes objectAtIndex:i];
        
        //node position
        CGPoint nodepos=ccp((float)n.x * kNodeScale, (nMaxY-(float)n.y) * kNodeScale);

        id<CouchDerived, Configurable, Selectable, Transform> newnode;
        
        //create a node go
        if(n.mastery)
        {
            newnode=[[[SGJmapMasteryNode alloc] initWithGameWorld:gw andRenderBatch:nodeRenderBatch andPosition:nodepos] autorelease];
            
            newnode.HitProximity=100.0f;
            newnode.HitProximitySign=150.0f;
            newnode.UserVisibleString=[n.jtd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if(n.regions.count>0)
                ((SGJmapMasteryNode*)newnode).Region=[n.regions objectAtIndex:0];
            else
                ((SGJmapMasteryNode*)newnode).Region=@"";
            
            //create a cloud go here as well
            [self createCloudAt:newnode.Position];
        }
        else {
            newnode=[[[SGJmapNode alloc] initWithGameWorld:gw andRenderBatch:nodeRenderBatch andPosition:nodepos] autorelease];
            newnode.UserVisibleString=[n.utd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            //todo: for now, if there are pipelines on the node, set it complete
            if([usersService hasCompletedNodeId:n._id])
            {
                ((SGJmapNode*)newnode).EnabledAndComplete=YES;
            }
            
            
            newnode.HitProximity=40.0f;
            newnode.HitProximitySign=150.0f;
        }   
        
        newnode._id=n._id;
        
        [newnode setup];
    }
}

-(void)createCloudAt:(CGPoint)p
{
    CGPoint adj1=[BLMath ProjectMovementWithX:100 andY:50 forRotation:(arc4random() % 130)+110];
    CGPoint p1=[BLMath AddVector:p toVector:adj1];
    
    SGJmapCloud *c=[[SGJmapCloud alloc] initWithGameWorld:gw andRenderBatch:nodeRenderBatch andPosition:p1];
    c.particleRenderLayer=mapLayer;
    [c release];
    
    CGPoint adj2=[BLMath ProjectMovementWithX:100 andY:50 forRotation:(arc4random() % 130)+110];
    CGPoint p2=[BLMath AddVector:p toVector:adj2];
    
    SGJmapCloud *c1=[[SGJmapCloud alloc] initWithGameWorld:gw andRenderBatch:nodeRenderBatch andPosition:p2];
    c1.particleRenderLayer=mapLayer;
    [c1 release];
}

-(void)parseNodesForEndPoints
{
    //mastery>child relations
    NSArray *prereqs=[contentService relationMembersForName:@"Mastery"];
    for (NSArray *pair in prereqs) {
        SGJmapNode *leftgo=[self gameObjectForCouchId:[pair objectAtIndex:0]];
        SGJmapMasteryNode *rightgo=[self gameObjectForCouchId:[pair objectAtIndex:1]];
        
        if(leftgo && rightgo)
        {
            //add child to collection of children on mastery
            [rightgo.ChildNodes addObject:leftgo];
            
            //add ref to mastery on child
            leftgo.MasteryNode=rightgo;
        }
        else {
            NSLog(@"could not find both end points for %@ and %@", [pair objectAtIndex:0], [pair objectAtIndex:1]);
        }
    }
    
    //pre-req relations
    NSArray *prqs=[contentService relationMembersForName:@"Prerequisite"];
    for(NSArray *pair in prqs)
    {
        SGJmapNode *left=[self gameObjectForCouchId:[pair objectAtIndex:0]];
        SGJmapNode *right=[self gameObjectForCouchId:[pair objectAtIndex:1]];
        
        if (left && right)
        {
            //add left as pre-requisite of left
            [right.PrereqNodes addObject:left];
        }
        else {
            NSLog(@"could not find both pre-req end points for %@ and %@", [pair objectAtIndex:0], [pair objectAtIndex:1]);
        }
    }
    
    //establish completed state on mastery nodes; pre-req completion
    for(id go in [gw AllGameObjects])
    {
        if([go isKindOfClass:[SGJmapMasteryNode class]])
        {
            SGJmapMasteryNode *mgo=(SGJmapMasteryNode*)go;

            int count=0;
            int complete=1;
            for (SGJmapNode *n in mgo.ChildNodes) {
                count++;
                if(n.EnabledAndComplete)complete++;
            }
            
            if(mgo.ChildNodes.count==0)
            {
                mgo.EnabledAndComplete=NO;
                mgo.Disabled=YES;
            }
            else
            {
                mgo.CompleteCount=complete;
                mgo.CompletePercentage=(complete / (float)count) * 100.0f;
                mgo.EnabledAndComplete=(complete==count);
            }
        }
    }
    
    //second pass on mastery nodes to establish completion
    for(id go in [gw AllGameObjects])
    {
        if([go isKindOfClass:[SGJmapMasteryNode class]])
        {    
            SGJmapMasteryNode *mgo=(SGJmapMasteryNode*)go;
            
            int prqcount=0;
            int prqcomplete=0;
            
            for(SGJmapNode *n in mgo.ChildNodes)
            {
                for (SGJmapNode *prqn in n.PrereqNodes) {
                    prqcount++;
                    if(prqn.EnabledAndComplete) prqcomplete++;
                }
            }
            
            mgo.PrereqCount=prqcount;
            mgo.PrereqComplete=prqcomplete;
            
            if(mgo.PrereqCount>0)
            {
                mgo.PrereqPercentage=(prqcomplete / (float)prqcount) * 100.0f;
            }
            else if(mgo.ChildNodes.count>0)
            {
                mgo.PrereqPercentage=100;
            }
            else {
                mgo.PrereqPercentage=0;
            }

            if(mgo.PrereqPercentage>0 && mgo.PrereqPercentage < 100)
            {
                NSLog(@"prereq %d%% for %@", (int)mgo.PrereqPercentage, mgo.UserVisibleString);
            }
            
            //NSLog(@"mastery prq percentage %f for complete %d of %d", mgo.PrereqPercentage, mgo.PrereqComplete, mgo.PrereqCount);
        }
    }
    
    
    //mastery>mastery relations
    NSArray *ims=[contentService relationMembersForName:@"InterMastery"];
    for(NSArray *pair in ims) {
        SGJmapMasteryNode *leftgo=[self gameObjectForCouchId:[pair objectAtIndex:0]];
        SGJmapMasteryNode *rightgo=[self gameObjectForCouchId:[pair objectAtIndex:1]];
        
        if(leftgo && rightgo)
        {
            [leftgo.ConnectFromMasteryNodes addObject:rightgo];
            [rightgo.ConnectToMasteryNodes addObject:leftgo];
        }
        else {
            NSLog(@"could not find both mastery nodes for %@ and %@", [pair objectAtIndex:0], [pair objectAtIndex:1]);
        }
    }

}

-(void)buildSearchIndex
{
    if(searchNodes)[searchNodes release];
    searchNodes=[[NSMutableArray alloc] init];
    
    for(id go in [gw AllGameObjects])
    {
        if([go isKindOfClass:[SGJmapMasteryNode class]])
        {
            SGJmapMasteryNode *mgo=(SGJmapMasteryNode*)go;
    
            //build search test
            NSString *searchBuild=mgo.UserVisibleString;
            
            for(SGJmapNode *node in mgo.ChildNodes)
            {
                searchBuild=[NSString stringWithFormat:@"%@ %@", searchBuild, node.UserVisibleString];
            }
            
            mgo.searchMatchString=searchBuild;
            
            //add to source for list
            [searchNodes addObject:mgo];
        }
    }
    
    //authoring mode -- add nodes to direct index
    if(authorRenderEnabled)
    {
        for(id go in [gw AllGameObjects])
        {
            if([go isKindOfClass:[SGJmapNode class]])
            {
                SGJmapNode *ngo=(SGJmapNode*)go;
                ngo.searchMatchString=ngo.UserVisibleString;
                [searchNodes addObject:ngo];
            }
        }
    }
    
    //sort index
    [searchNodes sortUsingComparator:^NSComparisonResult(id<CouchDerived> a, id<CouchDerived> b){
        return [a.UserVisibleString compare:b.UserVisibleString];
    }];
}

-(void)createRegions
{
    NSArray *regions=[contentService allRegions];
    int rindex=0;
    
    for (NSString *r in regions) {
//        NSLog(@"region: %@", r);
        
        //create the region
        SGJmapRegion *rgo=[[SGJmapRegion alloc] initWithGameWorld:gw];
        rgo.RenderBatch=nodeRenderBatch;
        rgo.RegionNumber=rindex;
        rgo.Name=r;
        
        //find all mastery children
        
        //step over all nodes and compare region string -- this may need perf refactor long term
        for (id go in [gw AllGameObjects]) {
            if([go isKindOfClass:[SGJmapMasteryNode class]])
            {
                SGJmapMasteryNode *mgo=(SGJmapMasteryNode*)go;
                if([mgo.Region isEqualToString: r])
                {
                    //add this mastery node to the region
                    [rgo.MasteryNodes addObject:mgo];
                }
            }
        }
        
        [rgo release];
        rindex++;
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
    
    
    //underwater tracking
    if(setUnderwaterLastMapPos)
    {
        CGPoint posDiff=[BLMath SubtractVector:underwaterLastMapPos from:mapLayer.position];
        posDiff=[BLMath MultiplyVector:posDiff byScalar:0.2f];
        [underwaterLayer setPosition:[BLMath AddVector:posDiff toVector:underwaterLayer.position]];
    }
    
    underwaterLastMapPos=mapLayer.position;
    setUnderwaterLastMapPos=YES;
    
//    //scrolling
//    float friction=0.85f;
//    
//    if(!isDragging)
//    {
//        dragVel=[BLMath MultiplyVector:dragVel byScalar:friction];
//        if(dragVel.x<100.0f && dragVel.y<100.0f)
//            mapLayer.position=[BLMath AddVector:dragVel toVector:mapLayer.position];
//    }
//    else {
//        dragVel=[BLMath SubtractVector:dragLast from:mapLayer.position];
//        dragLast=mapLayer.position;
//    }
}

-(void) doUpdateProximity:(ccTime)delta
{
    //don't do proximity on general view
    if(!zoomedOut) [self evalProximityAcrossGW];
}

-(void) evalProximityAcrossGW
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
    for (int i=0; i<DRAW_DEPTH; i++)
    {
        for(id go in [gw AllGameObjects]) {
            if([go conformsToProtocol:@protocol(Drawing)])
                [((id<Drawing>)go) draw:i];
        }
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
    isDragging=YES;
    
    //drop any UI state
    [self resetUI];
    
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
    touchCount+=touches.count;
    
    if(ac.AuthoringMode && CGRectContainsPoint(debugButtonBounds, l))
    {
        if(authorRenderEnabled)[gw handleMessage:kSGdisableAuthorRender];
        else [gw handleMessage:kSGenableAuthorRender];
        authorRenderEnabled=!authorRenderEnabled;
        
        //re-build search index
        [self buildSearchIndex];
        [ac.searchList reloadData];
        [self searchBar:ac.searchBar textDidChange:ac.searchBar.text];
    }
    
    if(l.x<110 && l.y > (ly-55)) // log out button
    {
        [loggingService logEvent:BL_USER_LOGOUT withAdditionalData:nil];
        [usersService setCurrentUserToUserWithId:nil];
        
        [(AppController*)[[UIApplication sharedApplication] delegate] returnToLogin];
        return;
    }

    else {

        lastTouch=l;
        
        CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
     
        NSLog(@"touched at %@", NSStringFromCGPoint(lOnMap));
        
        if(!zoomedOut)
        {
            [self testForNodeTouchAt:lOnMap];
        }
        
    //    [daemon setTarget:l];
    //    [daemon setRestingPoint:l];
        
        //assume touch didn't start in the node map
        touchStartedInNodeMap=NO;

        if (juiState==kJuiStateNodeMap) {
                    
            touchStartedInNodeMap=YES;
        }
    }
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isDragging=NO;
    didJustChangeZoom=NO;
    
    touchCount=0;
}

-(void)testForNodeTouchAt:(CGPoint)lOnMap
{
    for (id go in [gw AllGameObjects]) {
        if([go conformsToProtocol:@protocol(Selectable)])
        {
            id<Selectable>sgo=go;
            if([((id<Selectable>)sgo).NodeSelectComponent trySelectionForPosition:lOnMap])
            {
                [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_node_pin_tap.wav")];;
                break;
            }
        }
    }
}

//- (void)testForNodeSliceTransitionStartWithTouchAt:(CGPoint)lOnMap
//{
//    //test for node hit and start transition
//    ConceptNode *n=[self nodeWithin:(kPropXNodeHitDist * lx) ofLocation:lOnMap];
//    if(n)
//    {
//        //[self createNodeSliceFrom:n];
//        NSLog(@"hit node %@", n._id);
//        
//    }
//}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
    if (touchCount==1 && !didJustChangeZoom) {
        
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
            //[[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_navigating_(panning_map).wav")];
            [mapLayer setPosition:newpos];

            lastTouch=l;
            
//            CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
            
//            [daemon setTarget:l];    
//            [daemon setRestingPoint:l];
        }
    }
    //pinch handling
    if([touches count]>1 && !didJustChangeZoom)
    {
        UITouch *t1=[[touches allObjects] objectAtIndex:0];
        UITouch *t2=[[touches allObjects] objectAtIndex:1];
        
        CGPoint t1a=[[CCDirector sharedDirector] convertToGL:[t1 previousLocationInView:t1.view]];
        CGPoint t1b=[[CCDirector sharedDirector] convertToGL:[t1 locationInView:t1.view]];
        CGPoint t2a=[[CCDirector sharedDirector] convertToGL:[t2 previousLocationInView:t2.view]];
        CGPoint t2b=[[CCDirector sharedDirector] convertToGL:[t2 locationInView:t2.view]];
        
        float da=[BLMath DistanceBetween:t1a and:t2a];
        float db=[BLMath DistanceBetween:t1b and:t2b];
        
        float scaleChange=db-da;
        
        if(scaleChange<-2 && !zoomedOut)
        {
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_zooming_map.wav")];
            [self zoomToRegionView];
            didJustChangeZoom=YES;
        }
        else if(scaleChange>2 && zoomedOut)
        {
            [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_zooming_map.wav")];
            CGPoint aPos=[BLMath AddVector:t1b toVector:[BLMath MultiplyVector:[BLMath SubtractVector:t1b from:t1a] byScalar:0.5f]];
            
            [self zoomToCityViewAtPoint:aPos];
            didJustChangeZoom=YES;
        }
    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchCount-=touches.count;
    if(touchCount<0)touchCount=0;
    
    if(touchCount==0)
    {
        didJustChangeZoom=NO;
        isDragging=NO;
    }
    
}

#pragma mark - map views and zooming

-(void)zoomToCityViewAtPoint:(CGPoint)gesturePoint
{
    zoomedOut=NO;
    //[backarrow setVisible:YES];
    [backarrow setFlipX:NO];
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.5f scale:1.0f] rate:2.0f]];
    
    CGPoint gestureLocalOffset=[BLMath SubtractVector:gesturePoint from:ccp(cx,cy)];
    CGPoint gestureDestOffset=[BLMath MultiplyVector:gestureLocalOffset byScalar:REGION_ZOOM_LEVEL];
    CGPoint gestureOffset=[BLMath AddVector:gestureLocalOffset toVector:gestureDestOffset];
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:[BLMath MultiplyVector:[BLMath AddVector:mapLayer.position toVector:gestureOffset] byScalar:1.0f/REGION_ZOOM_LEVEL]] rate:2.0f]];
    
    [gw handleMessage:kSGzoomIn];
    
    //needs immediate proximity check
    [self evalProximityAcrossGW];
}

-(void)zoomToRegionView
{
    zoomedOut=YES;
//    [backarrow setVisible:NO];
    [backarrow setFlipX:YES];
    
    [mapLayer setAnchorPoint:ccp(0.5,0.5)];
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.5f scale:REGION_ZOOM_LEVEL] rate:2.0f]];
    
    NSLog(@"pos at region view %@", NSStringFromCGPoint(mapLayer.position));
    
    //mapLayer.position=[BLMath MultiplyVector:mapLayer.position byScalar:REGION_ZOOM_LEVEL];
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:[BLMath MultiplyVector:mapLayer.position byScalar:REGION_ZOOM_LEVEL]] rate:2.0f]];
    
    //[mapLayer setPosition:ccp(-(nMaxX-nMinX) / 2.0f, -(nMaxY-nMinY) / 2.0f)];
//    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:ccp(-257, 212.5)] rate:2.0f]];
    
    [gw handleMessage:kSGzoomOut];
}

#pragma mark - debug

-(void)buildDebugMenu
{
    CCMenuItemLabel *i1=[CCMenuItemFont itemWithString:@"relocate to home" target:self selector:@selector(debugRelocate:)];
    CCMenuItemLabel *i2=[CCMenuItemFont itemWithString:@"rebuild node tris" target:self selector:@selector(debugRebuildNodeTris:)];
    
    CCMenuItemLabel *i3=[CCMenuItemFont itemWithString:@"switch map view" target:self selector:@selector(debugSwitchZoom:)];
    
    debugMenu =[CCMenu menuWithItems:i1, i2, i3, nil];
    
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

-(void)debugSwitchZoom:(id)sender
{
    if(zoomedOut)[self zoomToCityViewAtPoint:ccp(cx,cy)];
    else [self zoomToRegionView];
}

#pragma mark - ui setup 

-(void)setupUI
{
    ac.searchBar=[[UISearchBar alloc] initWithFrame:CGRectMake(750, 0, 266, 60)];
    ac.searchBar.barStyle=UIBarStyleBlackTranslucent;
    [[[ac.searchBar subviews] objectAtIndex:0] removeFromSuperview];
    ac.searchBar.backgroundColor=[UIColor clearColor];
    
    ac.searchBar.delegate=self;
    
    [[CCDirector sharedDirector].view addSubview:ac.searchBar];
    
    
    ac.searchList=[[UITableView alloc] initWithFrame:CGRectMake(683, 62, 341, 354)];
    ac.searchList.delegate=self;
    ac.searchList.dataSource=self;
}

-(void)resetUI
{
    [ac.searchBar resignFirstResponder];
}

#pragma mark - UISearchBarDelegate

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [[CCDirector sharedDirector].view addSubview:ac.searchList];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [ac.searchList removeFromSuperview];
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    if(text.length == 0)
    {
        isFiltered = NO;
    }
    else
    {
        isFiltered = YES;
        filteredNodes = [[NSMutableArray alloc] init];
        
        for (id<CouchDerived, Searchable> node in searchNodes)
        {
            NSRange searchRange = [node.searchMatchString rangeOfString:text options:NSCaseInsensitiveSearch];
            NSRange idRange = [node._id rangeOfString:text options:NSCaseInsensitiveSearch];
            if(searchRange.location != NSNotFound || idRange.location != NSNotFound)
            {
                [filteredNodes addObject:node];
            }
        }
    }
    
    [ac.searchList reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected %@", [searchNodes objectAtIndex:indexPath.row]);
    
    id<CouchDerived, Transform>node;
    if(isFiltered)node=[filteredNodes objectAtIndex:indexPath.row];
    else node=[searchNodes objectAtIndex:indexPath.row];

    CGPoint moveto=ccp(300-node.Position.x, 600-node.Position.y);
    //if(zoomedOut)moveto=ccp(300-node.Position.x*REGION_ZOOM_LEVEL, 600-node.Position.y*REGION_ZOOM_LEVEL);
    
    if(zoomedOut)moveto=[BLMath MultiplyVector:moveto byScalar:REGION_ZOOM_LEVEL];
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.75f position:moveto] rate:2.0f]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:
(NSIndexPath *)indexPath
{
    static NSString *reuseId=@"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId] autorelease];
    }
    
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
    cell.textLabel.textColor=[UIColor blackColor];

    id<CouchDerived> go;
    if(isFiltered)go=[filteredNodes objectAtIndex:indexPath.row];
    else go=[searchNodes objectAtIndex:indexPath.row];
    
    cell.textLabel.text=go.UserVisibleString;
    
    if(authorRenderEnabled)
    {
        if([(NSObject*)go isKindOfClass:[SGJmapNode class]])
        {
            cell.textLabel.textColor=[UIColor grayColor];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<CouchDerived> go;
    if(isFiltered)go=[filteredNodes objectAtIndex:indexPath.row];
    else go=[searchNodes objectAtIndex:indexPath.row];
    
    NSString *cellText = go.UserVisibleString;
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
    CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    
    return labelSize.height + 20;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(isFiltered) return filteredNodes.count;
    else return searchNodes.count;
}

#pragma mark - tear down

-(void)dealloc
{
    [mapLayer release];
    [foreLayer release];
    [kcmNodes release];
    [gw release];
    
    [searchNodes release];
    
    [super dealloc];
}

@end
