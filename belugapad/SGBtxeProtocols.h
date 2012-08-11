//
//  SGBtxeProtocols.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import <Foundation/Foundation.h>

@protocol Container

@property (readonly) NSArray *children;

@end


@protocol Bounding

@property (readonly) CGSize size;
@property CGPoint position;

-(void) calculateSize;

@end



@protocol Text

@property (retain) NSString *text;

@end



@protocol Interactive

@property BOOL enabled;
@property (retain) NSString *tag;

@end



@protocol Parser

-(void) parseXML:(NSString*)xmlString;

@end