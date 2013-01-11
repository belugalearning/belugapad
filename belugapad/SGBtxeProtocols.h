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
@class SGBtxeTextBackgroundRender;
@class SGBtxeParser;
@class SGGameWorld;


@protocol Container <NSObject>

@property (retain) NSMutableArray *children;
@property (retain) SGBtxeContainerMgr *containerMgrComponent;
@property (retain) NSString *defaultNumbermode;

@end



@protocol Containable

@property (retain) id<Container> container;

@end


@protocol RenderContainer

@property (retain) CCLayer *renderLayer;
@property (retain) CCNode *baseNode;
//@property BOOL isLarge;
@property (retain) NSString *myAssetType;
@property BOOL tintMyChildren;
@property (retain) NSString *backgroundType;
@property BOOL forceVAlignTop;


@end


@protocol RenderObject <Containable>

-(void)attachToRenderBase:(CCNode*)renderBase;

@end



@protocol Bounding

@property CGSize size;
@property CGPoint position;
@property CGPoint worldPosition;
@property float rowWidth;
@property BOOL hidden;

-(void) setupDraw;

@end



@protocol Text

@property (retain) NSString *text;

@property (retain) SGBtxeTextRender *textRenderComponent;

@property BOOL disableTrailingPadding;

-(NSString*)returnMyText;

@end



@protocol Value <NSObject>

@property (readonly) NSNumber *value;

@end



@protocol ValueOperator <NSObject>

@property (retain) NSString *valueOperator;

@end



@protocol Interactive <Bounding>

@property BOOL enabled;
@property BOOL interactive;
@property (retain) NSString *tag;

-(void)activate;
-(void)inflateZIndex;
-(void)deflateZindex;
-(void)destroy;

@end





@protocol MovingInteractive <Interactive>

@property CGPoint originalPosition;
@property (retain) id mount;
@property (retain) SGBtxeTextBackgroundRender *textBackgroundRenderComponent;
//@property BOOL isLargeObject;
@property (retain) NSString *assetType;
@property (retain) NSString *backgroundType;

-(void)returnToBase;
-(id<MovingInteractive>)createADuplicate;
-(id<MovingInteractive>)createADuplicateIntoGameWorld:(SGGameWorld*)destGW;
-(void)setColourOfBackgroundTo:(ccColor3B)thisColour;
-(CGRect)returnBoundingBox;
-(void)destroy;

@end




@protocol BtxeMount

@property (retain) id<Interactive, NSObject> mountedObject;
@property (retain) NSString *backgroundType;

-(void)duplicateAndMountThisObject:(id<MovingInteractive, NSObject>)mountObject;
-(CGRect)returnBoundingBox;

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