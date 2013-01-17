//
//  SGBtxeObjectIcon.h
//  belugapad
//
//  Created by gareth on 01/10/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"
#import "LogPollingProtocols.h"

@class SGBtxeIconRender;

@interface SGBtxeObjectIcon : SGGameObject <MovingInteractive, Icon, FadeIn, Containable, LogPolling, LogPollPositioning>
{
    CCNode *renderBase;
    LoggingService *loggingService;
}

@property (retain) SGBtxeIconRender *iconRenderComponent;
@property BOOL animatePos;

-(void)tagMyChildrenForIntro;
-(NSString*)returnMyText;

@end
