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


typedef enum {

    kDWonGameObjectInitComplete,

    kDWsetupStuff,
    
    kDWsetMount,
    kDWsetMountedObject,
    kDWupdateSprite,
    kDWunsetMountedObject,
    kDWareYouADropTarget,
    kDWareYouAPickupTarget,
    
    kDWupdatePosFromPhys,
    kDWsetPhysBody,
    
    kDWpickedUp,
    kDWputdown
    
} DWMessageType;