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
#import "ToolHost.h"
#import "SimpleAudioEngine.h"
#import "User.h"
#import "UsersService.h"

#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>

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

const CGPoint kPropXBackBtnPos={0.39, -0.06};
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
        
        [self buildModuleOverlay];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:BUNDLE_FULL_PATH(@"/sfx/mood.mp3") loop:YES];
        
    }
    
    return self;
}

-(void)doUpdate:(ccTime)delta
{
    timeSinceTap+=delta;
}

-(void)setupBackground
{
    CCSprite *bkg=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/bg/archive_bg-ipad.png")];
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
    elementObjects=[[NSMutableArray alloc] init];
    
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
        
        NSMutableArray *elementModulesForThisTopic=[[[NSMutableArray alloc] init] autorelease];
        [elementObjects addObject:elementModulesForThisTopic];
        
        //set the module position for this topic
        [modulePositions addObject:[NSNumber numberWithInt:0]];
        
        
        //topic name
        CCLabelTTF *tnamelabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@", topic.name] fontName:GENERIC_FONT fontSize:(kPropXMenuLabelFontSize*0.6*lx)];
        [tnamelabel setPosition:ccp(200, cy)];
        [tnamelabel setColor:kMenuLabelTitleColor];
        [tnamelabel setOpacity:kMenuLabelOpacity];
        [modBase addChild:tnamelabel];
        
        if(!topicLabelLast)
        {
            topicLabelLast=tnamelabel;
        }
        
        NSArray *moduleIDs=topic.modules;
        
        for(int m=0; m<[moduleIDs count] && m<2; m++)
        {
            Module *module=[[CouchModelFactory sharedInstance] modelForDocument:[[contentService Database] documentWithID:[moduleIDs objectAtIndex:m]]];
            
            //create module 
            CCLayer *moduleLayer=[[[CCLayer alloc] init] autorelease];
            [layersForThisTopic addObject:moduleLayer];
            [modBase addChild:moduleLayer];
            
            [objectsForThisTopic addObject:module];
            
            NSMutableArray *elementsForThisModule=[[[NSMutableArray alloc] init] autorelease];
            [elementModulesForThisTopic addObject:elementsForThisModule];
            
            [moduleLayer setPosition:ccp(m * (kPropXModuleGap * lx), 0)];
            [moduleLayer setScale:kMenuModuleScale];
            
            //render elements
            NSArray *elementIDs=module.elements;
            //float xOffsetCentre=-(([elementIDs count]-1)*200) / 2.0f;
            //float xOffsetCentre=0;
            
            for(int e=0; e<[elementIDs count]; e++)
            {                
                Element *element=[[CouchModelFactory sharedInstance] modelForDocument:[[contentService Database] documentWithID:[elementIDs objectAtIndex:e]]];
                
                [elementsForThisModule addObject:element];
                
                //create module/topc element view
//                CCSprite *elegeo=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/elementview/acirc.png")];
                
                CCSprite *elegeo=[CCSprite spriteWithFile:@"acirc.png"];
                
                float offsetX=-(((int)[elementIDs count]-1) * 100);
                
                [elegeo setPosition:ccp(cx + (e*200) + offsetX, cy)];
                [elegeo setOpacity:255];
                [moduleLayer addChild:elegeo];
            }
            
            //create module/topic label
            CCLabelTTF *tlabel=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@", module.name] fontName:GENERIC_FONT fontSize:(kPropXMenuLabelFontSize*lx)];
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
            //TOFU -- disabled for sprint demo
            //[self moveTopicPositionByLinearY:diffy];
            
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
    
    if(modulePosition<0 || (modulePosition >= [[moduleLayers objectAtIndex:topicPosition] count]))
    {
        MenuState=kMenuStateTopic;
        return;
    }
    

    CCLayer *currentModule=[[moduleLayers objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    Module *module=[[moduleObjects objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    [currentModule runAction:[CCEaseIn actionWithAction:[CCScaleTo actionWithDuration:kMenuScaleTime scale:1.0f] rate:kMenuModuleScaleRate]];
    
    [currentModule runAction:[CCMoveBy actionWithDuration:kMenuScaleTime position:ccp(150,0)]];
    
    //semi-hide all other elements
    [self setAllModuleOpacityTo:0.0f exceptFor:currentModule];
    
    //show element view
    [self showModuleOverlay:module];
    
    [moduleViewUI setVisible:YES];
}

-(void)buildModuleOverlay
{
    eMenu = [[CCLayer alloc]init];
    [self addChild:eMenu];
    [eMenu setVisible:NO];
    
    eMenuLeftOlay = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/ElementView/Menu_LeftPanelStatic.png")];
    eMenuLeftPlayBtn = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/ElementView/PlayButton.png")];
    eMenuLeftClock = [CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/ElementView/Menu_E_Clock.png")];

    eMenuPlayerName = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(283.0f,40.0f) alignment:UITextAlignmentLeft fontName:GENERIC_FONT fontSize:50.0f];
    eMenuTotExp = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(213.0f,45.0f) alignment:UITextAlignmentLeft fontName:GENERIC_FONT fontSize:42.0f];
    
    eMenuTotTime = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(213.0f,45.0f) alignment:UITextAlignmentLeft fontName:GENERIC_FONT fontSize:42.0f];
    eMenuModName = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(289.0f,45.0f) alignment:UITextAlignmentLeft fontName:GENERIC_FONT fontSize:45.0f];
    eMenuModDesc = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(289.0f,45.0f) alignment:UITextAlignmentLeft fontName:GENERIC_FONT fontSize:30.0f];
    eMenuModStatus = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(289.0f,45.0f) alignment:UITextAlignmentLeft fontName:GENERIC_FONT fontSize:25.0f];
    eMenuModTime = [CCLabelTTF labelWithString:@"" dimensions:CGSizeMake(246.0f,26.0f) alignment:UITextAlignmentLeft fontName:GENERIC_FONT fontSize:26.0f];
    
    [eMenuLeftOlay setPosition:ccp(168,384)];
    [eMenuPlayerName setPosition:ccp(198,684)];
    [eMenuLeftClock setPosition:ccp(60,310)];
    [eMenuLeftPlayBtn setPosition:ccp(162,51)];
    [eMenuTotExp setPosition:ccp(228,610)];
    [eMenuTotTime setPosition:ccp(228,543)];
    [eMenuModName setPosition:ccp(190,454)];
    [eMenuModDesc setPosition:ccp(190,399)];
    [eMenuModStatus setPosition:ccp(190,354)];
    [eMenuModTime setPosition:ccp(211,308)];
    
    [eMenuTotExp setColor:ccc3(89, 133, 136)];
    [eMenuModName setColor:ccc3(45, 97, 130)];
    [eMenuModDesc setColor:ccc3(102, 102, 102)];
    [eMenuModStatus setColor:ccc3(255, 128, 0)];
    [eMenuModTime setColor:ccc3(103, 157, 185)];
    [eMenuPlayerName setColor:ccc3(255, 255, 255)];
    
    [eMenuLeftClock setVisible:NO];
    
    
    [eMenu addChild:eMenuLeftOlay z:0];
    [eMenu addChild:eMenuPlayerName z:1];
    [eMenu addChild:eMenuTotExp z:1];
    [eMenu addChild:eMenuTotTime z:1];
    [eMenu addChild:eMenuModName z:1];
    [eMenu addChild:eMenuModDesc z:1];
    [eMenu addChild:eMenuModStatus z:1];
    [eMenu addChild:eMenuModTime z:1];
    [eMenu addChild:eMenuLeftClock z:1];
    [eMenu addChild:eMenuLeftPlayBtn z:1];
}

-(NSString *)convertTimeFromSeconds:(NSString *)seconds 
{
    
    // Return variable.
    NSString *result = @"";
    
    // Int variables for calculation.
    int secs = [seconds intValue];
    int tempHour    = 0;
    int tempMinute  = 0;
    int tempSecond  = 0;
    
    NSString *hour      = @"";
    NSString *minute    = @"";
    NSString *second    = @"";
    
    // Convert the seconds to hours, minutes and seconds.
    tempHour    = secs / 3600;
    tempMinute  = secs / 60 - tempHour * 60;
    tempSecond  = secs - (tempHour * 3600 + tempMinute * 60);
    
    hour    = [[NSNumber numberWithInt:tempHour] stringValue];
    minute  = [[NSNumber numberWithInt:tempMinute] stringValue];
    second  = [[NSNumber numberWithInt:tempSecond] stringValue];
    
    // Make time look like 00:00:00 and not 0:0:0
    if (tempHour < 10) {
        hour = [@"0" stringByAppendingString:hour];
    } 
    
    if (tempMinute < 10) {
        minute = [@"0" stringByAppendingString:minute];
    }
    
    if (tempSecond < 10) {
        second = [@"0" stringByAppendingString:second];
    }
    
    if (tempHour == 0) {
        
        NSLog(@"Result of Time Conversion: %@ hrs %@ mins", minute, second);
        result = [NSString stringWithFormat:@"%@ hrs %@ mins", minute, second];
        
    } else {
        
        NSLog(@"Result of Time Conversion: %@ hrs %@ mins %@ secs", hour, minute, second); 
        result = [NSString stringWithFormat:@"%@ hrs %@ mins %@ secs",hour, minute, second];
        
    }
    
    return result;
    
}

-(void)showModuleOverlay: (Module*)module
{
    UsersService *us = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService;
    NSUInteger totalExp = [us currentUserTotalExp];
    double secsInApp = [us currentUserTotalTimeInApp];
    NSUInteger hours = (NSUInteger)(secsInApp/3600);
    NSUInteger mins = ((NSUInteger)secsInApp % 3600)/60;
    
    [eMenuModName setString:module.name];
    [eMenuPlayerName setString:us.currentUser.nickName];
    [eMenuTotExp setString:[NSString stringWithFormat:@"%d", totalExp]];
    [eMenuTotTime setString:[NSString stringWithFormat:@"%dh %dm", hours, mins]];
    [eMenu setVisible:YES];
    [eMenuLeftPlayBtn setVisible:YES];
    
    [topicLabelLast setOpacity:0];
}

-(void)hideModuleOverlay
{
    NSLog(@"hide module view");

    [eMenuTotExp setString:@""];
    [eMenuTotTime setString:@""];
    [eMenuModName setString:@""];
    [eMenuModDesc setString:@""];
    [eMenuModStatus setString:@""];
    [eMenuModTime setString:@""];
    [eMenuLeftPlayBtn setVisible:NO];
    [eMenuLeftClock setVisible:NO];
    [eMenu setVisible:NO];
    
    [topicLabelLast setOpacity:kMenuLabelOpacity];
}

-(void)pressedPlayButton
{
    
}

-(void)showElementInfo:(Element*)element
{
    UsersService *us = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService;
    double elCompletion = [us currentUserPercentageCompletionOfElement:element];    
    // TODO: Display element completion (remember to multiply by 100)
    
    double secsPlayingEl = [us currentUserTotalPlayingElement:element.document.documentID];
    NSUInteger hours = (NSUInteger)(secsPlayingEl/3600);
    NSUInteger mins = ((NSUInteger)secsPlayingEl % 3600) / 60;
    
    [eMenuModDesc setString:element.name];
    [eMenuModStatus setString:(elCompletion < 1 ? [NSString stringWithFormat:@"%d%% COMPLETED", (NSUInteger)(100*elCompletion)] : @"COMPLETED")];
    [eMenuModTime setString:[NSString stringWithFormat:@"%d hours %d mins", hours, mins]];
    [eMenuLeftClock setVisible:YES];    
}

-(void)snapToTopicView
{
    int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];
    CCLayer *currentModule=[[moduleLayers objectAtIndex:topicPosition] objectAtIndex:modulePosition];
    
    [currentModule runAction:[CCEaseIn actionWithAction:[CCScaleTo actionWithDuration:kMenuScaleTime scale:kMenuModuleScale] rate:kMenuModuleScaleRate]];   
    
    [currentModule runAction:[CCMoveBy actionWithDuration:kMenuScaleTime position:ccp(-150,0)]];
    
    [self setAllModuleOpacityTo:1.0f exceptFor:currentModule];
    
    if(selectedElementOverlay) [self removeChild:selectedElementOverlay cleanup:YES];
    
    if(selectedElement) selectedElement=nil;
    
    [moduleViewUI setVisible:NO];
}

-(void)setAllModuleOpacityTo:(float)newOpacity exceptFor:(CCLayer*)activeModule
{
    for (NSMutableArray *mn in moduleLayers)
    {
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
        
        //TOFU: don't topic scroll for demo
//        //topic change up
//        else if (topicPosition < (topicCount-1) && touchYMovement >= (kPropYSwipeTopicThreshold*ly))
//        {
//            topicPosition++;
//            
//        }
//
//        //topic change down
//        else if (topicPosition>0 && touchYMovement <= -(kPropYSwipeTopicThreshold*ly))
//        {
//            topicPosition--;
//            
//        }

        
        
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
        else if(CGRectContainsPoint(CGRectMake(0, 0, 300, 100), location))
        {
            if(selectedElement)
            {
                [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
                contentService.currentElement=selectedElement;
                [[CCDirector sharedDirector] replaceScene:[ToolHost scene]];
            }
        }
        
        else {
            //look for element taps
            int modulePosition=[[modulePositions objectAtIndex:topicPosition] intValue];   
            CCLayer *currentModule=[[moduleLayers objectAtIndex:topicPosition] objectAtIndex:modulePosition];
            NSArray *elements=[[elementObjects objectAtIndex:topicPosition] objectAtIndex:modulePosition];
            
            CGPoint tapInModule=[currentModule convertToNodeSpace:location];
        
            for (int e=0; e<[elements count]; e++) {
                
                float xBase=-(((int)[elements count]-1) * 100);
                
                CGPoint ePoint=ccp(xBase+512+(200*e), cy);
                
                if([BLMath DistanceBetween:ePoint and:tapInModule] < 75)
                {
                    Element *element=[elements objectAtIndex:e];
                    NSLog(@"tapped element %@", element.name);
                    
                    if(selectedElementOverlay) [self removeChild:selectedElementOverlay cleanup:YES];
                    
                    selectedElementOverlay=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/menu/ElementView/Menu_E_C_S.png")];
                    [selectedElementOverlay setPosition:[currentModule convertToWorldSpace:ePoint]];
                    [self addChild:selectedElementOverlay];
                    
                    [self showElementInfo:element];
                    
                    selectedElement=element;
                    
                }
            }
            
            NSLog(@"tap local: %@", NSStringFromCGPoint(tapInModule));
            
            NSLog(@"elements count: %d", [elements count]);
        }
        
        
        
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
