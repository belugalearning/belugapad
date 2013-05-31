//
//  SGBtxeObjectNumber.h
//  belugapad
//
//  Created by gareth on 24/09/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"
#import "LogPollingProtocols.h"

@class SGBtxeTextBackgroundRender;
@class SGBtxeNumberDotRender;
@class SGBtxeFractionRender;

@interface SGBtxeObjectNumber : SGGameObject <Text, Bounding, FadeIn, MovingInteractive, Containable, Value, NumberPicker, LogPolling, LogPollPositioning>
{
    CCNode *renderBase;
    LoggingService *loggingService;
}

@property (retain) NSString *prefixText;
@property (retain) NSString *numberText;
@property (retain) NSString *suffixText;


@property BOOL showAsMixedFraction;

@property (retain) SGBtxeTextBackgroundRender *textBackgroundRenderComponent;
@property (retain) SGBtxeFractionRender *fractionRenderComponent;

@property BOOL renderAsDots;
@property (retain) SGBtxeNumberDotRender *numberDotRenderComponent;

@property (retain) NSString *numberMode;

-(void)tagMyChildrenForIntro;
-(void)updateDraw;

@end
