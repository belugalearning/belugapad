//
//  JourneyScene.h
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "AppDelegate.h"
#import "BelugaNewsViewController.h"

@class Daemon;
@class SGJmapMasteryNode;
@class SGJmapNode;

@interface JMap : CCLayer <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, BelugaNewsDelegate>
{
    float cx, cy, lx, ly;
    
    
    //Daemon *daemon;
    
    CCLayer *underwaterLayer;
    CGPoint underwaterLastMapPos;
    BOOL setUnderwaterLastMapPos;
    
    CCLayer *mapLayer;
    CCLayer *foreLayer;
    
    
    CGPoint lastTouch;
    BOOL isDragging;
    CGPoint dragVel;
    CGPoint dragLast;
    
    BOOL zoomedOut;
    
    int touchCount;
    BOOL didJustChangeZoom;
    
    NSMutableArray *searchNodes;
    NSMutableArray *filteredNodes;
    BOOL isFiltered;
    BOOL filteredToAssignedNodes;
    BOOL showingFilter;
    CCSprite *filterButtonSprite;
    int filterTotalFlagCount;
    NSString *filterButtonType;
    
    AppController *ac;
    
    BOOL authorRenderEnabled;
    
    NSDictionary *udata;
    
    CGPoint lastTap;
    float lastTapTime;
    
    BOOL playTransitionAudio;
    id lastSelectedNode;
    
    id lastPlayedNode;
    SGJmapMasteryNode *lastPlayedMasteryNode;
    bool mapPositionSet;
    
    CCLabelTTF *utdHeaderLabel;
    
    SGJmapNode *resumeAtNode;
    NSDate *resumeAtMaxDate;
}

+(CCScene *)scene;

-(void)startTransitionToToolHostWithPos:(CGPoint)pos;
-(void)setUtdLabel:(NSString*)toThisString;
-(BOOL)isPointInView:(CGPoint)testPoint;
-(void)newPanelWasClosed;

@end
