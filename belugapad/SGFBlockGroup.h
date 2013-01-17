//
//  SGFBlockGroup.h
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import "SGGameObject.h"
#import "SGFBlockObjectProtocols.h"


@interface SGFBlockGroup : SGGameObject <Group>

-(int)blocksInGroup;

@end
