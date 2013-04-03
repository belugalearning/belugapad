//
//  TTAppUState.h
//  belugapad
//
//  Created by gareth on 03/04/2013.
//
//

#import "AppUState.h"

@interface TTAppUState : AppUState {
    
    int logRollover;
    BOOL persistSaves;
    BOOL overwriteOnLoad;
    
    NSString *persistPath;
    NSMutableDictionary *udata;
    
    
}

-(NSString*) getMedalForX:(int)x andY:(int)y;
-(NSString*) getPreviousMedalForX:(int)x andY:(int)y;

@end
