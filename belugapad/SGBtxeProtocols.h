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
@class SGBtxeParser;


@protocol Container

@property (retain) NSMutableArray *children;
@property (retain) SGBtxeContainerMgr *containerMgrComponent;

@end



@protocol Containable

@property (retain) id<Container> container;

@end


@protocol RenderContainer

@property (retain) CCLayer *renderLayer;
@property (retain) CCNode *baseNode;
@property BOOL forceVAlignTop;


@end


@protocol RenderObject <Containable>

-(void)attachToRenderBase:(CCNode*)renderBase;

@end



@protocol Bounding

@property CGSize size;
@property CGPoint position;
@property CGPoint worldPosition;

-(void) setupDraw;

@end



@protocol Text

@property (retain) NSString *text;

@property (retain) SGBtxeTextRender *textRenderComponent;

@end



@protocol Value <NSObject>

@property (readonly) NSNumber *value;

@end




@protocol Interactive <Bounding>

@property BOOL enabled;
@property (retain) NSString *tag;

-(void)activate;
-(void)inflateZIndex;
-(void)deflateZindex;
-(void)destroy;

@end


@protocol MovingInteractive <Interactive>

@property CGPoint originalPosition;

-(void)returnToBase;
-(id<MovingInteractive>)createADuplicate;
-(void)destroy;

@end


@protocol BtxeMount

@property (retain) id<Interactive, NSObject> mountedObject;

-(void)duplicateAndMountThisObject:(id<MovingInteractive, NSObject>)mountObject;

@end


@protocol Tappable <Bounding>

-(void) actOnTap;

@end


@protocol NumberPicker <Tappable>

@property float targetNumber;
@property BOOL usePicker;


@end


@protocol Parser

@property (retain) SGBtxeParser *parserComponent;
-(void) parseXML:(NSString*)xmlString;

@end


@protocol FadeIn

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime;

@end


@protocol Icon

@property (retain) NSString *iconTag;

@end