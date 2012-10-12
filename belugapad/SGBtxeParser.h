//
//  SGBtxeParser.h
//  belugapad
//
//  Created by gareth on 15/08/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeParser : SGComponent
{
    id<Parser, Container> ParentGO;
}

-(void)parseXML:(NSString*)xmlString;

@end
