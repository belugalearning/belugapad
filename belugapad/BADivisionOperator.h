//
//  BADivisionOperator.h
//  Beluga
//
//  Created by Cathy Shive on 1/25/11.
//  Copyright 2011 Heritage World Press. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BAOperator.h"

/*
	A division operation is not commutative.

	The children should be ordered so that:
	- the numerator of the division is child at index 0
	- the divisor of the division is child at index 1
 */

@interface BADivisionOperator : BAOperator 
{
}

-(void)simplifyIntegerDivision;

@end
