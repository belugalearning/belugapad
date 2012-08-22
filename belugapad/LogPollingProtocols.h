//
//  BLCommonProtocols.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/08/2012.
//
//

#import <Foundation/Foundation.h>


@protocol LogPolling

@property (readwrite, retain) NSString *logPollId;
@property (readonly, retain) NSString *logPollType;
@end


@protocol LogPollPositioning

@property (readonly) CGPoint logPollPosition;

@end
