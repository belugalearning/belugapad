//
//  GeneralTests.h
//  GeneralTests
//
//  Created by Gareth Jenkins on 01/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

@class BAExpressionTree;

@interface GeneralTests : SenTestCase

- (void)checkRootIsCommutative:(BAExpressionTree *)tree;

@end
