//
//  SGDtoolBlock.h
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGDtoolObjectProtocols.h"

@interface SGDtoolContainer : SGGameObject <Container>

-(SGDtoolContainer*) initWithGameWorld:(SGGameWorld*)aGameWorld andLabel:(NSString*)aLabel andRenderLayer:(CCLayer*)aRenderLayer;

-(void)addBlockToMe:(id)thisBlock;
-(void)removeBlockFromMe:(id)thisBlock;
-(void)repositionLabel;
-(int)blocksInShape;
-(void)destroyThisObject;
@end