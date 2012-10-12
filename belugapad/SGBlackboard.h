//
//  SGBlackboard.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCLayer;
@class CCSpriteBatchNode;

@interface SGBlackboard : NSObject {
 
}

@property (retain) CCLayer *RenderLayer;
@property BOOL inProblemSetup;

@property (retain) CCSpriteBatchNode *btxeIconBatch;

@end
