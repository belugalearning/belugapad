//
//  SGBtxeObjectOperator.h
//  belugapad
//
//  Created by gareth on 07/11/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"
#import "LogPollingProtocols.h"

@class SGBtxeTextBackgroundRender;

@interface SGBtxeObjectOperator : SGGameObject <Text, MovingInteractive, Containable, ValueOperator, LogPolling, LogPollPositioning>
{
    CCNode *renderBase;
    LoggingService *loggingService;
}

@property (retain) SGBtxeTextBackgroundRender *textBackgroundRenderComponent;

-(void)tagMyChildrenForIntro;

@end
