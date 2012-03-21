//
//  MenuScene.m
//  belugapad
//
//  Created by Gareth Jenkins on 04/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MenuScene.h"
#import "global.h"
#import "BLMath.h"
#import "ZubiIntro.h"
#import "ContentService.h"
#import "Syllabus.h"
#import "Topic.h"
#import "Module.h"
#import "Element.h"
#import "AppDelegate.h"

#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>
#import <CouchCocoa/CouchTouchDBServer.h>
#import <TouchDB/TouchDB.h>

const float kPropXPinchThreshold=0.08f;
const float kPropXSwipeModuleThreshold=0.15f;
const float kPropYSwipeTopicThreshold=0.2f;
const float kPinchScaleMin=0.05;

const float kPropYTopicGap=0.6f;
const float kPropXModuleGap=0.35f;

const ccColor3B kMenuLabelTitleColor={255, 255, 255};
const GLubyte kMenuLabelOpacity=120;
const float kPropXMenuLabelFontSize=0.08f;

const float kMenuSnapTime=0.15f;
const float kMenuSnapRate=0.5f;

const float kDragEffectX=0.5f;
const float kDragEffectY=0.5f;

const float kPropXTapReleaseProximity=0.01f;
const float kPropXTapModuleRadius=0.1f;

const float kMenuScaleTime=0.5f;
const float kMenuModuleScale=0.25f;
const float kMenuModuleScaleRate=0.5f;

const float kTimeTapMax=0.2f;

//effectively may as well be redefined -- should sit in a global
const float kMenuScheduleUpdateDoUpdate=60.0f;

//temporary -- for elegeo sprite placeholder
const float kOpacityElementGeo=75;

const CGPoint kPropXBackBtnPos={0.06, -0.06};
const float kPropXBackBtnHitRadius=40;

const float kPropXHitNextMenu=0.9f;
const float kPropYHitNextMenu=0.9f;

@implementation MenuScene

+(CCScene *)scene
{
    CCScene *scene=[CCScene node];
    
    MenuScene *layer=[MenuScene node];
    
    [scene addChild:layer];
    
    return scene;
}

-(id)init
{
    if(self=[super init])
    {
        self.isTouchEnabled=YES;
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        
        MenuState=kMenuStateTopic;
        
        contentService = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).contentService;
        
        //load this from module data        
        //moduleCount=5;
        topicCount=[contentService.defaultSyllabus.topics count];
        
        [self setupBackground];
        
        [self setupMap];
        
        [self setupUI];
        
        [self schedule:@selector(doUpdate:) interval:1.0f/kMenuScheduleUpdateDoUpdate];
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    timeSinceTap+=delta;
}

-(void)setupBackground
{
    CCSprite *bkg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/bg/bg-ipad.png")];
    [bkg setPosition:ccp(cx, cy)];
    [self addChild:bkg];
    
}

-(void)setupUI
{
    moduleViewUI=[[CCLayer alloc] init];
    [self addChild:moduleViewUI];
    [moduleViewUI setVisible:NO];
    
    CCSprite *backBtn=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/backbtn.png")];
    [moduleViewUI addChild:backBtn];
    [backBtn setPosition:[BLMath AddVector:ccp(0, ly) toVector:[BLMath MultiplyVector:kPropXBackBtnPos byScalar:lx]]];

}

-(void)setupMap
{
    topicLayerBase=[[CCLayer alloc]init];
    [self addChild:topicLayerBase];
    
    topicLayers=[[NSMutableArray alloc] init];
    moduleBaseLayers=[[NSMutableArray alloc]init];
    moduleLayers=[[NSMutableArray alloc]init];
    modulePositions=[[NSMutableArray alloc]init];
    
    moduleObjects=[[NSMutableArray alloc] init];
    
    NSArray *topicIDs=contentService.defaultSyllabus.topics;
    
    for (int t=0; t<[topicIDs count]; t++) {
        
        Topic *topic=[[CouchModelFactory sharedInstance] modelForDocument:[[contentService Database] documentWithID:[topicIDs objectAtIndex:t]]];
        
        NSLog(@"topic name: %@", topic.name);
        
        CCLayer *thisTopic=[[[CCLayer alloc] init] autorelease];
        [thisTopic setPosition:ccp(0, -(t*(kPropYTopicGap*ly)))];
        [topicLayers addObject:thisTopic];
        [topicLayerBase addChild:thisTopic];
        
        //create module base layer on topic
        CCLayer *modBase=[[[CCLayer alloc] init] autorelease];
        [thisTopic addChild:modBase];
        [moduleBaseLayers addObject:modBase];
        
        //create holder array for module layers themselves
        NSMutableArray *layersForThisTopic=[[[NSMutableArray alloc] init] autorelease];
        [moduleLayers addObject:layersForThisTopic];
        
        NSMutableArray *objectsForThisTopic=[[[NSMutableArray alloc] init] autorelease];
        [moduleObjects addObject:objectsForThisTopic];
        
        //set the module position for this topic
        [modulePositions addObject:[NSNumber numberWithInt:0]];
        
        NSArray *moduleIDs=topic.modules;
        
        for(int m=0; m<[moduleIDs count]; m++)
        {
            Module *module=[[CouchModelFactory sharedInstance] modelForDocument:[[contentService Database] documentWithID:[moduleIDs objectAtIndex:m]]];
            
            //create module 
            CCLayer *moduleLayer=[[[CCLayer alloc] init] autorelease];
            [layersForThisTopic addObject:moduleLayer];
            [modBase addChild:moduleLayer];
            
            [objectsForThisTopic addObject:module];
            
            [moduleLayer setPosition:ccp(m * (kPropXModuleGap * lx), 0)];
            [moduleLayer setScale:kMenuModuleScale];
            
            //render elements
            NSArray *elementIDs=module.elements;
            //float xOffsetCentre=-(([elementIDs count]-1)*200) / 2.0f;
            //float xOffsetCentre=0;
            
            for(int e=0; e<[elementIDs count]; e++)
            {                
                //create module/topc element view
                CCSprite *elegeo=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/ElementView/Menu_E_C_S.png")];
                
                float offsetX=-(((int)[elementIDs count]-1) * 100);
                
                [elegeo setPosition:ccp(cx + (e*200) + offsetX, cy)];
                [elegeo setOpacity:255];
                [moduleLayer addChild:elegeo];
            }
            
            //create module/topic label
            CCLabelTTF *tlabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"M%@", module.name] fontName:GENERIC_FONT fontSize:(kPropXMenuLabelFontSize*lx)];
            [tlabel setPosition:ccp(cx, cy-200)];
            [tlabel setColor:kMenuLabelTitleColor];
            [tlabel setOpacity:kMenuLabelOpacity];
            [moduleLayer addChild:tlabel];
        }
    }
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouchDown=YES;
    timeSinceTap=0.0f;
    
    //THIS WILL NOT GATE -- only here to load in out in belugapad
    UITouch *t=[touches anyObject];
    CGPoint l=[[CCDirector sharedDirector] convertToGL:[t locationInView:t.view]];
    if(l.x>(kPropXHitNextMenu * lx) && l.y>(kPropYHitNextMenu * ly))
    {
        [[CCDirector sharedDirector] replaceScene:[ZubiIntro scene]];
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // module menu ignores touch motion

    if([touches count]>1)
    {
        isMultiTouchMove=YES;
        
        UITouch *t1=[[touches allObjects] objectAtIndex:0];
        UITouch *t2=[[touches allObjects] objectAtIndex:1];
        
        CGPoint t1a=[[CCDirector sharedDirector] convertToGL:[t1 previousLocationInView:t1.view]];
        CGPoint t1b=[[CCDirector sharedDirector] convertToGL:[t1 locationInView:t1.view]];
        CGPoint t2a=[[CCDirector sharedDirector] convertToGL:[t2 previousLocationInView:t2.view]];
        CGPoint t2b=[[CCDirector sharedDirector] convertToGL:[t2 locationInView:t2.view]];
        
        float da=[BLMath DistanceBetween:t1a and:t2a];
        float db=[BLMath DistanceBetween:t1b and:t2b];
        
        float scaleChange=db-da;
        
        [self pinchMovementBy:scaleChange];
        
        touchPinchMovement+=scaleChange;
        
    }
    else
    {
        if(MenuState==kMenuStateTopic)
        {
            UITouch *touch=[touches anyObject];
            
            //only tracking if one touch, so accumulating this is okay
            CGPoint a = [[CCDirector sharedDirector] convertToGL:[touch previousLocationInView:touch.view]];
            CGPoint b = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
            
            float diffx=b.x-a.x;
            float diffy=b.y-a.y;
            
            diffx=diffx*kDragEffectX;
            diffy=diffy*kDragEffectY;
            
            //rotate orbit
            [self rotateOrbitByLinearX:diffx];
            
            //move topic
            [self moveTopicPositionByLinearY:diffy];
            
            //track total movement
            touchXMovement+=diffx;  
            touchYMovement+=diffy;
        }
        
    }

    
}

-(void)rotateOrbitByLinearX:(float)moveByX
{
    if(MenuState==kMenuStateTopic)
    {
        CCLayer *layerBase=[moduleBaseLayers objectAtIndex:topicPosition];
        CGPoint pos=[layerBase position];
        pos=ccp(pos.x + moveByX, pos.y);
        [layerBase setPosition:pos];
    }
}

-(void)moveTopicPositionByLinearY:(float)moveByY
{    
    if(MenuState==kMenuStateTopic)
    {
        CGPoint pos=[topicLayerBase position];
        pos=ccp(pos.x, pos.y+moveByY);
        [topicLayerBase setPosition:pos];
    }
}

-(void)pinchMovementBy:(float)pinchBy
{
    //DLog(@"pinchMovementBy");
    
    float pinchProp=pinchBy / cy;
    float scaleChange=kMenuModuleScale * pinchProp;
    
    int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];
    CCLayer *currentModule=[[moduleLayers objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    float newScale=[currentModule scale] + scaleChange;
    
    if(newScale>kPinchScaleMin)
        [currentModule setScale:newScale];
    
}

-(void)snapToYSwipe
{    
    //snap by remainder of movement to next topic (including overrun)
    float desiredTopicBaseOffset=topicPosition*-(kPropYTopicGap*ly);
    float moveBy=desiredTopicBaseOffset+(topicLayerBase.position.y);
    
    //todo: easein
    [topicLayerBase runAction:[CCEaseIn actionWithAction:[CCMoveBy actionWithDuration:kMenuSnapTime position:ccp(0, -moveBy)] rate:kMenuSnapRate]];    
    
}

-(void)snapToXSwipe
{
    //reset for every topic layer -- as a side swipe on the previous layer needs to snap back if the transition is topic-topic (overriding the module-module transition)
    
    for (int it=0; it<topicCount; it++) {
        int modulePosition=[[modulePositions objectAtIndex:it] intValue];
        
        float desiredOffset=modulePosition * (kPropXModuleGap * lx);
        CCLayer *layerBase=[moduleBaseLayers objectAtIndex:it];
        float moveBy=desiredOffset + (layerBase.position.x);
        
        [layerBase runAction:[CCEaseIn actionWithAction:[CCMoveBy actionWithDuration:kMenuSnapTime position:ccp(-moveBy, 0)] rate:kMenuSnapRate]];   
            
    }
    
}

-(void)resetPinch
{
    int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];
    
    //bail if before or after modules
    if (modulePosition<0 || modulePosition>=[[moduleLayers objectAtIndex:topicPosition] count]) return;
    
    CCLayer *currentModule=[[moduleLayers objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    if(MenuState==kMenuStateTopic) [currentModule setScale:kMenuModuleScale];
    if(MenuState==kMenuStateModule) [currentModule setScale:1.0f];
}

-(void)snapToModuleView
{
    int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];
    CCLayer *currentModule=[[moduleLayers objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    Module *module=[[moduleObjects objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    [currentModule runAction:[CCEaseIn actionWithAction:[CCScaleTo actionWithDuration:kMenuScaleTime scale:1.0f] rate:kMenuModuleScaleRate]];
    
    //semi-hide all other elements
    [self setAllModuleOpacityTo:0.0f exceptFor:currentModule];
    
    //show element view
    [self showModuleOverlay:module];
    
    [moduleViewUI setVisible:YES];
}

-(void)showModuleOverlay: (Module*)module
{
    NSLog(@"module: %@", module.name);
}

-(void)hideModuleOverlay
{
    NSLog(@"hide module view");
}

-(void)pressedPlayButton
{
    
}

-(void)snapToTopicView
{
    int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];
    CCLayer *currentModule=[[moduleLayers objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    [currentModule runAction:[CCEaseIn actionWithAction:[CCScaleTo actionWithDuration:kMenuScaleTime scale:kMenuModuleScale] rate:kMenuModuleScaleRate]];    
    
    [self setAllModuleOpacityTo:1.0f exceptFor:currentModule];
    
    [moduleViewUI setVisible:NO];
}

-(void)setAllModuleOpacityTo:(float)newOpacity exceptFor:(CCLayer*)activeModule
{
    for (NSMutableArray *mn in moduleLayers) {
        for(CCLayer *ml in mn)
        {
            if(ml!=activeModule)
            {
                if(newOpacity<1.0f) [ml setVisible:NO];
                else [ml setVisible:YES];
            }
        }
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[touches anyObject];
    CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:touch.view]];
    
    if(MenuState==kMenuStateTopic)
    {
        float distanceToCentre=[BLMath DistanceBetween:location and:ccp(cx, cy)];
        
        //test for tap on module with acceptable bounds
        if(!isMultiTouchMove && touchXMovement < (lx*kPropXTapReleaseProximity) && touchYMovement<(lx*kPropXTapReleaseProximity)
           && distanceToCentre < (kPropXTapModuleRadius*lx) && timeSinceTap<=kTimeTapMax)
        {
            MenuState=kMenuStateModule;
            
            [self snapToModuleView];
        }
        
        //test for pinch past bound
        else if(touchPinchMovement>(lx*kPropXPinchThreshold))
        {
            MenuState=kMenuStateModule;

            [self snapToModuleView];

        }

        //topic change up
        else if (topicPosition < (topicCount-1) && touchYMovement >= (kPropYSwipeTopicThreshold*ly))
        {
            topicPosition++;
            
        }

        //topic change down
        else if (topicPosition>0 && touchYMovement <= -(kPropYSwipeTopicThreshold*ly))
        {
            topicPosition--;
            
        }
        
        //module change up
        else if (touchXMovement <= -(kPropXSwipeModuleThreshold*lx))
        {
            int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];
            
            if(modulePosition==(moduleCount-1)) modulePosition=0;
            else modulePosition++;
            
            [modulePositions replaceObjectAtIndex:topicPosition withObject:[NSNumber numberWithInt:modulePosition]];
            
        }
        
        //module change down
        else if (touchXMovement >= (kPropXSwipeModuleThreshold*lx))
        {
            int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];

            if(modulePosition==0)modulePosition=moduleCount-1;
            else modulePosition--;
            
            [modulePositions replaceObjectAtIndex:topicPosition withObject:[NSNumber numberWithInt:modulePosition]];
        }
        
    }
    
    else if(MenuState==kMenuStateModule)
    {
        if([BLMath DistanceBetween:location and:[BLMath AddVector:ccp(0, ly) toVector:[BLMath MultiplyVector:kPropXBackBtnPos byScalar:lx]]] < kPropXBackBtnHitRadius)
        {
            MenuState=kMenuStateTopic;
            
            [self hideModuleOverlay];
            
            [self snapToTopicView];            
        }
        
        else if(touchPinchMovement<= -(kPropXPinchThreshold * lx))
        {
            MenuState=kMenuStateTopic;
            
            [self hideModuleOverlay];
            
            [self snapToTopicView];
        }
        
        //tofu touch here for play button press -- call pressMenuButton
    }

    [self snapToXSwipe];
    [self snapToYSwipe];
    [self resetPinch];
    
    DLog(@"state is %d with topic %d and module %d", MenuState, topicPosition, [[modulePositions objectAtIndex:topicPosition] intValue]);
    
    isTouchDown=NO;
    isMultiTouchMove=NO;
    touchXMovement=0.0f;
    touchPinchMovement=0.0f;
    touchYMovement=0.0f;
}

-(void) dealloc
{
    [topicLayerBase release];
    [topicLayers release];
    [moduleBaseLayers release];
    [moduleLayers release];
    
    [super dealloc];
}

@end
