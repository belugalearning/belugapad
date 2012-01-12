//
//  Blackboard.h
//
//  Created by Gareth Jenkins on 29/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DWGameObject;

@interface DWBlackboard : NSObject {
 
}

@property (retain) DWGameObject *DropObject;
@property (retain) DWGameObject *PickupObject;
@property (retain) NSMutableArray *AllStores;

-(void)loadData;

@end
