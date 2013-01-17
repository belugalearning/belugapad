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
#import "SGJmapComingSoonNode.h"
#import "SGJmapPaperPlane.h"

#import "JSONKit.h"
#import "TestFlight.h"

#import "UserNodeState.h"
#import "TouchXML.h"


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
        self.touchEnabled=YES;
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
        
        [self setupContentRegions];
        
        [self setupUI];
        
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        [self schedule:@selector(doUpdateProximity:) interval:15.0f / 60.0f];
        
        [[SimpleAudioEngine sharedEngine]playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/go/sfx_launch_general_background_score.mp3") loop:YES];
                        
        //[[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/mood.mp3") loop:YES];
        
        [TestFlight passCheckpoint:@"STARTED_JMAP"];
        
    }
    
    return self;
}

#pragma mark - transitions

-(void)setUtdLabel:(NSString *)toThisString
{
    if(!utdHeaderLabel){
        utdHeaderLabel=[CCLabelTTF labelWithString:@""
                                          fontName:CHANGO
                                          fontSize:14.0f
                                        dimensions:CGSizeMake(575, 42) hAlignment:UITextAlignmentCenter vAlignment:UITextAlignmentCenter];
        [utdHeaderLabel setPosition:ccp(442,742)];
        [foreLayer addChild:utdHeaderLabel z:10];
    }
    
    int maxStringSize=100;
    
    if([toThisString length]>maxStringSize)
    {
        NSString *truncString=[toThisString substringToIndex: MIN(maxStringSize, [toThisString length])];
        toThisString=[NSString stringWithFormat:@"%@...", truncString];
    }

    [utdHeaderLabel setString:toThisString];

}

-(void)startTransitionToToolHostWithPos:(CGPoint)pos
{
    
    [self gotoToolHost:0];
}

-(void)gotoToolHost:(ccTime)delta
{
    //[[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
    
    [TestFlight passCheckpoint:@"PROCEEDING_TO_TOOLHOST_FROM_JMAP"];
    [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_enter_question.wav")];
    contentService.resetPositionAfterTH=YES;
    contentService.lastMapLayerPosition=mapLayer.position;
    
//    [ac.searchBar removeFromSuperview];
//    ac.searchBar=nil;
    
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
    
    gw.Blackboard.jmapInstance=self;
    
//    gw.Blackboard.debugDrawNode=[[[CCDrawNode alloc] init] autorelease];
    
    //used for debug draw of map positioning
//    [mapLayer addChild:gw.Blackboard.debugDrawNode z:99];
    
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
 
    [self getUserData];
    
    [self setupGw];
    
    [self parseIslandData];
    
    kcmNodes=[NSMutableArray arrayWithArray:[contentService allConceptNodes]];
    [kcmNodes retain];
    
    [self parseKcmForBounds];
    
    [self createNodesInGameWorld];
    
    [self parseNodesForEndPoints];
    
    //get nodes to calculate their offset from parent / mastery
    [gw handleMessage:kSGretainOffsetPosition];
    
    //force layout mastery
    //for(int i=0; i<50; i++)
    //{
    //    [gw handleMessage:kSGforceLayout];
    //}
    
    //re-set node positions
    [gw handleMessage:kSGresetPositionUsingOffset];
    
    [self createRegions];
    
    //setup rendering -- needs all node connections built
    [gw handleMessage:kSGreadyRender];

    // position map so that bottom-most included node in view, bottom-left
    if (!mapPositionSet)
    {
//        CGPoint p = ccp(NSIntegerMax, NSIntegerMax);
//        for (id go in [gw AllGameObjects]) {
//            if([go isKindOfClass:[SGJmapMasteryNode class]])
//            {
//                CGPoint mnpos = ((SGJmapMasteryNode*)go).Position;
//                if (mnpos.y < p.y || (mnpos.y == p.y && mnpos.x < p.x)) p = mnpos;
//            }
//        }
//        if (p.y != NSIntegerMax) [mapLayer setPosition:ccp(512-p.x, 300-p.y)]; // offset to make most of node visible
        
        CGPoint np=resumeAtNode.Position;
        [mapLayer setPosition:ccp(512-np.x, 384-np.y)];
    }
    
    [self buildSearchIndex];
    
    //any final node-based visual setup
    [gw handleMessage:kSGsetVisualStateAfterBuildUp];
 
    //after we've finished building everything, set the last jmap viewed user state on the app delegate
    ac.lastJmapViewUState=udata;
    
    NSLog(@"node bounds are %f, %f -- %f, %f", nMinX, nMinY, nMaxX, nMaxY);
    
    if(playTransitionAudio)
       [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_map_progress_island_state_change.wav")];
    playTransitionAudio=NO;
    
//    SGJmapPaperPlane *plane=[[SGJmapPaperPlane alloc]initWithGameWorld:gw andRenderLayer:mapLayer andPosition:ccp(0,0) andDestination:ccp(100,100)];
//    [plane setup];
}

-(void)setupContentRegions
{
    CCSprite *algebra=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/Region_Algebra.png")];
    [algebra setPosition:ccp(5285,3585)];
    [mapLayer addChild:algebra];
    
    CCSprite *shape=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/Region_Geometry.png")];
    [shape setPosition:ccp(-512,3585)];
    [mapLayer addChild:shape];
}

-(void)getUserData
{
    udata=[usersService currentUserAllNodesState];
}

- (void)createLayers
{
    underwaterLayer=[[CCLayer alloc] init];
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/jmap/water_whitebkg.png") rect:CGRectMake(0, 0, 12*cx, 12*cy)];
    [s setPosition:ccp(-6*cx,-6*cy)];
    [s setAnchorPoint:ccp(0,0)];
    ccTexParams params={GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
    [s.texture setTexParameters:&params];
    [underwaterLayer addChild:s];
    
    [self addChild:underwaterLayer];
    
    //base map layer
    mapLayer=[[CCLayer alloc] init];
//    if(contentService.resetPositionAfterTH)
//        [mapLayer setPosition:contentService.lastMapLayerPosition];
//    else
//        [mapLayer setPosition:kStartMapPos];        

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
        
        if([n._id isEqualToString:ac.lastViewedNodeId])
        {
            lastPlayedNode=newnode;
        }
        
        //create a node go
        
        if(n.comingSoon)
        {
            SGJmapComingSoonNode *comingSoonNode=[[[SGJmapComingSoonNode alloc] initWithGameWorld:gw andRenderLayer:mapLayer andPosition:nodepos]autorelease];
            
            comingSoonNode.UserVisibleString=[n.jtd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            newnode=(id<Transform,CouchDerived,Configurable,Selectable>)comingSoonNode;
            
        }
        else if(n.mastery)
        {
            SGJmapMasteryNode *mnode=[[[SGJmapMasteryNode alloc] initWithGameWorld:gw andRenderBatch:nodeRenderBatch andPosition:nodepos] autorelease];
            
            newnode=(id<CouchDerived, Configurable, Selectable, Transform>)mnode;
            
            mnode.renderBase=n.renderBase;
            mnode.renderLayout=n.renderLayout;
            
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
            
            //get the node state data from the userservice
            SGJmapNode *newnodeC=(SGJmapNode*)newnode;
            
            newnodeC.ustate=[udata objectForKey:n._id];
            if(ac.lastJmapViewUState) newnodeC.lastustate=[ac.lastJmapViewUState objectForKey:n._id];
            
            //mock old enabledAndComplete by directly accessing the lastPlayed of the node
            newnodeC.EnabledAndComplete=(newnodeC.ustate.lastCompleted > 0);
            newnodeC.Attempted=(newnodeC.ustate.lastPlayed > 0);
            newnodeC.DateLastPlayed=(newnodeC.ustate.lastPlayed);
            
            if(newnodeC.EnabledAndComplete && (newnodeC.lastustate!=nil && newnodeC.lastustate.lastCompleted<=0))
            {
                newnodeC.FreshlyCompleted=YES;
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
    resumeAtMaxDate=[NSDate dateWithTimeIntervalSince1970:0];
    
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
//                NSLog(@"prereq %d%% for %@", (int)mgo.PrereqPercentage, mgo.UserVisibleString);
            }
            

            //calculate old prqc
            int pprqcomplete=0;
            for(SGJmapNode *n in mgo.ChildNodes)
            {
                for (SGJmapNode *prqn in n.PrereqNodes) {
                    if(prqn.EnabledAndComplete && !prqn.FreshlyCompleted) {                        
                            pprqcomplete++;
                        }
                    else if(prqn.EnabledAndComplete && prqn.FreshlyCompleted)
                    {
                        mgo.FreshlyCompleted=YES;
                        playTransitionAudio=YES;
                        
                        //that means that node's island has a effective link to this one, add it with link data
                        if(![prqn.MasteryNode.EffectedPathDestinationNodes containsObject:mgo])
                            [prqn.MasteryNode.EffectedPathDestinationNodes addObject:mgo];
                    }
                }
            }
            
            if(mgo.PrereqCount>0)
            {
                mgo.PreviousPreReqPercentage =(pprqcomplete / (float)prqcount) * 100.0f;
            }
            else if(mgo.ChildNodes.count>0)
            {
                mgo.PreviousPreReqPercentage=100;
            }
            else {
                mgo.PreviousPreReqPercentage=0;
            }
            
            
            //NSLog(@"mastery prq percentage %f for complete %d of %d", mgo.PrereqPercentage, mgo.PrereqComplete, mgo.PrereqCount);
        }
        else if([go isKindOfClass:[SGJmapNode class]])
        {
            SGJmapNode *n=(SGJmapNode*)go;
            if (n.ustate.lastPlayed)
            {
                if([resumeAtMaxDate compare:n.ustate.lastPlayed]==NSOrderedAscending)
                {
                    resumeAtMaxDate=n.ustate.lastPlayed;
                    resumeAtNode=n;
                }
            }
            else if([n._id isEqualToString:@"5608a59d6797796ce9e11484fd180214"])
            {
                //if no other node set, we'll use this one -- so set an aritifically low date
                if(!resumeAtMaxDate)
                {
                    resumeAtMaxDate=[NSDate dateWithTimeIntervalSince1970:0];
                    resumeAtNode=n;
                }
            }
        }
    }
    
    
    //mastery>mastery relations
    NSArray *ims=[contentService relationMembersForName:@"InterMastery"];
    for(NSArray *pair in ims) {
        SGJmapMasteryNode *leftgo=[self gameObjectForCouchId:[pair objectAtIndex:0]];
        SGJmapMasteryNode *rightgo=[self gameObjectForCouchId:[pair objectAtIndex:1]];
        
        BOOL connectNodes=YES;
        
        if(![leftgo isKindOfClass:[SGJmapMasteryNode class]]||![rightgo isKindOfClass:[SGJmapMasteryNode class]])connectNodes=NO;
        
        if(leftgo && rightgo && connectNodes)
        {
            [leftgo.ConnectFromMasteryNodes addObject:rightgo];
            [rightgo.ConnectToMasteryNodes addObject:leftgo];
        }
        else {
            //NSLog(@"could not find both mastery nodes for %@ and %@", [pair objectAtIndex:0], [pair objectAtIndex:1]);
        }
    }

    //check if last mastery has been completed, and
    // - bounce nodes on other islands
    // - fly planes
    //always
    // - centre map on that mastery
    // - bounce that node
    
    if(lastPlayedNode)
    {
        NSLog(@"identified last played mastery node");
        
        if([lastPlayedNode isKindOfClass:[SGJmapMasteryNode class]])
            lastPlayedMasteryNode=(SGJmapMasteryNode*)lastPlayedNode;
        else
            lastPlayedMasteryNode=((SGJmapNode*)lastPlayedNode).MasteryNode;
        
        BOOL allComplete=YES;
        NSLog(@"assuming all children complete... testing");
        for(SGJmapNode *n in lastPlayedMasteryNode.ChildNodes)
        {
            if(n.ustate.lastScore==0)
            {
                NSLog(@"children not complete, reverting assumption");
                allComplete=NO;
                break;
            }
        }
        
        if(allComplete)
        {
            NSLog(@"bouncing all other applicable nodes / islands; enabling planes");
            //bounce all other mastery node
            for(id go in [gw AllGameObjects])
            {
                if([go isKindOfClass:[SGJmapMasteryNode class]])
                {
                    SGJmapMasteryNode *mgo=(SGJmapMasteryNode*)go;
                    mgo.shouldBouncePins=YES;
                }
            }
            
            //enable paper planes on this node/island
            lastPlayedMasteryNode.shouldShowPaperPlanes=YES;
        }
        
        //always
        lastPlayedMasteryNode.shouldBouncePins=YES;
        
        //centre on this node
        CGPoint p = lastPlayedMasteryNode.Position;
        [mapLayer setPosition:ccp(512-p.x, 300-p.y)]; // offset to make most of node visible
        
        mapPositionSet=YES;
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

#pragma mark - parse island data svg

-(void)parseIslandData
{
    gw.Blackboard.islandData=[[[NSMutableArray alloc] init] autorelease];
    
    NSString *XMLPath=BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/jmap/data/ifeatures.svg"]));
	
	//use that file to populate an NSData object
	NSData *XMLData=[NSData dataWithContentsOfFile:XMLPath];
	
	//get TouchXML doc
	CXMLDocument *doc=[[CXMLDocument alloc] initWithData:XMLData options:0 error:nil];
    
	//setup a namespace mapping for the svg and xlink namespaces
    NSDictionary *nsMappings=@{@"svg":@"http://www.w3.org/2000/svg", @"xlink":@"http://www.w3.org/1999/xlink"};
    
    
    //step over each group that includes a data-features and create a dictionary for it
    NSArray *nodes=[doc nodesForXPath:@"//svg:g[starts-with(@id, 'data-features')]" namespaceMappings:nsMappings error:nil];
    
    int didx=0;
    
    for (CXMLElement *node in nodes) {
        
        //this is a node
        //NSLog(@"parsing island group %@", [[node attributeForName:@"id"] stringValue]);
        
        //create dict for this island
        NSMutableDictionary *idata=[[[NSMutableDictionary alloc] init] autorelease];
        [gw.Blackboard.islandData addObject:idata];
        
        //create the arrays of node and artefact dicts, as well as the master index dict
        NSMutableArray *featureindex=[[[NSMutableArray alloc] init] autorelease];
        [idata setValue:featureindex forKey:@"FEATURE_INDEX"];
        NSMutableArray *artefacts=[[[NSMutableArray alloc] init] autorelease];
        [idata setValue:artefacts forKey:@"ARTEFACTS"];
        NSMutableArray *nodes=[[[NSMutableArray alloc] init] autorelease];
        [idata setValue:nodes forKey:@"NODES"];
        NSMutableArray *features=[[[NSMutableArray alloc] init] autorelease];
        [idata setValue:features forKey:@"FEATURES"];
        
        //step over all of the images in the group to infer types
        NSArray *dimages=[node nodesForXPath:@"svg:image" namespaceMappings:nsMappings error:nil];
        
        //NSLog(@"dimages in data found %d is %d", didx, dimages.count);
        
        for(CXMLElement *dimg in dimages)
        {
            NSString *href=[[dimg attributeForName:@"xlink:href"] stringValue];
            if([href rangeOfString:@"Crystal_Placeholder"].location!=NSNotFound)
            {
                NSDictionary *cryd=@{@"POS": [self getBoxedPosFromTransformString:[[dimg attributeForName:@"transform"] stringValue]]};
                [artefacts addObject:cryd];
                [featureindex addObject:cryd];
                
            }
            else if([href rangeOfString:@"Feature_Stage"].location!=NSNotFound)
            {
                int size=[[[href substringFromIndex:19] substringToIndex:1] intValue];
                int variant=[[[href substringFromIndex:21] substringToIndex:1] intValue];
                
                NSDictionary *fd=@{@"POS": [self getBoxedPosFromTransformString:[[dimg attributeForName:@"transform"] stringValue]],
                                    @"SIZE": @(size),
                                    @"VARIANT": @(variant)};
                
                [features addObject:fd];
                [featureindex addObject:fd];
                
            }
            else if([href rangeOfString:@"Node_Placeholder"].location!=NSNotFound)
            {
                NSDictionary *noded=@{@"POS": [self getBoxedPosFromTransformString:[[dimg attributeForName:@"transform"] stringValue]],
                                        @"FLIPPED": [self getBoxedIsFlippedFromTransformString:[[dimg attributeForName:@"transform"] stringValue]]};
                
                [nodes addObject:noded];
                [featureindex addObject:noded];
                
            }
            else if([href rangeOfString:@"Mastery_Placeholder"].location!=NSNotFound)
            {
                NSDictionary *masd=@{@"POS": [self getBoxedPosFromTransformString:[[dimg attributeForName:@"transform"] stringValue]],
                @"FLIPPED": [self getBoxedIsFlippedFromTransformString:[[dimg attributeForName:@"transform"] stringValue]]};
                
                [featureindex addObject:masd];
                [idata setValue:masd forKey:@"MASTERY"];
                
            }
        }
        
        didx++;
    }
    
}

-(NSValue*)getBoxedPosFromTransformString:(NSString*)t
{
    
    NSArray *ps=[t componentsSeparatedByString:@" "];
    NSString *sx=[ps objectAtIndex:4];
    NSString *sy=[ps objectAtIndex:5];
    sy=[sy stringByReplacingOccurrencesOfString:@")" withString:@""];

    float fx=[sx floatValue];
    float fy=[sy floatValue];
    fy=768.0f-fy;

    //NSLog(@"boxing %@ to %f, %f", t, fx, fy);
    
    return [NSValue valueWithCGPoint:CGPointMake(fx, fy)];
}

-(NSNumber*)getBoxedIsFlippedFromTransformString:(NSString*)t
{
    if(t.length==0)return [NSNumber numberWithBool:NO];
    
    NSArray *ps=[t componentsSeparatedByString:@" "];
    NSString *sx=[ps objectAtIndex:0];
    sx=[sx stringByReplacingOccurrencesOfString:@"matrix(" withString:@""];

    int set=0;
    if([sx isEqualToString:@"-1"])
    {
     set=-1;
        
    }
    
    NSNumber *res=[NSNumber numberWithBool:(set<0)];

    return res;
}



#pragma mark - drawing and sprite creation

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
    
    //udpdate tap timer
    lastTapTime+=delta;
    
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

-(BOOL) isPointInView:(CGPoint)testPoint
{
    if(zoomedOut)return NO;
    
    return CGRectContainsPoint(CGRectMake(-mapLayer.position.x, -mapLayer.position.y, 1024, 768), testPoint);
}


#pragma mark touch handling



-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    isDragging=YES;
    
    //drop any UI state
    [self resetUI];
    
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    
    if (![[touch view] isKindOfClass:[CCGLView class]])
    {
        return;
    }
    
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
        
        ac.lastJmapViewUState=nil;
        ac.lastViewedNodeId=nil;
        contentService.lastMapLayerPosition=CGPointZero;
        [ac returnToLogin];
        
        return;
    }

    else {

        lastTouch=l;
        
        CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
     
        NSLog(@"touched at %@", NSStringFromCGPoint(lOnMap));
        
        if(!zoomedOut)
        {
            [self testForNodeTouchAt:lOnMap];
            [self testForPlaneTouchAt:lOnMap];
        }
        else if(touchCount==1)
        {
            //look for double tap
            if(lastTapTime<0.5f)
            {
                //zoom to tapped point
                [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_zooming_map.wav")];
                [self zoomToCityViewAtPoint:l];
                didJustChangeZoom=YES;
            }
            
            lastTap=l;
            lastTapTime=0;
        }
        
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
    if(lastSelectedNode && [((id<Selectable>)lastSelectedNode).NodeSelectComponent trySelectionForPosition:lOnMap])
    {
        return;
    }
    else
    {
        
        id selected=nil;
        float bestDistance=0;
        BOOL first=YES;
        
        for (id go in [gw AllGameObjects]) {
            if([go conformsToProtocol:@protocol(Selectable)] && [go conformsToProtocol:@protocol(Transform)])
            {
                id<Transform>tgo=go;
                float thisDistance=[BLMath DistanceBetween:lOnMap and:tgo.Position];
                
                if((first||thisDistance<bestDistance) && thisDistance<40.0f)
                {
                    first=NO;
                    bestDistance=thisDistance;
                    selected=tgo;
                    lastSelectedNode=selected;
                }
                
    //            id<Selectable>sgo=go;
    //            if([((id<Selectable>)sgo).NodeSelectComponent trySelectionForPosition:lOnMap])
    //            {
    //                selected=sgo;
    //                [[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_node_pin_tap.wav")];
    //                break;
    //            }
            }
            
        }
        
        if(selected)
        {
            [loggingService logEvent:BL_JS_PIN_SELECT withAdditionalData:nil];
            [((id<Selectable>)selected).NodeSelectComponent trySelectionForPosition:lOnMap];
        }
        else
            [self setUtdLabel:@""];

        
        for (id go in [gw AllGameObjects]) {
            if([go conformsToProtocol:@protocol(Selectable)])
            {
                id<Selectable>sgo=go;
                if(selected!=sgo)
                {
                    [((id<Selectable>)sgo).NodeSelectComponent removeSign];
                }
            }
            
        }
    }
}

-(void)testForPlaneTouchAt:(CGPoint)lOnMap
{
    for (id go in [gw AllGameObjects]) {
        
        if([go isKindOfClass:[SGJmapPaperPlane class]])
        {
            SGJmapPaperPlane *thisPlane=(SGJmapPaperPlane*)go;
            
            NSValue *ret=[thisPlane checkTouchOnMeAt:lOnMap];
            if(ret)
            {
                CGPoint dest=[ret CGPointValue];
                
                //pan map
//                CGPoint moveto=ccp(300-dest.x, 600-dest.y);
                
                if(zoomedOut)dest=[BLMath MultiplyVector:dest byScalar:REGION_ZOOM_LEVEL];
                
                [mapLayer runAction:[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:2.5f position:dest] rate:2.0f]];

             
                //stop looking
                break;
            }
        }
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
    if (touchCount==1 && !didJustChangeZoom) {
        
        if(touchStartedInNodeMap)
        {
            CGPoint newpos=[BLMath AddVector:mapLayer.position toVector:[BLMath SubtractVector:lastTouch from:l]];
            
            
//            //restrict movement generally
            
            
            if(zoomedOut)
            {
                if (newpos.x > -282) newpos.x=-282;
                if (newpos.y < -199) newpos.y=-199;
                if (newpos.y > 560) newpos.y=560;
                if (newpos.x < -282) newpos.x=-282;
            }
            else
            {
                if (newpos.x > 1022) newpos.x=1022;
                if (newpos.y < -3200) newpos.y=-3200;
                if (newpos.y > 4200) newpos.y=4200;
                if (newpos.x < -4772) newpos.x=-4772;
            }
            
            //[[SimpleAudioEngine sharedEngine] playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_navigating_(panning_map).wav")];
            [mapLayer setPosition:newpos];

            lastTouch=l;
            
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
            CGPoint aPos=[BLMath AddVector:t1a toVector:[BLMath MultiplyVector:[BLMath SubtractVector:t1b from:t1a] byScalar:0.5f]];
            
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
    [loggingService logEvent:BL_JS_ZOOM_IN withAdditionalData:nil];
    
    zoomedOut=NO;
    //[backarrow setVisible:YES];
    [backarrow setFlipX:NO];
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.5f scale:1.0f] rate:2.0f]];
    
    CGPoint gestureLocalOffset=[BLMath SubtractVector:gesturePoint from:ccp(cx,cy)];
    CGPoint gestureDestOffset=[BLMath MultiplyVector:gestureLocalOffset byScalar:REGION_ZOOM_LEVEL];
    CGPoint gestureOffset=[BLMath AddVector:gestureLocalOffset toVector:gestureDestOffset];
    
    CGPoint newpos=[BLMath MultiplyVector:[BLMath AddVector:mapLayer.position toVector:gestureOffset] byScalar:1.0f/REGION_ZOOM_LEVEL];
    
    if(newpos.x<-4772)newpos=ccp(-4772, newpos.y);
    if(newpos.x>1022)newpos=ccp(1022, newpos.y);
    if(newpos.y<-3200)newpos=ccp(newpos.x, -3200);
    
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:newpos] rate:2.0f]];
    
    [gw handleMessage:kSGzoomIn];
    
    //needs immediate proximity check
    [self evalProximityAcrossGW];
}

-(void)zoomToRegionView
{
    [loggingService logEvent:BL_JS_ZOOM_OUT withAdditionalData:nil];
    
    zoomedOut=YES;
//    [backarrow setVisible:NO];
    [backarrow setFlipX:YES];
    
    [mapLayer setAnchorPoint:ccp(0.5,0.5)];
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.5f scale:REGION_ZOOM_LEVEL] rate:2.0f]];
    
    NSLog(@"pos at region view %@", NSStringFromCGPoint(mapLayer.position));
    
    //mapLayer.position=[BLMath MultiplyVector:mapLayer.position byScalar:REGION_ZOOM_LEVEL];
    
    CGPoint newpos=[BLMath MultiplyVector:mapLayer.position byScalar:REGION_ZOOM_LEVEL];
    newpos=ccp(-282, newpos.y);
    if(newpos.y<-199)newpos=ccp(newpos.x, -199);
    
    [mapLayer runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.5f position:newpos] rate:2.0f]];
    
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
    ac.searchBar=[[[UISearchBar alloc] initWithFrame:CGRectMake(748, -2, 266, 58)] autorelease];
    ac.searchBar.barStyle=UIBarStyleBlackTranslucent;
    [[[ac.searchBar subviews] objectAtIndex:0] removeFromSuperview];
    ac.searchBar.backgroundColor=[UIColor clearColor];
    
    ac.searchBar.delegate=self;
    
    [[CCDirector sharedDirector].view addSubview:ac.searchBar];
    
    
    ac.searchList=[[[UITableView alloc] initWithFrame:CGRectMake(683, 56, 341, 360)] autorelease];
    ac.searchList.delegate=self;
    ac.searchList.dataSource=self;
    
    ac.searchList.backgroundColor=[UIColor colorWithRed:72.0f/255.0f green:76.0f/255.0f blue:77.0f/255.0f alpha:1];
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
//    [ac speakString:searchBar.text];
    
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
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_login_transition.wav")];
    
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
    
    cell.backgroundColor=[UIColor clearColor];
    
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
    cell.textLabel.textColor=[UIColor whiteColor];

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
