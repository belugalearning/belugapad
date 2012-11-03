//
//  SGDtoolCage.h
//  belugapad
//
//  Created by David Amphlett on 13/08/2012.
//
//

#import "SGGameObject.h"
#import "SGDtoolObjectProtocols.h"

@interface SGDtoolCage : SGGameObject <Cage>

-(SGDtoolCage*) initWithGameWorld:(SGGameWorld*)aGameWorld atPosition:(CGPoint)thisPosition andRenderLayer:(CCLayer*)aRenderLayer andCageType:(NSString*)cageType;

-(void)removeBlockFromMe:(id)thisBlock;
@end