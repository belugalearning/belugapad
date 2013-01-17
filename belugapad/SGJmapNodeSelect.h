//
//  SGJmapNodeSelect.h
//  belugapad
//
//  Created by Gareth Jenkins on 18/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"
#import "SGJmapObjectProtocols.h"

@interface SGJmapNodeSelect : SGComponent
{
    id<Transform, CouchDerived, Selectable, Completable> ParentGO;
    
    CCSprite *signSprite;
    CGRect hitbox;
    BOOL forcedOn;
}

-(BOOL)trySelectionForPosition:(CGPoint)pos;
-(void)deselect;
-(void)removeSign;
-(void)showSignWithForce:(BOOL)forceOn;

@end
