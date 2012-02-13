//
//  DWModelConstants.h
//
//  Created by Gareth Jenkins on 30/07/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

//data store structure / key constants
#define IMPLEMENT_TEMPLATES @"IMPLEMENT_TEMPLATES"
#define BEHAVIOURS @"BEHAVIOURS"
#define VALUES @"VALUES"
#define BEHAVIOUR_NAME @"BEHAVIOUR_NAME"
#define OBJECT_DATA @"OBJECT_DATA"
#define DEBUG_LEVEL 1

//macros and shortcuts
#define GOS_GET(forKey) ([[gameObject store] objectForKey:forKey])
#define GOS_GETCGPOINT(forKey) ([[[gameObject store] objectForKey:forKey] CGPointValue])

#define GOS_SET(object, key) ([[gameObject store] setObject:object forKey:key])


#define LOG_OUTPUT_LEVEL 0

typedef enum {

    kDWonGameObjectInitComplete=0,

    kDWsetupStuff=1,
    
    kDWsetMount=2,
    kDWunsetMount=3,
    kDWsetMountedObject=4,
    kDWunsetMountedObject=5,
    
    
    kDWupdateSprite=6,
    
    kDWareYouADropTarget=7,
    kDWareYouAPickupTarget=8,
    
    kDWupdatePosFromPhys=9,
    kDWsetPhysBody=10,
    
    kDWpickedUp=11,
    kDWputdown=12,
    
    kDWenable=13,
    
    kDWpurgeMatchSolutions=14,
    
    kDWejectContents=15,
    
    kDWresetToMountPosition=16
    
} DWMessageType;