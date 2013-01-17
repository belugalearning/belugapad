//
//  BATio.h
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAExpressionTree;
@class BAExpression;
@class CXMLElement;

@interface BATio : NSObject

+(BAExpressionTree *)loadTreeFromMathMLFile:(NSString*)filePath;
+(BAExpressionTree *)loadTreeFromMathMLData:(NSData*)xmlData;
+(BAExpression *)parseMathMLElement:(CXMLElement*)element withNSMap:(NSDictionary*)nsmap;

@end
