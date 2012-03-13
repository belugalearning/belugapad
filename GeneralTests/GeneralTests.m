//
//  GeneralTests.m
//  GeneralTests
//
//  Created by Gareth Jenkins on 01/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeneralTests.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"

@implementation GeneralTests

- (void)checkRootIsCommutative:(BAExpressionTree *)tree {
STAssertTrue([tree canMoveNode:tree.root.leftChild], @"Can move left ");
STAssertTrue([tree canMoveNode:tree.root.rightChild], @"Can move left ");
STAssertTrue([tree canMoveNode:tree.root.leftChild afterNode:tree.root.rightChild], @"Can move left after right");
STAssertTrue([tree canMoveNode:tree.root.rightChild beforeNode:tree.root.leftChild], @"Can move right before left");
}

@end