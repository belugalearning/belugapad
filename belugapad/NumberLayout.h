//
//  NumberLayout.h
//  belugapad
//
//  Created by gareth on 11/09/2012.
//
//

#import <Foundation/Foundation.h>

@interface NumberLayout : NSObject

+(NSArray*)unitLayoutUpToNumber:(int)max;
+(NSArray*)unitLayoutAcrossToNumber:(int)max;
+(NSArray*)physicalLayoutUpToNumber:(int)max withSpacing:(float)spacing;
+(NSArray*)physicalLayoutAcrossToNumber:(int)max withSpacing:(float)spacing;


@end
