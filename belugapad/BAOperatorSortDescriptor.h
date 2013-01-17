//
//  BAOperatorSortDescriptor.h
//  Beluga
//
//  Created by Cathy Shive on 12/20/10.
//  Copyright 2010 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAOperator;
@interface BAOperatorSortDescriptor : NSSortDescriptor 
{
}
- (NSComparisonResult)compareObject:(BAOperator*)theObject1 toObject:(BAOperator*)theObject2;
- (NSInteger)priorityIntForOperator:(BAOperator*)theOperator;
@end
