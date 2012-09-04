//
//  AdpInserter.h
//  belugapad
//
//  Created by gareth on 03/09/2012.
//
//

#import <Foundation/Foundation.h>

@class ContentService;

@interface AdpInserter : NSObject
{
    ContentService *contentService;
    NSDictionary *adplineSettings;
}

@property (retain) NSMutableArray *viableInserts;
@property (readonly) NSString *inserterName;
@property (retain) NSMutableDictionary *decisionInformation;

-(void)buildInserts;

@end
