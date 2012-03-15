//
//  NSArray_BAAdditions.h
//  Beluga
//
//  Created by Cathy Shive on 12/21/10.
//  Copyright 2010 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (BAAdditions)
+ (NSArray*)arrayByRandomizingObjectsInArray:(NSArray*)theArray;
+ (id)randomObjectFromArray:(NSArray*)theArray;
- (BOOL)indexIsValid:(NSInteger)theIndex;
- (BOOL)hasFiveInARow;
@end
