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
@property (readonly) BOOL mastery;
@property (readonly) NSString *jtd;
@property (readonly) NSArray *regions;

//not persisted
@property bool isLit;

@end
