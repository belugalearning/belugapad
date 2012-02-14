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
@property (retain) DWGameObject *ProximateObject;
@property (retain) NSMutableArray *SelectedObjects;
@property (retain) NSMutableArray *AllStores;
@property CGPoint PickupOffset;
@property float hostLX;
@property float hostLY;
@property float hostCX;
@property float hostCY;

-(void)loadData;

@end
