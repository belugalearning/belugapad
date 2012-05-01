//
//  JourneyScene.m
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JourneyScene.h"

#import "Daemon.h"
#import "global.h"
#import "BLMath.h"

#import "AppDelegate.h"
#import "ContentService.h"
#import "UsersService.h"

#import "ConceptNode.h"

static float kNodeScale=2.0f;
static CGPoint kStartMapPos={-3376, -1457};

static int kNodeMax=50;

@interface JourneyScene()
{
    @private
    ContentService *contentService;

    NSArray *kcmNodes;
    NSDictionary *kcmIdIndex;
    NSMutableArray *nodeSprites;
    NSMutableArray *dotSprites;
    
    NSArray *prereqRelations;
    
    float nMinX, nMinY, nMaxX, nMaxY;
    float scale;
}

@end

@implementation JourneyScene

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
        [[CCDirector sharedDirector] view].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        lx=winsize.width;
        ly=winsize.height;
        cx = lx / 2.0f;
        cy = ly / 2.0f;
        
        scale=1.0f;
        
        contentService = ((AppController*)[[UIApplication sharedApplication] delegate]).contentService; 
        
        [self setupMap];
        
        [self addFeatures];
        
        [self schedule:@selector(doUpdate:) interval:1.0f / 60.0f];
        
        daemon=[[Daemon alloc] initWithLayer:mapLayer andRestingPostion:[mapLayer convertToNodeSpace:ccp(cx, cy)] andLy:ly];
        [daemon setMode:kDaemonModeFollowing];
    }
    
    return self;
}

-(void) setupMap
{
    //base colour layer
    CCLayer *cLayer=[[CCLayerColor alloc] initWithColor:ccc4(0, 59, 72, 255) width:lx height:ly];
    [self addChild:cLayer];
    
    //base map layer
    mapLayer=[[CCLayer alloc] init];
    [mapLayer setPosition:kStartMapPos];
    [self addChild:mapLayer];
    
    //add overlay on centre tile
//    CCSprite *sample=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/samplenodes.png")];
//    [sample setPosition:ccp(cx, cy)];
//    [mapLayer addChild:sample];
    
    kcmIdIndex=[[NSMutableDictionary alloc] init];
    dotSprites=[[NSMutableArray alloc] init];
    nodeSprites=[[NSMutableArray alloc] init];
    
    kcmNodes=[contentService allConceptNodes];
    
    //find bounds
    //set bounds to first element
    if(kcmNodes.count>0)
    {
        ConceptNode *n1=[kcmNodes objectAtIndex:0];
        nMinX=[n1.x floatValue];
        nMinY=[n1.y floatValue];
        nMaxX=nMinX;
        nMaxY=nMaxY;
        
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
        }
    }
    
    nMinX=nMinX*kNodeScale;
    nMinY=nMinY*kNodeScale;
    nMaxX=nMaxX*kNodeScale;
    nMaxY=nMaxY*kNodeScale;
    
    [self createNodeSprites];
    
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
    
    //add background to the map itself
    
//    int rsize=(int)((nMaxY-nMinY) / ly);
//    int csize=(int)((nMaxX-nMinX) / lx);
//    
//    for (int r=0; r<=rsize; r++) {
//        for (int c=0; c<csize; c++) {
//            CCSprite *btile=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/mapbase.png")];
//            [btile setPosition:ccp((lx*c)+cx, (ly*r)+cy)];
//            [mapLayer addChild:btile];
//        }
//    }
    
    NSLog(@"node bounds are %f, %f -- %f, %f", nMinX, nMinY, nMaxX, nMaxY);
}

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
    for(int i=0; i<kcmNodes.count; i++)
    {
        ConceptNode *n=[kcmNodes objectAtIndex:i];
        
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/journeymap/node-std.png")];
        [s setPosition:ccp([n.x floatValue] / kNodeScale, [n.y floatValue] / kNodeScale)];
        
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
        
    }
}

-(void)addFeatures
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

-(void) doUpdate:(ccTime)delta
{
    [daemon doUpdate:delta];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
 
    lastTouch=l;
    
    CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
    
    [daemon setTarget:lOnMap];
    [daemon setRestingPoint:lOnMap];
    
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint l=[touch locationInView:[touch view]];
    l=[[CCDirector sharedDirector] convertToGL:l];
    
    //pinch handling
    if([touches count]>1)
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
        
        
        scale+=(scaleChange / cx) * 0.01f;
        
        if(scale<0.1f)scale=0.1f;
        if(scale>2.0f)scale=1.0f;
        
        CGPoint avgPos=ccpMult(ccpAdd(t1b, t2b), 0.5f);
        CGPoint diffCenter=[BLMath SubtractVector:mapLayer.position from:avgPos];
        
        //[mapLayer setPosition:ccpAdd(mapLayer.position, ccpMult(diffCenter, (1-(scaleChange / cx))*0.01f))];
        
        NSLog(@"ns avgpos %@", NSStringFromCGPoint([mapLayer convertToNodeSpace:avgPos]));
        
        [mapLayer setAnchorPoint:[mapLayer convertToNodeSpace:avgPos]];
        [mapLayer setScale:scale];
        
        //NSLog(@"scale: %f", scale);
    }
    else {
        [mapLayer setPosition:[BLMath AddVector:mapLayer.position toVector:[BLMath SubtractVector:lastTouch from:l]]];
        
        lastTouch=l;
        
        CGPoint lOnMap=[mapLayer convertToNodeSpace:l];
        
        [daemon setTarget:lOnMap];    
        [daemon setRestingPoint:lOnMap];

    }
    
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //CGPoint tapFromC=[BLMath SubtractVector:ccp(cx, cy) from:lastTouch];
    //CGPoint moveBy=ccp(-tapFromC.x, -tapFromC.y);
    
    //CCMoveBy *m=[CCMoveBy actionWithDuration:2.5f position:moveBy];
    
    //CCEaseInOut *ease=[CCEaseInOut actionWithAction:[CCMoveBy actionWithDuration:2.0f position:moveBy] rate:0.5f];
    
    //CCEaseOut *eout=[CCEaseOut actionWithAction:m rate:0.6f];
    //CCEaseIn *ein=[CCEaseIn actionWithAction:eout rate:0.6f];
    
    //CCEaseIn *eins=[CCEaseIn actionWithAction:m rate:0.5f];
    
    //[mapLayer runAction:eins];
}



@end