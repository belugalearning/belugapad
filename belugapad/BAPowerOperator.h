//
//  BAPowerOperator.h
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAOperator.h"

/*
 A power operation is not commutative.
 
The children should be ordered so that:
 - the base integer is child at index 0
 - the exponent integer is child at index 1
 */

@interface BAPowerOperator : BAOperator 
{
}

@end
