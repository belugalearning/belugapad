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

#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchModelFactory.h>

static float kNodeScale=0.5f;
//static CGPoint kStartMapPos={-3576, -2557};
static CGPoint kStartMapPos={-611, 3713};
static float kPropXNodeDrawDist=1.25f;
static float kPropXNodeHitDist=0.065f;

static float kNodeSliceStartScale=0.08f;
static CGPoint kNodeSliceOrigin={600, 384};
static float kNodeSliceRadius=350.0f;
static float kNodeSliceHoldTime=1.0f;
static CGPoint kPinOffset={-118, -162.5f};
static float kPinTapRadius=80.0f;

static float kLightInDelay=0.4f;
static float kLightInTime=0.5f;
static float kLightInScaleMax=10.0f;

static int kNodeMax=50;

typedef enum {
    kJuiStateNodeMap,
    kJuiStateNodeSliceTransition,
    kJuiStateNodeSlice
} JuiState;

@interface JourneyScene()
{
    @private
    ContentService *contentService;

    NSArray *kcmNodes;
    NSDictionary *kcmIdIndex;
    NSMutableArray *nodeSprites;
    NSMutableArray *dotSprites;
    NSMutableArray *visibleNodes;
        
    NSArray *prereqRelations;
    
    NSMutableArray *nodeSliceNodes;
    ConceptNode *currentNodeSliceNode;
    BOOL currentNodeSliceHasProblems;
    float nodeSliceTransitionHold;
    CGPoint mapPosAtNodeSliceTransitionComplete;
    
    JuiState juiState;
    
    float nMinX, nMinY, nMaxX, nMaxY;
    float scale;
    
    BOOL touchStartedInNodeMap;
    
    CCRenderTexture *darknessLayer;
    NSMutableArray *lightSprites;
    CCSprite *zubiLight;
    CCSprite *nodeSliceLight;
    
    UsersService *usersService;
    
    float deltacum;
    
}

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
        
        [self setupMap];
        
        //create nodes near camera
        [self createNodeSpritesNearCentre];
        
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        [self schedule:@selector(doUpdateCreateNodes:) interval:1.0f / 4.0f];
        
        //daemon=[[Daemon alloc] initWithLayer:mapLayer andRestingPostion:[mapLayer convertToNodeSpace:ccp(cx, cy)] andLy:ly];
        daemon=[[Daemon alloc] initWithLayer:foreLayer andRestingPostion:ccp(cx, cy) andLy:ly];
        [daemon setMode:kDaemonModeFollowing];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/mood.mp3") loop:YES];
    }
    
    return self;
}

#pragma mark - setup and parse



-(void) setupMap
{
    [self createLayers];
    
    kcmIdIndex=[[NSMutableDictionary alloc] init];
    dotSprites=[[NSMutableArray alloc] init];
    nodeSprites=[[NSMutableArray alloc] init];
    nodeSliceNodes=[[NSMutableArray alloc] init];
    lightSprites=[[NSMutableArray alloc] init];
    
    kcmNodes=[contentService allConceptNodes];
    
    [self parseForBoundsAndCreateKcmIndex];
    
    //shifting to proximity create
    //[self createNodeSprites];

    //not doing this at all atm
    //[self parseAndCreateSpritesForPreReqRelations];
    
    //shifting to proximity features
    //[self addFeaturesInEmptySpace];
    
    //we don't want to do this -- needs to move to dynamic draw
    //[self createAllBackgroundTileSprites];
    
    [self createLights];
    
    [self addTerrainAtPosition:ccp(1208,-3587) withFile:BUNDLE_FULL_PATH(@"/images/map/fjord-with-base-25%.png")];
    
    [self addTerrainAtPosition:ccp(1562,-3500) withFile:BUNDLE_FULL_PATH(@"/images/map/forrest-with-base-4-25%.png")];
    
    [self addTerrainAtPosition:ccp(1201,-3226) withFile:BUNDLE_FULL_PATH(@"/images/map/forrest-with-base-3-25%.png")];
    
    [self addTerrainAtPosition:ccp(1480,-3032) withFile:BUNDLE_FULL_PATH(@"/images/map/hills-with-base-1-25%.png")];
    
    [self addTerrainAtPosition:ccp(1451,-2751) withFile:BUNDLE_FULL_PATH(@"/images/map/mountain-range-with-base-1-25%.png")];
    
    [self addTerrainAtPosition:ccp(1038,-2780) withFile:BUNDLE_FULL_PATH(@"/images/map/mountains-with-base-1-25%.png")];
    
    [self addTerrainAtPosition:ccp(1146,-2076) withFile:BUNDLE_FULL_PATH(@"/images/map/lake-with-base-1-25%.png")];
    
    [self addTerrainAtPosition:ccp(834,-2288) withFile:BUNDLE_FULL_PATH(@"/images/map/lake-with-base-4-25%.png")];
    
    [self addTerrainAtPosition:ccp(1553,-2290) withFile:BUNDLE_FULL_PATH(@"/images/map/mountain-range-with-base-1-25%.png")];
    
    [self addTerrainAtPosition:ccp(1553,-2290) withFile:BUNDLE_FULL_PATH(@"/images/map/mountain-range-with-base-1-25%.png")];
    
    [self addTerrainAtPosition:ccp(587,-2940) withFile:BUNDLE_FULL_PATH(@"/images/map/hills-with-base-3-25%.png")];
    
    //reposition if previous node
    if(contentService.currentNode)
    {
        //put map at this position
        CGPoint p=ccp(-[contentService.currentNode.x floatValue] * kNodeScale, -(nMaxY - [contentService.currentNode.y floatValue]) * kNodeScale);
        p=ccpAdd(ccp(cx, cy), p);
        [mapLayer setPosition:p];
    }
    
    NSLog(@"node bounds are %f, %f -- %f, %f", nMinX, nMinY, nMaxX, nMaxY);
}

-(void)addTerrainAtPosition:(CGPoint)location withFile:(NSString*)thisImage
{
    
    CCSprite *thisSprite=[CCSprite spriteWithFile:thisImage];
    [thisSprite setPosition:location];
    [mapLayer addChild:thisSprite];
}

- (void)createLayers
{
    //base colour layer
//    CCLayer *cLayer=[[CCLayerColor alloc] initWithColor:ccc4(0, 59, 72, 255) width:lx height:ly];
    CCLayer *cLayer=[[CCLayerColor alloc] initWithColor:ccc4(137, 173, 171, 255) width:lx height:ly];
    [self addChild:cLayer];
    
    //base map layer
    mapLayer=[[CCLayer alloc] init];
    [mapLayer setPosition:kStartMapPos];        

    [self addChild:mapLayer];

    //darkness layer
    darknessLayer=[CCRenderTexture renderTextureWithWidth:lx height:ly];
    [darknessLayer setPosition:ccp(cx, cy)];
    [self addChild:darknessLayer];

    //fore layer
    foreLayer=[[CCLayer alloc] init];
    [self addChild:foreLayer];
    
}

-(void)createLights
{
    //test lights
//    CCSprite *l=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/node-light.png")];
//    [l setBlendFunc:(ccBlendFunc){GL_ZERO, GL_ONE_MINUS_SRC_ALPHA}];
//    [l setPosition:ccp(cx, cy)];
//    [l setScale:10.0f];
//    //[darknessLayer addChild:l];
//    [l retain];
//    [lightSprites addObject:l];
    
    //zubi light
    zubiLight=[self createLight];
    [zubiLight setScale:3.0f];
    
    //nodeslice light
    nodeSliceLight=[self createLight];
    [nodeSliceLight setScale:14.0f];
    [nodeSliceLight setPosition:kNodeSliceOrigin];
    //only add this when in the correct mode
    [lightSprites removeObject:nodeSliceLight];
}

-(CCSprite*)createLight
{
    CCSprite *l=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/node-light.png")];
    [l setBlendFunc:(ccBlendFunc){GL_ZERO, GL_ONE_MINUS_SRC_ALPHA}];
    [l setPosition:ccp(cx, cy)];
    [l setScale:10.0f];
    [l retain];
    [lightSprites addObject:l];    
    return l;
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

- (void)parseForBoundsAndCreateKcmIndex
{
    //find bounds
    //set bounds to first element
    if(kcmNodes.count>0)
    {
        ConceptNode *n1=[kcmNodes objectAtIndex:0];
        nMinX=[n1.x floatValue];
        nMinY=[n1.y floatValue];
        nMaxX=nMinX;
        nMaxY=nMaxY;
        
        //clean up any left over sprite info from last use
        n1.journeySprite=nil;
        n1.lightSprite=nil;
        n1.nodeSliceSprite=nil;
        
        for (int i=1; i<[kcmNodes count]; i++) {
            ConceptNode *n=[kcmNodes objectAtIndex:i];
            if([n.x floatValue]<nMinX)nMinX=[n.x floatValue];
            if([n.y floatValue]<nMinY)nMinY=[n.y floatValue];
            if([n.x floatValue]>nMaxX)nMaxX=[n.x floatValue];
            if([n.y floatValue]>nMaxY)nMaxY=[n.y floatValue];
            
            //add reference
            [kcmIdIndex setValue:[NSNumber numberWithInt:i] forKey:n.document.documentID];
            
            //force quit at max (e.g. 50) nodes
            if(i>=kNodeMax) break;

            //clean up any left over sprite info from last use
            n.journeySprite=nil;
            n.lightSprite=nil;
            n.nodeSliceSprite=nil;
        }
    }
    
    nMinX=nMinX*kNodeScale;
    nMinY=nMinY*kNodeScale;
    nMaxX=nMaxX*kNodeScale;
    nMaxY=nMaxY*kNodeScale;
}

- (void)parseAndCreateSpritesForPreReqRelations
{
    prereqRelations=[contentService relationMembersForName:@"Prerequisites"];
    NSLog(@"relation count %d", [prereqRelations count]);
    
    //iterate relations and find start/end points
    for (NSArray *rel in prereqRelations) {
        NSString *id1=[rel objectAtIndex:0];
        NSString *id2=[rel objectAtIndex:1];
        
        NSNumber *idx1=[kcmIdIndex objectForKey:id1];
        NSNumber *idx2=[kcmIdIndex objectForKey:id2];
        
        if(idx1 && idx2)
        {
            CCSprite *cs1=[nodeSprites objectAtIndex:[idx1 integerValue]];
            CCSprite *cs2=[nodeSprites objectAtIndex:[idx2 integerValue]];
            
            CGPoint pos1=[cs1 position];
            CGPoint pos2=[cs2 position];
            
            [self drawPathFrom:pos1 to:pos2];
        }
    }
}

#pragma mark drawing and sprite creation

-(void)drawPathFrom:(CGPoint)p1 to:(CGPoint)p2
{
    //get the lenth of the vector
    float l=[BLMath DistanceBetween:p1 and:p2];
    
    //how many points to plot
    float dotCount=l / 50.0f;
    
    //vector between
    CGPoint diff=[BLMath SubtractVector:p2 from:p1];
    
    float gapx=diff.x / dotCount;
    float gapy=diff.y / dotCount;
    
    if(dotCount>=1)
    {
        for(int i=1; i<=(int)dotCount; i++)
        {
            //put dot at p1 + (gapx * i, gapy * i)
            CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/node-std.png")];
            [s setScale:0.25];
            [s setOpacity:100];
            [s setPosition:ccpAdd(p1, ccp(i*gapx, i*gapy))];
            [mapLayer addChild:s];
            [dotSprites addObject:s];
        }
    }
}

-(void)createNodeSprites
{
    //effectively depracated -- this iterates all nodes and draws them
    
    for(int i=0; i<kcmNodes.count; i++)
    {
        ConceptNode *n=[kcmNodes objectAtIndex:i];
        
        [self createASpriteForNode:n];
    }
}

-(CGPoint)currentCentre
{
    CGPoint c=ccp(-mapLayer.position.x + (0.5f*lx), -mapLayer.position.y + (0.5f*ly));
    return c;
}

-(void)createNodeSpritesNearCentre
{
    [self createNodeSpritesNear:[self currentCentre]];
}

-(void)createNodeSpritesNear:(CGPoint)loc
{
    //creates sprites within kPropXNodeDrawDist of loc, and destroys them outside of that
    
    for(int i=0; i<kcmNodes.count; i++)
    {
        ConceptNode *n=[kcmNodes objectAtIndex:i];
     
        
        CGPoint nlpos=ccp([n.x floatValue] * kNodeScale, (nMaxY-[n.y floatValue]) * kNodeScale);
        float diff=[BLMath DistanceBetween:loc and:nlpos];
        
        if(diff<(kPropXNodeDrawDist*lx))
        {
            //create a sprite
            if(!n.journeySprite || contentService.fullRedraw)
            {
                [self createASpriteForNode:n];
                
                if(!visibleNodes)
                    visibleNodes=[[NSMutableArray alloc] init];
                
                //also add to visible nodes
                [visibleNodes addObject:n];
                
                //setup light if required
                BOOL isLit=[usersService hasCompletedNodeId:n.document.documentID];
                
                if(isLit || [n.document.documentID isEqualToString:@"5608a59d6797796ce9e11484fd180214"]
                   || [n.document.documentID isEqualToString:@"5608a59d6797796ce9e11484fd180be3"])
                {
                    n.lightSprite=[self createLight];
                    [n.lightSprite setPosition:[mapLayer convertToWorldSpace:n.journeySprite.position]];
                    
                    //if this is the node just completed, animate it
                    if (n==contentService.currentNode && contentService.lightUpProgressFromLastNode) {
                        NSLog(@"got just completed node");
                        [n.lightSprite setTag:1];
//                        [n.lightSprite setOpacity:0];
                        [n.lightSprite setScale:1.0f];
//                        [n.lightSprite runAction:[CCFadeIn actionWithDuration:1.0f]];
//                        [n.lightSprite runAction:[CCScaleTo actionWithDuration:1.0f scale:10.0f]];
                    }
                }
            }
        }
        else {
            //destroy the sprite, if present
            if(n.journeySprite)
            {
                [mapLayer removeChild:n.journeySprite cleanup:YES];
                [nodeSprites removeObject:n.journeySprite];
                
                //[n.journeySprite release];
                n.journeySprite=nil;
                
                //remove light if present
                if(n.lightSprite)
                {
                    [lightSprites removeObject:n.lightSprite];
                    n.lightSprite=nil;
                }
                
                //remove from visible nodes
                [visibleNodes removeObject:n];
            }
        }
    
    }   
    
    contentService.fullRedraw=NO;
    contentService.lightUpProgressFromLastNode=NO;
}

-(void)createASpriteForNode:(ConceptNode *)n
{
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/node-std.png")];
    [s setPosition:ccp([n.x floatValue] * kNodeScale, (nMaxY-[n.y floatValue]) * kNodeScale)];
    
    if(n.pipelines.count==0)
    {
        [s setOpacity:100];
    }
    else {
        NSLog(@"pipelines %d", n.pipelines.count);
    }
    
    NSLog(@"id: %@ pipelines: %d", n.document.documentID, n.pipelines.count);
    
    [mapLayer addChild:s];
    [nodeSprites addObject:s];    
    
    n.journeySprite=s;
}

-(void)addFeaturesInEmptySpace
{
    int fCount=0;
    float minDist=100.0f;
    
    int xDiff=(nMaxX - nMinX) + nMinX;
    int yDiff=(nMaxY - nMinY) + nMinY;
    
    do {
        int rx=arc4random() % xDiff;
        int ry=arc4random() % yDiff;
        
//        float x=rx*xDiff;
//        float y=ry*yDiff;
        
        CGPoint pos=ccp(rx, ry);
        BOOL found=NO;
        for (CCNode *n in nodeSprites) {
            if(fabsf([BLMath DistanceBetween:pos and:n.position])<minDist)
            {
                found=YES;
                return;
            }
        }
        for (CCNode *n in dotSprites) {
            if(fabsf([BLMath DistanceBetween:pos and:n.position])<minDist)
            {
                found=YES;
                return;
            }
        }
        
        if(!found)
        {
            [self drawFeatureAt:pos];
            fCount++;
        }
        
    } while (fCount<100);
}

-(void)drawFeatureAt:(CGPoint)pos
{
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/features/large1.png")];
    [s setPosition:pos];
    [s setScale:0.25f];
    [mapLayer addChild:s];
}

#pragma mark loops

-(void) doUpdate:(ccTime)delta
{
    [daemon doUpdate:delta];
    deltacum+=delta;
    
    if(juiState==kJuiStateNodeSliceTransition)
    {
        nodeSliceTransitionHold+=delta;
    }
    
    //update light positions
    [self updateLightPositions];
    
    //render darkness layer
    [darknessLayer clear:0.0f g:0.0f b:0.0f a:0.7f];
    
    [darknessLayer begin];
    

    glColorMask(0, 0, 0, 1);
    
    for (CCSprite *l in lightSprites) {
        
        if(l.tag==1)
        {
            if(deltacum>l.tag * kLightInDelay)
            {
                float prop = deltacum - (l.tag * kLightInDelay);
                float newscale=kLightInScaleMax * (prop / kLightInTime);
                if(newscale>kLightInScaleMax)
                {
                    newscale=kLightInScaleMax;
                }
                [l setScale:newscale];
            }
        }
        
        [l visit];
    }
    
    glColorMask(1, 1, 1, 1);
    
    [darknessLayer end];
}

-(void)updateLightPositions
{
    //[zubiLight setPosition:[mapLayer convertToWorldSpace:[daemon currentPosition]]];
    [zubiLight setPosition:[daemon currentPosition]];
    
    for (ConceptNode *n in visibleNodes) {
        if(n.lightSprite)
        {
            [n.lightSprite setPosition:[mapLayer convertToWorldSpace:n.journeySprite.position]];
        }
    }
}

-(void) doUpdateCreateNodes:(ccTime)delta
{
    [self createNodeSpritesNearCentre];
}

#pragma mark location testing and queries

-(ConceptNode*) nodeWithin:(float)distance ofLocation:(CGPoint)location
{
    //returns first node withing distance of location
    for(int i=0; i<kcmNodes.count; i++)
    {
        ConceptNode *n=[kcmNodes objectAtIndex:i];
        
        
        CGPoint nlpos=ccp([n.x floatValue] * kNodeScale, (nMaxY-[n.y floatValue]) * kNodeScale);
        float diff=[BLMath DistanceBetween:location and:nlpos];
        
        if(diff<distance)
        {
            return n;
        }
    }
    return nil;
}

#pragma mark transitions

-(void)createNodeSliceFrom:(ConceptNode*)n
{
    //establish if there are problems
    currentNodeSliceHasProblems=n.pipelines.count>0;
    if(currentNodeSliceHasProblems)
    {
        currentNodeSliceHasProblems=NO;
        for (int i=0; i<n.pipelines.count; i++) {
            
            Pipeline *p=[[CouchModelFactory sharedInstance] modelForDocument:[[contentService Database] documentWithID:[n.pipelines objectAtIndex:i]]];
            
            if(p.problems.count>0)
            {
                currentNodeSliceHasProblems=YES;
                break;
            }
        }
    }
    
    NSString *bpath=BUNDLE_FULL_PATH(@"/images/journeymap/nodeslice-bkg.png");
    if(!currentNodeSliceHasProblems) bpath=BUNDLE_FULL_PATH(@"/images/journeymap/nodeslice-bkg-nopin.png");
    
    CCSprite *ns=[CCSprite spriteWithFile:bpath];
    [ns setScale:kNodeSliceStartScale];
    [ns setPosition:n.journeySprite.position];

    [mapLayer addChild:ns];
    [nodeSliceNodes addObject:n];
    
    n.nodeSliceSprite=ns;
    
    float time1=0.1f;
    float time2=0.9f;
    float time3=0.2f;
    
    CCScaleTo *scale1=[CCScaleTo actionWithDuration:time1 scale:0.3f];
    CCScaleTo *scale2=[CCScaleTo actionWithDuration:time2 scale:0.5f];
    CCEaseOut *ease2=[CCEaseOut actionWithAction:scale2 rate:0.5f];
    CCScaleTo *scale3=[CCScaleTo actionWithDuration:time3 scale:1.0f];
    CCSequence *scaleSeq=[CCSequence actions:scale1, ease2, scale3, nil];
    
    CCDelayTime *move1=[CCDelayTime actionWithDuration:time1 + time2];
    CCMoveTo *move2=[CCMoveTo actionWithDuration:time3 position:[mapLayer convertToNodeSpace:kNodeSliceOrigin]];
    CCSequence *moveSeq=[CCSequence actions:move1, move2, nil];
    
    [ns runAction:scaleSeq];
    [ns runAction:moveSeq];
}

-(void)cancelNodeSliceTransition
{
    if(!currentNodeSliceNode) return;
    
    CCSprite *ns=currentNodeSliceNode.nodeSliceSprite;
    
    [ns stopAllActions];
    
    CCScaleTo *scaleto=[CCScaleTo actionWithDuration:0.2f scale:kNodeSliceStartScale];
    CCFadeOut *fade=[CCFadeOut actionWithDuration:0.6f];
    CCMoveTo *moveto=[CCMoveTo actionWithDuration:0.2f position:currentNodeSliceNode.journeySprite.position];
    [ns runAction:scaleto];
    [ns runAction:fade];
    [ns runAction:moveto];
    
    currentNodeSliceNode=nil;
}

-(void)tidyUpRemovedNodeSlices
{
    NSMutableArray *removedS=[[NSMutableArray alloc] init];
    
    for (ConceptNode *n in nodeSliceNodes) {
        if(n.nodeSliceSprite.opacity==0)
        {
            [mapLayer removeChild:n.nodeSliceSprite cleanup:YES];
            //[n.nodeSliceSprite release];
            n.nodeSliceSprite=nil;
            [removedS addObject:n];
            
        }
    }
    
    [nodeSliceNodes removeObjectsInArray:removedS];
    [removedS release];
}

-(void)removeNodeSlices
{
    [self tidyUpRemovedNodeSlices];
    
    if([lightSprites containsObject:nodeSliceLight])[lightSprites removeObject:nodeSliceLight];
    
    for (ConceptNode *n in nodeSliceNodes) {
        
        CCSprite *ns=n.nodeSliceSprite;
        
        if(ns.opacity==255)
        {
            CCScaleTo *scaleto=[CCScaleTo actionWithDuration:0.2f scale:kNodeSliceStartScale];
            CCFadeOut *fade=[CCFadeOut actionWithDuration:0.6f];
            CCMoveTo *moveto=[CCMoveTo actionWithDuration:0.2f position:n.journeySprite.position];
            [ns runAction:scaleto];
            [ns runAction:fade];
            [ns runAction:moveto];
        }
    }
    
}

#pragma mark user i/o

-(void)startSeletedPin
{
    NSLog(@"starting pipeline 0 for node %@", currentNodeSliceNode.nodeDescription);
    
    if (currentNodeSliceNode.pipelines.count>0) {
        [contentService startPipelineWithId:[currentNodeSliceNode.pipelines objectAtIndex:0] forNode:currentNodeSliceNode];
        [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
    }
    else {
        NSLog(@"failed to start -- no pipelines found");
    }
}

#pragma mark touch handling



-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
 
    lastTouch=l;
    
    CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
 
    NSLog(@"touched at %@", NSStringFromCGPoint(lOnMap));
    
    [daemon setTarget:l];
    [daemon setRestingPoint:l];
    
    //assume touch didn't start in the node map
    touchStartedInNodeMap=NO;

    if (juiState==kJuiStateNodeMap) {
        
        [self removeNodeSlices];
        
        [self testForNodeSliceTransitionStartWithTouchAt:lOnMap];
        
        touchStartedInNodeMap=YES;
    }
    
    else if(juiState==kJuiStateNodeSlice)
    {
        if([BLMath DistanceBetween:lOnMap and:currentNodeSliceNode.nodeSliceSprite.position] >= kNodeSliceRadius)
        {
            //handle as normal tap -- but reset to node map state in case a new node isn't hit
            juiState=kJuiStateNodeMap;
            
            [self removeNodeSlices];
            
            [self testForNodeSliceTransitionStartWithTouchAt:lOnMap];
            
            touchStartedInNodeMap=YES;
        }
        else {
            //handle as a tap in the nodeslice
            
            //look for tap on pin
            if(currentNodeSliceHasProblems)
            {
                CGPoint pinOnMap=[mapLayer convertToNodeSpace:ccpAdd(kNodeSliceOrigin, kPinOffset)];
                
                if([BLMath DistanceBetween:pinOnMap and:lOnMap] <= kPinTapRadius)
                {
                    [self startSeletedPin];
                }
            }
        }
    }
}

- (void)testForNodeSliceTransitionStartWithTouchAt:(CGPoint)lOnMap
{
    //test for node hit and start transition
    ConceptNode *n=[self nodeWithin:(kPropXNodeHitDist * lx) ofLocation:lOnMap];
    if(n)
    {
        [self createNodeSliceFrom:n];
        NSLog(@"hit node %@", n.document.documentID);
        
        //keep this to move there if the user pans during transition
        mapPosAtNodeSliceTransitionComplete=mapLayer.position;
        
        juiState=kJuiStateNodeSliceTransition;
        nodeSliceTransitionHold=0.0f;
        currentNodeSliceNode=n;
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
            [mapLayer setPosition:[BLMath AddVector:mapLayer.position toVector:[BLMath SubtractVector:lastTouch from:l]]];
            
            lastTouch=l;
            
            CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
            
            [daemon setTarget:l];    
            [daemon setRestingPoint:l];
        }
    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(juiState==kJuiStateNodeSliceTransition)
    {
        if(nodeSliceTransitionHold>=kNodeSliceHoldTime)
        {
            //alow the transition to complete, and change state
            juiState=kJuiStateNodeSlice;
            
            //move the map layer to get nodeslice view in correct position if user panned
            [mapLayer runAction:[CCEaseIn actionWithAction:[CCMoveTo actionWithDuration:0.2f position:mapPosAtNodeSliceTransitionComplete] rate:0.5f]];
            
            //add the nodeslice light
            [lightSprites addObject:nodeSliceLight];
        }
        else {
            //cancel current transition
            [self cancelNodeSliceTransition];
            
            juiState=kJuiStateNodeMap;
        }
    }
}

-(void)dealloc
{
    [kcmNodes release];
    [kcmIdIndex release];
    [nodeSprites release];
    [dotSprites release];
    [visibleNodes release];
    [prereqRelations release];
    [nodeSliceNodes release];
    [lightSprites release];
    
    [super dealloc];
}

@end
