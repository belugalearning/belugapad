//
//  JourneyScene.h
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "AppDelegate.h"

@class Daemon;

@interface JMap : CCLayer <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>
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
    
    AppController *ac;
    
    BOOL authorRenderEnabled;
}

+(CCScene *)scene;

-(void)startTransitionToToolHostWithPos:(CGPoint)pos;

@end
