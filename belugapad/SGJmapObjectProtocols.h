//
//  SGJmapObjectProtocols.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGJmapProximityEval;
@class SGJmapNodeSelect;


@protocol Transform

    @property CGPoint Position;

    @property (retain) CCSpriteBatchNode *RenderBatch;

@end


@protocol ProximityResponder

    @property CGPoint Position;

    @property BOOL Visible;
    @property (retain) SGJmapProximityEval* ProximityEvalComponent;

@end


@protocol Selectable

    @property BOOL Selected;
    @property (retain) SGJmapNodeSelect *NodeSelectComponent;
    @property float HitProximity;
    @property float HitProximitySign;

@end


@protocol Drawing

    @property CGPoint Position;
    @property BOOL Visible;

-(void)draw:(int)z;

@end


@protocol CouchDerived

    @property (retain) NSString *_id;
    @property (retain) NSString *UserVisibleString;

@end

@protocol PinRender

@property BOOL flip;

@end

@protocol Searchable
    @property (retain) NSString *searchMatchString;
@end

@protocol Completable

    @property BOOL EnabledAndComplete;
    @property BOOL Attempted;
    @property (retain) NSDate *DateLastPlayed;
    @property BOOL FreshlyCompleted;

@end

@protocol Configurable

    -(void) setup;

@end

@protocol ParticleRender

    @property (retain) CCLayer *particleRenderLayer;

@end

