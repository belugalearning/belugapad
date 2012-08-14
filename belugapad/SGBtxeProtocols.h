//
//  SGBtxeProtocols.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import <Foundation/Foundation.h>

@class SGBtxeContainerMgr;
@class SGBtxeTextRender;


@protocol Container

@property (retain) NSMutableArray *children;

@property (retain) SGBtxeContainerMgr *containerMgrComponent;

@end


@protocol RenderContainer

@property (retain) CCLayer *renderLayer;

@end


@protocol RenderObject

-(void)attachToRenderBase:(CCNode*)renderBase;

@end



@protocol Bounding

@property CGSize size;
@property CGPoint position;

-(void) setupDraw;

@end



@protocol Text

@property (retain) NSString *text;

@property (retain) SGBtxeTextRender *textRenderComponent;

@end



@protocol Interactive <Bounding>

@property BOOL enabled;
@property (retain) NSString *tag;

@end



@protocol Parser

-(void) parseXML:(NSString*)xmlString;

@end