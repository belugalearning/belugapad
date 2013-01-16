//
//  SGJmapMNodeRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapMasteryNodeRender.h"
#import "SGJmapMasteryNode.h"
#import "SGJmapNode.h"
#import "PRFilledPolygon.h"
#import "BLMath.h"
#import "global.h"
#import "SGJmapPaperPlane.h"
#import "SimpleAudioEngine.h"

#import "TouchXML.h"

static ccColor4B userCol={80, 110, 146, 255};
static ccColor4B userCol2={120, 168, 221, 255};
//static ccColor4B userCol={101, 140, 153, 255};
//static ccColor4B userCol={0, 51, 98, 255};
//static ccColor4B userCol={150,90,200,255};
//static ccColor4B userCol={150,90,200,255};
//static ccColor4B userHighCol={255, 255, 255, 50};
//static ccColor4B userHighCol={239,119,82,255};
static int shadowSteps=5;

#define FEATURE_UNIQUE_VARIANTS 2


@interface SGJmapMasteryNodeRender()
{
    CCSprite *nodeSprite;
    CCSprite *labelSprite;
    CCSprite *labelShadowSprite;
}

@end

@implementation SGJmapMasteryNodeRender

@synthesize ParentGO, sortedChildren, allPerimPoints, scaledPerimPoints, zoomedOut;

@synthesize islandShapeIdx, islandLayoutIdx, islandStage;

@synthesize previousIslandStage;

-(SGJmapMasteryNodeRender*)initWithGameObject:(id<Transform, CouchDerived>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=(SGJmapMasteryNode*)aGameObject;
        
        //[self setup];
        
        islandData=[[NSMutableDictionary alloc] init];
        featureSprites=[[NSMutableArray alloc] init];
        
        zoomedOut=NO;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    if(messageType==kSGreadyRender)
    {
        [self setup];
        
//        [self readyRender];
        
        [self readyNodeSpriteRender];
        
        [self readyIslandRender];
    }
    
    else if(messageType==kSGvisibilityChanged)
    {
        nodeSprite.visible=ParentGO.Visible;
        islandShadowSprite.visible=ParentGO.Visible;
        
        if(ParentGO.Visible)
        {
            [labelSprite runAction:[CCFadeTo actionWithDuration:0.5f opacity:255]];
            [labelShadowSprite runAction:[CCFadeTo actionWithDuration:0.75f opacity:255]];
        }
        else
        {
            labelShadowSprite.opacity=0;
            labelSprite.opacity=0;
            
//            [labelSprite runAction:[CCFadeTo actionWithDuration:0.25f opacity:0]];
//            [labelShadowSprite runAction:[CCFadeTo actionWithDuration:0.15f opacity:0]];
        }
        
        for (CCSprite *s in featureSprites) {
            s.visible=ParentGO.Visible;
        }
        
    }
    
    if(messageType==kSGzoomOut)
    {
        //[self setPointScalesAt:REGION_ZOOM_LEVEL];
        
        [nodeSprite setVisible:NO];
        islandSprite.visible=YES;
        islandShadowSprite.visible=NO;
        ParentGO.Visible=YES;
        zoomedOut=YES;
        
        labelSprite.opacity=255;
        labelShadowSprite.opacity=255;
        
        [labelSprite runAction:[CCFadeTo actionWithDuration:0.25f opacity:0]];
        [labelShadowSprite runAction:[CCFadeTo actionWithDuration:0.15f opacity:0]];
        
        for (CCSprite *s in featureSprites) {
            //rly!?
            s.visible=YES;
        }
    }
    if(messageType==kSGzoomIn)
    {
        islandSprite.visible=YES;
        
        [self setPointScalesAt:1.0f];
        //islandSprite.visible=ParentGO.Visible;
        
        zoomedOut=NO;
    }
    
    if(messageType==kSGforceLayout)
    {
        [self forceLayoutStep];
    }
}

-(void)dealloc
{
    free(allPerimPoints);
    free(scaledPerimPoints);
    
    [sortedChildren release];
    [texturePoints release];
    
    [islandData release];
    [featureSprites release];

    self.indexedBaseNodes=nil;
    
    [super dealloc];
}

#pragma mark - physical force-directed layout step

-(void)forceLayoutStep
{
    CGPoint max=ccp(900,900);
    CGPoint avgp=ccp(0,0);
    int countx=0, county=0;
    
    //connections from mnodes
    
    for(SGJmapMasteryNode *n in ParentGO.ConnectFromMasteryNodes)
    {
        CGPoint diff=[BLMath SubtractVector:n.Position from:ParentGO.Position];
        diff=ccp(fabsf(diff.x), fabsf(diff.y));
        if(diff.x<max.x || YES)
        {
            avgp=ccp(avgp.x+((max.x - diff.x)*(max.x - diff.x)), avgp.y);
            countx++;
        }
        if(diff.y<max.y || YES)
        {
            avgp=ccp(avgp.x, avgp.y + ((max.y - diff.y)*(max.y - diff.y)));
            county++;
        }
    }
    
    
    //connections to notes
    for(SGJmapMasteryNode *n in ParentGO.ConnectToMasteryNodes)
    {
        CGPoint diff=[BLMath SubtractVector:n.Position from:ParentGO.Position];
        diff=ccp(fabsf(diff.x), fabsf(diff.y));
        if(diff.x<max.x || YES)
        {
            avgp=ccp(avgp.x+((max.x - diff.x)*(max.x - diff.x)), avgp.y);
            countx++;
        }
        if(diff.y<max.y || YES)
        {
            avgp=ccp(avgp.x, avgp.y + ((max.y - diff.y)*(max.y - diff.y)));
            county++;
        }
    }

    //NSLog(@"avgp pre  %@", NSStringFromCGPoint(avgp));
    
//    if(countx>0)avgp=ccp(avgp.x / (float)countx, avgp.y);
//    if(county>0)avgp=ccp(avgp.x, avgp.y / (float)county);
    
    //NSLog(@"avgp post %@", NSStringFromCGPoint(avgp));
    
    //root of those squared
//    avgp=ccp(sqrtf(avgp.x), sqrtf(avgp.y));
    
    //inverse and multiply
//    avgp=ccp(avgp.x * 0.01f, avgp.y*0.02f);
    
    //NSLog(@"avgp adj  %@", NSStringFromCGPoint(avgp));
    
    //reset position
    //ParentGO.Position=[BLMath AddVector:ParentGO.Position toVector:avgp];
}

#pragma mark - update and draw (draw only used in debug)

-(void)doUpdate:(ccTime)delta
{
    if(needToTransition)
    {
        if([gameWorld.Blackboard.jmapInstance isPointInView:ParentGO.Position])
        {
            [self transitionToNewState];
        }
    }
}

-(void)draw:(int)z
{
    //no current drawing outside of debug and draw testing
    
//    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
    
    if(z==1)
    {
        //this was island base colour -- now in render node
    }
    else if (z==2)
    {
        
//        ccColor4F f4=ccc4FFromccc4B(currentCol);
//        
//        //lines to inter mastery nodes
//        for(id<Transform> imnode in ParentGO.ConnectToMasteryNodes) {
//            //world space of their pos
//            CGPoint tWP=[ParentGO.RenderBatch.parent convertToWorldSpace:imnode.Position];
//            
////            ccDrawColor4B(userCol.r, userCol.g, userCol.b, userCol.a);
////            ccDrawLine(myWorldPos, tWP);
//            
//            float x1=myWorldPos.x;
//            float y1=myWorldPos.y;
//            float x2=tWP.x;
//            float y2=tWP.y;
//            
//            float L=sqrtf((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
//            
//            int lines=5;
//            if(zoomedOut) lines=1;
//            
//            for (float width=-lines; width<(lines+1); width+=0.75f)
//            {
//                float x1p=x1+width * (y2-y1) / L;
//                float x2p=x2+width * (y2-y1) / L;
//                float y1p=y1+width * (x1-x2) / L;
//                float y2p=y2+width * (x1-x2) / L;
//                
//                if(zoomedOut) ccDrawColor4F(f4.r, f4.g, f4.b, 0.15f);
//                else ccDrawColor4F(f4.r, f4.g, f4.b, 0.35f);
//                
//                ccDrawLine(ccp(x1p, y1p), ccp(x2p, y2p));
//            }
//            
//        }    
    }
}

#pragma mark - sprite / fixed position layout, main setup sequence

-(void)setup
{
    self.islandShapeIdx=ParentGO.renderBase;
    
    self.islandLayoutIdx=ParentGO.renderLayout % 4;
    if(self.islandLayoutIdx>0)self.islandLayoutIdx-=1;

    //island stage
    self.islandStage=1;
    if(ParentGO.PrereqPercentage>=30)self.islandStage=3;
    if(ParentGO.PrereqPercentage>=70)self.islandStage=5;
    
    self.previousIslandStage=1;
    if(ParentGO.PreviousPreReqPercentage>=30)self.previousIslandStage=3;
    if(ParentGO.PreviousPreReqPercentage>=70)self.previousIslandStage=5;
    
    [self createBaseNodes];
    
    //position children
    
    //all nodes with data
    NSArray *fnodes= [[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"NODES"];
    
//    NSLog(@"NODE COUNT: %d", ParentGO.ChildNodes.count);
    
    //step all children -- layout and attach artefact positions
    NSArray *artefacts=[[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"ARTEFACTS"];
    int artefactIdx=0;
    
    for (int i=0; i<ParentGO.ChildNodes.count; i++)
    {
        SGJmapNode *child=[ParentGO.ChildNodes objectAtIndex:i];
     
        //get corresponding data
        NSDictionary *fnode=[fnodes objectAtIndex:i];
        
        //skip if no corresponding data
        if(!fnode) continue;
        
        //find this node in the indexed list of all features
        int targetIdx=[[[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"FEATURE_INDEX"] indexOfObject:fnode];
        
        //get position by copying from indexed placeholder
        CGPoint pos=((CCSprite*)[self.indexedBaseNodes objectAtIndex:targetIdx]).position;
        
        child.Position=ccp(pos.x+48,pos.y-33);
        
        child.flip=((CCSprite*)[self.indexedBaseNodes objectAtIndex:targetIdx]).flipX;
        
        [child flipSprite];
        
//        NSLog(@"child flip? %@", child.flip? @"YES":@"NO");
        
        //todo set flipped here -- from FLIPPED NSNumber on the fnode dict
        
        
        //set artefact
        int artefactTargetIdx=[[[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"FEATURE_INDEX"] indexOfObject:[artefacts objectAtIndex:artefactIdx]];
        artefactIdx++;
        
        child.artefactSpriteBase=[self.indexedBaseNodes objectAtIndex:artefactTargetIdx];
        
        [gameWorld.Blackboard.debugDrawNode drawDot:child.artefactSpriteBase.position radius:15.0f color:ccc4f(1, 1, 0, 0.5f)];
        
        [child setupArtefactRender];
    }
    
    [self setupPlaneRender];
}

-(void)setupPlaneRender
{
    //only show them if enabeld for this mastery node / island
    if(!ParentGO.shouldShowPaperPlanes) return;
    
    for(SGJmapMasteryNode *othermn in ParentGO.EffectedPathDestinationNodes)
    {
        CGPoint path=[BLMath SubtractVector:ParentGO.Position from:othermn.Position];
        CGPoint startpos=[BLMath AddVector:ParentGO.Position toVector:[BLMath MultiplyVector:path byScalar:0.2f]];
        
        SGJmapPaperPlane *plane=[[[SGJmapPaperPlane alloc]initWithGameWorld:gameWorld andRenderLayer:gameWorld.Blackboard.RenderLayer andPosition:startpos andDestination:othermn.Position] autorelease];
        
        [plane setup];
        
        [gameWorld.Blackboard.debugDrawNode drawSegmentFrom:ParentGO.Position to:othermn.Position radius:5.0f color:ccc4f(1,1,1,0.3f)];
    }
}

-(void)readyIslandRender
{

    int shapeIndex=self.islandShapeIdx;
    
    if(shapeIndex==0)shapeIndex=1;
    
    NSString *baseSpriteName=[NSString stringWithFormat:@"Sand_%d_Yellow.png", shapeIndex];

    if(self.islandStage>2)
    {
        baseSpriteName=[NSString stringWithFormat:@"Sand_%d_Green.png", self.islandShapeIdx];
    }
    
    islandSprite=[CCSprite spriteWithSpriteFrameName:baseSpriteName];
    islandSprite.position=ParentGO.Position;
    islandSprite.visible=YES;
    [ParentGO.RenderBatch addChild:islandSprite z:-1];
    
    [gameWorld.Blackboard.debugDrawNode drawDot:ParentGO.Position radius:25.0f color:ccc4f(0, 0, 1, 0.25f)];
    
//    //draw the volcano / big hill
//    int vver=1+arc4random()%FEATURE_UNIQUE_VARIANTS;
//    NSString *vName=[NSString stringWithFormat:@"Feature_Stage%d_Size5_%d.png", self.islandStage, vver];
//    CCSprite *vol=[CCSprite spriteWithSpriteFrameName:vName];
//    //[vol setPosition:ccpAdd(ParentGO.Position, [[islandData objectForKey:ISLAND_MASTERY] CGPointValue])];
//    [vol setPosition:ccpAdd(ParentGO.Position, ccp(0,120))];
//    if(vver==3)vol.scale=0.7f;
//    [ParentGO.RenderBatch addChild:vol z:3];
//    [featureSprites addObject:vol];
//
//    //1st stage of hills -- stage 4
//    NSString *scatterName=[NSString stringWithFormat:@"Feature_Stage%d_Size4", self.islandStage];
//    [self scatterThing:scatterName withOffset:ccp(0, -0.25f) andScale:ccp(1.0f, 0.15f)];
//
//    
//    scatterName=[NSString stringWithFormat:@"Feature_Stage%d_Size3", self.islandStage];
//    [self scatterThing:scatterName withOffset:ccp(0, 0.75f) andScale:ccp(1.0f, 0.5f)];
    
//    if(ParentGO.PrereqPercentage==0)
//    {
//        //if bigger island (2/3+) draw volcano, pick from two
//        if(ParentGO.ChildNodes.count>0)
//        {
////            int vver=3; // the non lava volcano
////            if(ParentGO.ChildNodes.count>3) vver=1+arc4random()%2; //the lava volcanoes
//            
////            NSString *vName=[NSString stringWithFormat:@"volcano_%d.png", vver];
////            CCSprite *vol=[CCSprite spriteWithSpriteFrameName:vName];
////            //[vol setPosition:ccpAdd(ParentGO.Position, [[islandData objectForKey:ISLAND_MASTERY] CGPointValue])];
////            [vol setPosition:ccpAdd(ParentGO.Position, ccp(0,120))];
////            if(vver==3)vol.scale=0.7f;
////            [ParentGO.RenderBatch addChild:vol z:3];
////            [featureSprites addObject:vol];
//        }
//
//        //scatter black mountains
//        [self scatterThing1:@"hill_black" andThing2:@"hill_black" withRatio1:50 andRatio2:50];
//        
//        
//        //set island colour black-ish
//        islandSprite.color=ccc3(183,183,167);
//
//        
//    }
//    else if(ParentGO.PrereqPercentage<100)
//    {
//        //scatter black and green in proportion
//        [self scatterThing1:@"hill_black" andThing2:@"hill_green" withRatio1:100-ParentGO.PrereqPercentage andRatio2:ParentGO.PrereqPercentage];
//        
//        //set island colour sandy
//        islandSprite.color=ccc3(186,182,104);
//        
//    }
//    else //it's 100
//    {
//        //scatter green + trees
//        [self scatterThing1:@"hill_green" andThing2:@"tree" withRatio1:100-ParentGO.CompletePercentage andRatio2:ParentGO.CompletePercentage];
//        
//    }
}

-(void)createBaseNodes
{
    //step through the nodes for the selected island and position them, linking feature/artefact/node arrays to nodes
    self.indexedBaseNodes=nil;
    self.indexedBaseNodes=[[[NSMutableArray alloc] init] autorelease];
    
    for (NSDictionary *f in [[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"FEATURE_INDEX"])
    {
        CGPoint rawpos=[[f objectForKey:@"POS"] CGPointValue];
        
        CCSprite *basesprite=[CCSprite spriteWithSpriteFrameName:@"spacer.png"];
        
        
        basesprite.position=ccpAdd([self halvedSubCentre:rawpos], ParentGO.Position);
        [ParentGO.RenderBatch addChild:basesprite z:5];
        
        BOOL flip=[[f objectForKey:@"FLIPPED"] boolValue];
        basesprite.flipX=flip;
        
        [self.indexedBaseNodes addObject:basesprite];
        
        [gameWorld.Blackboard.debugDrawNode drawDot:basesprite.position radius:5.0f color:ccc4f(1, 0, 0, 0.5f)];
        
//        CCNode *node=[[CCNode alloc] init];
//        node.position=[self subCentre:rawpos];
//        [ParentGO.RenderBatch addChild:node z:5];
    }
    
}

-(void)transitionToNewState
{
    for(NSDictionary *f in [[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"FEATURES"])
    {
        //CGPoint pos=[self subCentre:[[f objectForKey:@"POS"] CGPointValue]];
        int size=[[f objectForKey:@"SIZE"] integerValue];
        //int variant=[[f objectForKey:@"VARIANT"] integerValue];
        int variant=(arc4random() %2) +1;
        
        int targetIdx=[[[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"FEATURE_INDEX"] indexOfObject:f];
        CCSprite *base=[self.indexedBaseNodes objectAtIndex:targetIdx];
        
        if(size>2 || self.islandStage<3)
        {
            float stdTime = arc4random() % 11 * 0.1;
            float actTime = 1.5f;
            
            
            NSString *fnamenew=[NSString stringWithFormat:@"Feature_Stage%d_Size%d_%d.png", self.islandStage, size, variant];
            
            [oldNodeSprite runAction:[CCFadeOut actionWithDuration:actTime/2]];
            
            CCSprite *newfsprite=[CCSprite spriteWithSpriteFrameName:fnamenew];
            
            newfsprite.position=ccp(newfsprite.contentSize.width / 2.0f, -newfsprite.contentSize.height / 2.0f);
            
            [base addChild:newfsprite];
            newfsprite.opacity=0;
            [newfsprite runAction:[CCFadeIn actionWithDuration:(stdTime/2)+actTime]];
            
            newfsprite.position=ccpAdd(base.position, ccp(0, -75));
        }
    }
    NSString *audio=[NSString stringWithFormat:@"/sfx/go/sfx_journey_map_map_progress_island_state_change_%d.wav", self.islandStage];
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(audio)];
    needToTransition=NO;
}

-(void)readyNodeSpriteRender
{
    //step over features, find and add to correct bases
    for(NSDictionary *f in [[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"FEATURES"])
    {
        //CGPoint pos=[self subCentre:[[f objectForKey:@"POS"] CGPointValue]];
        int size=[[f objectForKey:@"SIZE"] integerValue];
        //int variant=[[f objectForKey:@"VARIANT"] integerValue];
        int variant=(arc4random() %2) +1;
        
        int targetIdx=[[[gameWorld.Blackboard.islandData objectAtIndex:self.islandLayoutIdx] objectForKey:@"FEATURE_INDEX"] indexOfObject:f];
        CCSprite *base=[self.indexedBaseNodes objectAtIndex:targetIdx];
        
        if(size>2 || self.islandStage<3)
        {
//            NSString *fnamenew=[NSString stringWithFormat:@"Feature_Stage%d_Size%d_%d.png", self.islandStage, size, variant];
            NSString *fnameold=[NSString stringWithFormat:@"Feature_Stage%d_Size%d_%d.png", self.previousIslandStage, size, variant];
            
//            float stdTime = arc4random() % 11 * 0.1;
//            float actTime = 1.5f;
            
            //create random delay to go before all transitions
            //fade out needs to be 1.5s
            //fade in needs to be 1s, starting and 0.5s
            
            if(ParentGO.FreshlyCompleted && previousIslandStage!=islandStage)
                needToTransition=YES;
            
//            if(ParentGO.FreshlyCompleted && previousIslandStage!=islandStage)
//            {
                oldNodeSprite=[CCSprite spriteWithSpriteFrameName:fnameold];
                [base addChild:oldNodeSprite];
//
                oldNodeSprite.position=ccp(oldNodeSprite.contentSize.width / 2.0f, -oldNodeSprite.contentSize.height / 2.0f);
            
//                [oldNodeSprite runAction:[CCFadeOut actionWithDuration:stdTime+(actTime/2)]];
//            }
            
//            CCSprite *newfsprite=[CCSprite spriteWithSpriteFrameName:fnamenew];
//            [base addChild:newfsprite];
            
//            if(ParentGO.FreshlyCompleted && previousIslandStage!=islandStage)
//            {
//                newfsprite.opacity=0;
//                [newfsprite runAction:[CCFadeIn actionWithDuration:(stdTime/2)+actTime]];
//            }
//            
//            if(size==5 && self.islandStage>4)
//            {
//                newfsprite.position=ccpAdd(base.position, ccp(0, -75));
//            }
            
            // mod pos of old sprite if existing
            
            //sort irregular x offset
            base.position=ccpAdd(base.position, ccp(50,-25));

            
//            NSLog(@"island state -- prevIslandStage %d -- islandStage %d", previousIslandStage, islandStage);
            
            if(ParentGO.FreshlyCompleted)
            {
//                NSLog(@"is fresh! -- prevIslandStage %d -- islandStage %d", previousIslandStage, islandStage);
                
            }
            
        }
        
    }
    
    NSString *labelText=ParentGO.UserVisibleString;
    
    CGPoint labelCentre=ccpAdd(ccp(75, -125), ParentGO.Position);
    labelShadowSprite=[CCLabelTTF labelWithString:labelText fontName:@"Chango" fontSize:20.0f];
    [labelShadowSprite setPosition:ccpAdd(labelCentre, ccp(0, -3))];
    [labelShadowSprite setRotation:[[islandData objectForKey:ISLAND_LABEL_ROT] floatValue]];
    [labelShadowSprite setColor:ccc3(0, 0, 0)];
//    [labelShadowSprite setOpacity:0.2f*255];
    [labelShadowSprite setRotation:-8.0f];
    [labelShadowSprite setVisible:YES];
    
    if(ParentGO.Disabled) [labelShadowSprite setOpacity:100];
    [ParentGO.RenderBatch.parent addChild:labelShadowSprite z:3];
    labelSprite=[CCLabelTTF labelWithString:labelText fontName:@"Chango" fontSize:20.0f];
    [labelSprite setPosition:labelCentre];
    [labelSprite setRotation:[[islandData objectForKey:ISLAND_LABEL_ROT] floatValue]];
    [labelSprite setVisible:YES];
//    [labelSprite setOpacity:0.7f*255];
    [labelSprite setRotation:-8.0f];
    if(ParentGO.Disabled) [labelSprite setOpacity:100];
    [ParentGO.RenderBatch.parent addChild:labelSprite z:3];
    
}

#pragma mark - random feature placement / scatter & calculations


-(CGPoint) subCentre:(CGPoint)pos
{
    return([BLMath SubtractVector:ccp(FIXED_SIZE_X/2.0f, FIXED_SIZE_Y/2.0f) from:pos]);
}

-(CGPoint) halvedSubCentre:(CGPoint)pos
{
//    return ccpMult([self subCentre:pos], 1.0f);
    
    CGPoint sc=[self subCentre:pos];
    
    return sc;
//    return ccp(sc.x * 0.7f, sc.y * 0.5f);
}

#pragma mark - parse island data out of a single-island data template and cache

-(NSMutableDictionary*)loadIslandData:(NSString*)name
{
    NSMutableDictionary *buildData=[[[NSMutableDictionary alloc] init] autorelease];
    
    //load animation data
	//NSString *XMLPath=BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/jmap/islands/%@.svg", name]));
    
    NSString *XMLPath=BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/jmap/islands/island6-1.svg"]));
	
	//use that file to populate an NSData object
	NSData *XMLData=[NSData dataWithContentsOfFile:XMLPath];
	
	//get TouchXML doc
	CXMLDocument *doc=[[CXMLDocument alloc] initWithData:XMLData options:0 error:nil];
    
	//setup a namespace mapping for the svg namespace
	NSDictionary *nsMappings=[NSDictionary
							  dictionaryWithObject:@"http://www.w3.org/2000/svg"
							  forKey:@"svg"];
    
    
    //mastery position
    CXMLElement *masteryCircle=[[doc nodesForXPath:@"//svg:g[@id='data-mastery']/svg:circle" namespaceMappings:nsMappings error:nil] objectAtIndex:0];
    float rawMasteryX=[[[masteryCircle attributeForName:@"cx"] stringValue] floatValue];
    float rawMasteryY=[[[masteryCircle attributeForName:@"cy"] stringValue] floatValue];
    
    //    [buildData setValue:[BLMath BoxAndYFlipCGPoint:ccp(rawMasteryX, rawMasteryY) withMaxY:FIXED_SIZE_Y] forKey:ISLAND_MASTERY];
    
    [buildData setValue:[NSValue valueWithCGPoint:[self subCentre:ccp(rawMasteryX, FIXED_SIZE_Y-rawMasteryY)]] forKey:ISLAND_MASTERY];
    
    //node positions (array of boxed cgpoints)
    NSArray *nodes=[doc nodesForXPath:@"//svg:g[@id='data-nodes']/svg:circle" namespaceMappings:nsMappings error:nil];
    NSMutableArray *nodePoints=[[[NSMutableArray alloc] init] autorelease];
    for (CXMLElement *node in nodes) {
        float rawNodeX=[[[node attributeForName:@"cx"] stringValue] floatValue];
        float rawNodeY=[[[node attributeForName:@"cy"] stringValue] floatValue];
        [nodePoints addObject:[NSValue valueWithCGPoint:[self subCentre:ccp(rawNodeX, FIXED_SIZE_Y-rawNodeY)]]];
    }
    [buildData setValue:nodePoints forKey:ISLAND_NODES];
    
    NSArray *featureSpacesElements=[doc nodesForXPath:@"//svg:g[@id='data-features']/svg:circle" namespaceMappings:nsMappings error:nil];
    if(featureSpacesElements.count>0)
    {
        NSMutableArray *featureSpaces=[[[NSMutableArray alloc] init] autorelease];
        for(CXMLElement *fs in featureSpacesElements)
        {
            float rawFsX=[[[fs attributeForName:@"cx"] stringValue] floatValue];
            float rawFsY=[[[fs attributeForName:@"cy"] stringValue] floatValue];
            float radFs=[[[fs attributeForName:@"r"] stringValue] floatValue];
            NSMutableDictionary *fsData=[[[NSMutableDictionary alloc] init] autorelease];
            
            [fsData setValue:[NSValue valueWithCGPoint:[self subCentre:ccp(rawFsX, FIXED_SIZE_Y-rawFsY)]] forKey:ISLAND_POS];
            
            [fsData setValue:[NSNumber numberWithFloat:radFs] forKey:ISLAND_RADIUS];
            
            [featureSpaces addObject:fsData];
        }
        [buildData setValue:featureSpaces forKey:ISLAND_FEATURE_SPACES];
    }
    
    //label position and rotation
    CXMLElement *labelElement=[[doc nodesForXPath:@"//svg:g[@id='data-label']/svg:line" namespaceMappings:nsMappings error:nil] objectAtIndex:0];
    float x1=[[[labelElement attributeForName:@"x1"] stringValue] floatValue];
    float x2=[[[labelElement attributeForName:@"x2"] stringValue] floatValue];
    float y1=[[[labelElement attributeForName:@"y1"] stringValue] floatValue];
    float y2=[[[labelElement attributeForName:@"y2"] stringValue] floatValue];
    
    CGPoint l1=ccp(x1, FIXED_SIZE_Y-y1);
    CGPoint l2=ccp(x2, FIXED_SIZE_Y-y2);
    CGPoint lmid=[self subCentre:[BLMath MultiplyVector:ccpAdd(l1, l2) byScalar:0.5f]];
    float lrot=[BLMath angleForNormVector:[BLMath SubtractVector:l2 from:l1]];
    [buildData setValue:[NSValue valueWithCGPoint:lmid] forKey:ISLAND_LABEL_POS];
    [buildData setValue:[NSNumber numberWithFloat:lrot + 90] forKey:ISLAND_LABEL_ROT];
    
    //[doc release];
    
    return buildData;
}


#pragma mark - geometric/forced layout

-(void)readyRender
{
    
    sortedChildren=[[NSMutableArray alloc] init];
 
    float r=userCol.r + (userCol2.r - userCol.r) * (ParentGO.PrereqPercentage / 100.0f);
    float g=userCol.g + (userCol2.g - userCol.g) * (ParentGO.PrereqPercentage / 100.0f);
    float b=userCol.b + (userCol2.b - userCol.b) * (ParentGO.PrereqPercentage / 100.0f);
    currentCol=ccc4(r, g, b, 255);
    
    // ------- force points into bottom section of island ---------------------------------------------------
    
    //range of nodes is 140deg from 110 to 250 (direction doesn't matter here as they're sorted later)
    
    for(id<Transform>prnode in ParentGO.ChildNodes)
    {
        CGPoint diff=[BLMath SubtractVector:ParentGO.Position from:prnode.Position];
        float startAngle=[BLMath angleForVector:diff];
        float startLength=[BLMath LengthOfVector:diff];
        float angleInRange=startAngle * (140.0f / 360.0f) + 110.0f;
        CGPoint newPos=[BLMath AddVector:[BLMath ProjectMovementWithX:0 andY:startLength forRotation:angleInRange] toVector:ParentGO.Position];
        prnode.Position=newPos;
        
//        NSLog(@"parentGO.pos %@ prnode pos %@", NSStringFromCGPoint(ParentGO.Position), NSStringFromCGPoint(prnode.Position));
//        NSLog(@"diff is %@, startAngle %f, startLength %f, angleInRange %f, newPos %@", NSStringFromCGPoint(diff), startAngle, startLength, angleInRange, NSStringFromCGPoint(newPos));
    }
    
    // ------------------------------------------------------------------------------------------------------
    
    
    
    //sort children
    for (id<Transform> prnode in ParentGO.ChildNodes) {
        //NSLog(@"parentGO.pos %@ prnode pos %@", NSStringFromCGPoint(ParentGO.Position), NSStringFromCGPoint(prnode.Position));
        
        float thisA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:prnode.Position] toMaxLength:1.0f]];
        
        if([sortedChildren count]==0)
        {
            //put this thing in the array at first position
            [sortedChildren addObject:[NSValue valueWithCGPoint:prnode.Position]];
        }
        else {
            //iterate sorted array, looking for something larger (in rotation), or the end -- then insert
            
            for(int i=0; i<sortedChildren.count; i++)
            {
                int insertat=0;
                BOOL doInsert=NO;
                
                CGPoint snodePos=[[sortedChildren objectAtIndex:i] CGPointValue];
                
                float nextA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:snodePos] toMaxLength:1.0f]];
                
                if(nextA>thisA)
                {
                    doInsert=YES;
                    insertat=i; //insert before node
                }
                else if (i==sortedChildren.count-1)
                {
                    doInsert=YES;
                    insertat=sortedChildren.count; //insert at end of list
                }
                    
                if(doInsert)
                {
                    //insert the node itself
                    [sortedChildren insertObject:[NSValue valueWithCGPoint:prnode.Position] atIndex:insertat];
                    
                    break;

                }
            }
            
            //on insert, if increment from last is > 135, add an additional psuedo item
        }
    }
    
    if(sortedChildren.count==0)return;
    
    //insert top positions?

    float ildwidth= 30 + (2 * ParentGO.UserVisibleString.length);
    
    [sortedChildren insertObject:[NSValue valueWithCGPoint:[BLMath AddVector:ParentGO.Position toVector:ccp(-ildwidth, 10)]] atIndex:0];
//    [sortedChildren insertObject:[NSValue valueWithCGPoint:[BLMath AddVector:ParentGO.Position toVector:ccp(0, 10)]] atIndex:0];
    [sortedChildren insertObject:[NSValue valueWithCGPoint:[BLMath AddVector:ParentGO.Position toVector:ccp(ildwidth, 10)]] atIndex:0];
    
    //big spacers
    [self insertSpacerPointsWithRotGap:40.0f andScale:1.25f];
    
    //[self insertSpacerPointsWithRotGap:10.0f andScale:1.0f];
    
    //start smooth from avg
    float avgL=0.0f;
    for (NSValue *p in sortedChildren)
    {
        float l=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:[p CGPointValue]]];
        avgL+=l;
    }
    avgL=avgL / (float)sortedChildren.count;
    
    
    //now extend draw positions for those past avg
    for(int ip=0; ip<sortedChildren.count; ip++)
    {
        NSValue *p=[sortedChildren objectAtIndex:ip];
        CGPoint diff=[BLMath SubtractVector:ParentGO.Position from:[p CGPointValue]];
        float l=[BLMath LengthOfVector:diff];
        if(l>avgL)
        {
            //the point is past the average, multiply it's length (for the point) by the distance over the 
//            l = l/avgL;
            
            //add to that an amount
            CGPoint add=[BLMath ProjectMovementWithX:0 andY:50 forRotation:[BLMath angleForVector:diff]];
            
            CGPoint addedlocal=[BLMath AddVector:add toVector:diff];
            
            p=[NSValue valueWithCGPoint:[BLMath AddVector:ParentGO.Position toVector:addedlocal]];
            [sortedChildren replaceObjectAtIndex:ip withObject:p];
        }
    }
    

//    //start smooth from max
//    float avgL=0.0f;
//    for (NSValue *p in sortedChildren)
//    {
//        float l=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:[p CGPointValue]]];
//        if(l>avgL)avgL=l;
//    }
//    avgL=avgL*1.25f;
//    //avgL=avgL / (float)sortedChildren.count;
    
    
    float seekr=110.0f;
    
    NSMutableArray *newChildren=[[NSMutableArray alloc] init];
    for(int r=0; r<360; r+=2)
    {
        float newL=avgL;
        
        //look for close rotations and adjust
        for (NSValue *p in sortedChildren)
        {
            CGPoint inspd=[BLMath SubtractVector:ParentGO.Position from:[p CGPointValue]];
            float inspr=[BLMath angleForVector:inspd];
            
            float rdiff=fabsf(inspr-r);
            if(inspr<seekr && r>(360-seekr)) rdiff=fabsf((inspr+360) - r);
            if(r<seekr && inspr>(360-seekr)) rdiff=fabsf(inspr - (360+r));

            if(rdiff<seekr)
            {
                float inspl=[BLMath LengthOfVector:inspd];
                
                float mult=((seekr-rdiff) / seekr);
                mult *= mult;
                
                newL=newL+((inspl-newL) * mult);
            }
        }
        
        CGPoint pos=[BLMath AddVector:ParentGO.Position toVector:[BLMath ProjectMovementWithX:0 andY:newL forRotation:r]];
        [newChildren addObject:[NSValue valueWithCGPoint:pos]];
    }
    
    [sortedChildren release];
    sortedChildren=newChildren;
    
    
    //================ calculate interior polys for drop shadow =============================
    //perim points
    CGPoint perimPoints[sortedChildren.count];
    CGPoint myWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
    int perimIx=0;
    
    //CGPoint offsetForTexture=[BLMath SubtractVector:myWorldPos from:ParentGO.Position];

    for (NSValue *cPosVal in sortedChildren) {
        //world space pos of child node
        CGPoint theirWorldPos=[ParentGO.RenderBatch.parent convertToWorldSpace:[cPosVal CGPointValue]];
        
        //add to perim
        //get vector from here to there
        CGPoint vdiff=[BLMath SubtractVector:myWorldPos from:theirWorldPos];
        CGPoint ediff=[BLMath MultiplyVector:vdiff byScalar:1.5f];
        //CGPoint dest=[BLMath AddVector:ediff toVector:myWorldPos];
        
        perimPoints[perimIx]=ediff;
        perimIx++;
    }
    
    //get avg position of points
    float xmean=0.0f;
    float ymean=0.0f;
    for(int i=0; i<sortedChildren.count; i++)
    {
        xmean+=perimPoints[i].x;
        ymean+=perimPoints[i].y;
    }
    xmean=xmean/(float)sortedChildren.count;
    ymean=ymean/(float)sortedChildren.count;
    CGPoint pmid=ccp(xmean,ymean);

    // === stepping colour creation -- not used currently due to fixed colouring of islands ===
//    ccColor4B stepColour=currentCol;
//    stepColour.r=stepColour.r-5;
//    stepColour.g=stepColour.g-5;
//    stepColour.b=stepColour.b-10;
//    if(stepColour.r>currentCol.r)stepColour.r=0;
//    if(stepColour.g>currentCol.g)stepColour.g=0;
//    if(stepColour.b>currentCol.b)stepColour.b=0;
//    
//    //step the colours
//    for(int i=0; i<shadowSteps; i++)
//    {
//        stepColours[i]=stepColour;
//        
//        //adjust colour
//        if(stepColour.r<252) stepColour.r+=3.5f;
//        if(stepColour.g<252) stepColour.g+=3.5f;
//        if(stepColour.b<252) stepColour.b+=7;
//    }
    // =========================================================================================
    
    //create the total perim array -- polys * points
    allPerimPoints=malloc(sizeof(CGPoint) * shadowSteps * sortedChildren.count);
    scaledPerimPoints=malloc(sizeof(CGPoint) * shadowSteps * sortedChildren.count);
    
    texturePoints=[[NSMutableArray alloc] init];
    
    //step the poly creation
    for(int ip=0; ip<shadowSteps; ip++)
    {
        for(int i=0; i<sortedChildren.count; i++)
        {
            CGPoint diff=[BLMath SubtractVector:pmid from:perimPoints[i]];
            
            CGPoint neardiff=CGPointZero;
            if(ip<3) // first two blue bands + the dark blue band
                neardiff=[BLMath MultiplyVector:diff byScalar:(1-(0.04 * (ip+1)))];
            if(ip==3) // the sand band
            {
                neardiff=[BLMath MultiplyVector:diff byScalar:(1-(0.042 * (ip)))];
                neardiff=CGPointMake(neardiff.x-2, neardiff.y-6);
            }
            if(ip==4) // the grass
            {
                neardiff=[BLMath MultiplyVector:diff byScalar:(1-(0.043 * (ip-1)))];
                neardiff=CGPointMake(neardiff.x-1, neardiff.y+1);
            }
            
            
            //CGPoint neardiff=diff; //don't scale -- just offset it
            
            CGPoint aPos=[BLMath AddVector:neardiff toVector:pmid];
            //CGPoint prelPos=[BLMath SubtractVector:ParentGO.Position from:aPos];
            
            //also offset the thing
            //aPos=[BLMath AddVector:ccp(5, 5) toVector:aPos];
            
            CGPoint newpos=aPos;
            
            int insertChildPos=ip*sortedChildren.count;
            if(ip>0)insertChildPos-=1;
            
            int actualinsert=insertChildPos+i;
            
            //NSLog(@"inserting at %d", actualinsert);
            allPerimPoints[actualinsert]=newpos;
            
            if(ip==4)
            {
                //newpos is point on this poly -- adjusted to what? * see the draw code
                
                CGPoint offp=[BLMath AddVector:newpos toVector:ParentGO.Position];
                [texturePoints addObject:[NSValue valueWithCGPoint:offp]];
            }
            
            //allPerimPoints[(ip==0 ? 0 : ((ip*shadowSteps)-1))+i]=newpos;
        }
    }
    
    //=======================================================================================
    
    [self setPointScalesAt:1.0f];
}

- (void)insertSpacerPointsWithRotGap:(float)rotGap andScale:(float)scale
{
    //iterate over sorted children repeatedly until we can't add any more spacers
    BOOL looking=YES;
    do {
        for (int i=0; i<sortedChildren.count; i++) {
            CGPoint thisP=[[sortedChildren objectAtIndex:i] CGPointValue];
            float thisA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:thisP] toMaxLength:1.0f]];
            
            CGPoint nextP;
            float nextA;
            if (i==sortedChildren.count-1) {
                //at end node, use position of first
                nextP=[[sortedChildren objectAtIndex:0] CGPointValue];
                nextA=360.0f + [BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:nextP] toMaxLength:1.0f]];
            }
            else {
                nextP=[[sortedChildren objectAtIndex:i+1] CGPointValue];
                nextA=[BLMath angleForNormVector:[BLMath TruncateVector:[BLMath SubtractVector:ParentGO.Position from:nextP] toMaxLength:1.0f]];
            }
            
            if((nextA-thisA) > rotGap)
            {
                float lOfThisV=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:thisP]];
                float lOfNextV=[BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:nextP]];
                
                float rotOffset=0.5f;
                float lOfV=(lOfThisV * rotOffset) + (lOfNextV * (1-rotOffset));
                
                lOfV=lOfV * scale;
                
                //float lOfV=scale * [BLMath LengthOfVector:[BLMath SubtractVector:ParentGO.Position from:thisP]];
                
                float newrot=thisA + ((nextA-thisA)*0.35f);
                //float newrot=thisA+ 50.0f;
                
                CGPoint newpos=[BLMath AddVector:ParentGO.Position toVector:[BLMath ProjectMovementWithX:0 andY:lOfV forRotation:newrot]];
                
                if(newrot>=360.0f)
                {
                    [sortedChildren insertObject:[NSValue valueWithCGPoint:newpos] atIndex:0];
                }
                else {
                    [sortedChildren insertObject:[NSValue valueWithCGPoint:newpos] atIndex:i+1];
                }
                
                break;
            }
            
            //if we got to the last node and didn't add a spacer and break, stop looking for new spacer requirements
            if(i==sortedChildren.count-1)
            {
                looking=NO;
            }
        }
    } while (looking);
}

-(void)setPointScalesAt:(float)scale
{
    for(int i=0;i<(sortedChildren.count * shadowSteps); i++)
    {
        scaledPerimPoints[i]=[BLMath MultiplyVector:allPerimPoints[i] byScalar:scale];
    }
}


@end


#pragma mark - MasteryDrawNode implementation

@implementation MasteryDrawNode

-(MasteryDrawNode*)initWithParent:(SGJmapMasteryNodeRender*)masteryNodeRender;
{
    if(self=[super init])
    {
        renderParent=masteryNodeRender;
    }
    return self;
}

-(void) draw
{
    //disabled in leui of island sprite
    return;
    
//    CGPoint myWorldPos=[renderParent.ParentGO.RenderBatch.parent convertToWorldSpace:renderParent.ParentGO.Position];

    CGPoint myWorldPos=renderParent.ParentGO.Position;
    
    //upate position of all polys
    CGPoint adjPoints[shadowSteps*renderParent.sortedChildren.count];
    for (int i=0; i<(shadowSteps*renderParent.sortedChildren.count); i++) {
        adjPoints[i]=[BLMath AddVector:myWorldPos toVector:renderParent.scaledPerimPoints[i]];
    }
    
    //perim polys -- overlapping
    for(int ip=0; ip<shadowSteps; ip++)
    {
//        CGPoint *first=&adjPoints[(ip==0) ? 0 : (ip*renderParent.sortedChildren.count)-1];
        
        //ccColor4F col=ccc4FFromccc4B(stepColours[ip]);

        //opacity-based were white, 0.15f
        //ccColor4F col=ccc4f(1.0f, 1.0f, 1.0f, 0.15f);
        
        ccColor4F col=ccc4f(0.343f, 0.520f, 0.641, 1.0f);
        if (ip==1) col=ccc4f(0.402f, 0.563f, 0.676f, 1.0f);
        
        if (ip==2) col=ccc4f(0.220f, 0.373f, 0.471f, 1.0f);
        if (ip==3) col=ccc4f(0.851f, 0.780f, 0.624f, 1.0f);
        if (ip==4) col=ccc4f(0.451f, 0.608f, 0.259f, 1.0f);
        
        //if(renderParent.zoomedOut) col=ccc4f(col.r, col.g, col.b, 0.3f);
        
        //todo: not doing with cocos2.1 -- needs replacing with CCDrawNode
        //ccDrawFilledPoly(first, renderParent.sortedChildren.count, col);
    }

    
    // ======= mastery > node lines -- not currently used ===============================
    
//    if(!renderParent.zoomedOut)
//    {
//        for (id<Transform> prnode in renderParent.ParentGO.ChildNodes) {
//            //world space pos of child node
//            CGPoint theirWorldPos=[renderParent.ParentGO.RenderBatch.parent convertToWorldSpace:prnode.Position];
//            
//            //draw prereq path to this node
//            ccDrawColor4B(userHighCol.r, userHighCol.g, userHighCol.b, userHighCol.a);
//            ccDrawLine(myWorldPos, theirWorldPos);
//        }
//    }
    
    // ==================================================================================
}

@end
