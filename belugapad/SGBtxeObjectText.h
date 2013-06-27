//
//  SGBtxeObjectText.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"
#import "LogPollingProtocols.h"

@class SGBtxeTextBackgroundRender;

@interface SGBtxeObjectText : SGGameObject <Text, MovingInteractive, Containable, FadeIn, LogPolling, LogPollPositioning>
{
    CCNode *renderBase;
    LoggingService *loggingService;
}

@property (retain) SGBtxeTextBackgroundRender *textBackgroundRenderComponent;

-(void)tagMyChildrenForIntro;
-(NSString*)returnMyText;

@end
