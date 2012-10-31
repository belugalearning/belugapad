//
//  SGBtxeObjectNumber.h
//  belugapad
//
//  Created by gareth on 24/09/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"


@interface SGBtxeObjectNumber : SGGameObject <Text, Bounding, FadeIn, Interactive>
{
    CCNode *renderBase;
}

@property (retain) NSString *prefixText;
@property (retain) NSString *numberText;
@property (retain) NSString *suffixText;
@property (retain, readonly) NSNumber *numberValue;

@end
