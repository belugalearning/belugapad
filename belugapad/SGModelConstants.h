//
//  SGModelConstants.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

//data store structure / key constants
#define DEBUG_LEVEL 1

//macros and shortcuts
#define LOG_OUTPUT_LEVEL 0

typedef enum {

    kSGmessageNone,
    kSGreadyRender,
    kSGvisibilityChanged,
    
    kSGzoomOut,
    kSGzoomIn,
    
    kSGretainOffsetPosition,
    kSGforceLayout,
    kSGresetPositionUsingOffset,
    
    kSGtearDownRender,
    
    kSGdisableAuthorRender,
    kSGenableAuthorRender,
    
    kSGsetVisualStateAfterBuildUp
        
} SGMessageType;