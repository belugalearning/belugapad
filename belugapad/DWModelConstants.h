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
    
    kDWresetToMountPosition=16,
    
    kDWswitchSelection=17,
    kDWresetPositionEval=18,
    
    kDWdeselectAll=19,
    
    kDWswitchBaseSelection=20,
    kDWswitchBaseSelectionBack=21,
    
    kDWdeselectIfNotThisValue=22,
    kDWdismantle=23,
    
    kDWmoveSpriteToPosition=24,
    
    kDWhandleTap=25,
    
    kDWmoveSpriteToHome=26,
    kDWcanITouchYou=27,
    kDWaddMeToSelection=28,
    kDWremoveMeFromSelection=29,
    kDWremoveAllFromSelection=30,
    
    kDWuseThisHandle=31,
    kDWmoveShape=32,
    kDWresizeShape=33,
    
    kDWshowCalcBubble=34,
    
    kDWsplitActivePies=35,
    kDWupdateLabels=36,
    
    kDWcheckMyMountIsCage=37,
    kDWcheckMyMountIsNet=38,
    kDWstopAllActions=39,
    
    kDWunsetAllMountedObjects=40,
    
    kDWswitchParentToMovementLayer=41,
    kDWswitchParentToRenderLayer=42,
    
    kDWreorderPieSlices=43,
    kDWresetToMountPositionAndDestroy=44,
    
    kDWdestroy=45,
    kDWfadeAndDestroy=46,
  
    kDWselectMe=47,
    kDWdeselectMe=48,
    
    kDWareYouProximateTo=101,
    kDWupdateObjectData=102,
    kDWdetachPhys=103,
    kDWattachPhys=104,
    
    kDWoperateAddTo=105,
    kDWoperateSubtractFrom=106,
    kDWfloatAddThisChild=107,
    kDWfloatSubtractThisChild=108,
    kDWenableOccludingSeparators=109,
    
    kDWoperateMultiplyBy=110,
    kDWoperateDivideBy=111,
    kDWfloatMultiplyWithThisChild=112,
    kDWfloatDivideWithThisChild=113,
    
    kDWnlineReleaseRamblerAtOffset=114,
    kDWrenderSelection=115,
    
    kDWinOperatorMode=116,
    kDWnotInOperatorMode=117,
    
    kDWhighlight=118,
    kDWunhighlight=119,
    
    kDWdoSelection=120,
    
    kDWstartRespositionSeek=121,
    
    kDWmoveSpriteToPositionWithoutAnimation=122
    
} DWMessageType;