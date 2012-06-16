//
//  SGJmapObjectProtocols.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Transform

@property CGPoint Position;
@property (retain) CCSpriteBatchNode *RenderBatch;

@end