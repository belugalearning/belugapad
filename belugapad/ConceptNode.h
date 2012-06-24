//
//  ConceptNode.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CouchDBDerivedDocument.h"
@class CCSprite;

@interface ConceptNode : CouchDBDerivedDocument
{
}

@property (readonly) NSArray *pipelines;
@property (readonly) int x;
@property (readonly) int y;

//not persisted
@property (retain) CCSprite *journeySprite;
@property (retain) CCSprite *nodeSliceSprite;
@property (retain) CCSprite *lightSprite;
@property bool isLit;

@end
