//
//  SGJmapObjectProtocols.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGJmapProximityEval;


@protocol Transform

@property CGPoint Position;

@property (retain) CCSpriteBatchNode *RenderBatch;

@end


@protocol ProximityResponder

@property CGPoint Position;

@property BOOL Visible;
@property (retain) SGJmapProximityEval* ProximityEvalComponent;

@end



@protocol Drawing

@property CGPoint Position;
@property BOOL Visible;

-(void)draw;

@end



@protocol CouchDerived

@property (retain) NSString *_id;
@property (retain) NSString *UserVisibleString;

@end


@protocol Configurable

-(void) setup;

@end