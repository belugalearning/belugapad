//
//  CCPickerView.m
//  CCPickerView
//
//  Created by Mick Lester on 5/16/12.
//  Copyright (c) 2012 fidgetware. All rights reserved.
//

#import "CCPickerView.h"

@implementation CCPickerView
@synthesize dataSource;
@synthesize delegate;
@synthesize numberOfComponents;
@synthesize isLocked;

-(id) init {
	if ((self=[super init])) {
        repeatNodes = YES;
	}
    
	return self;
}

-(void)initialLoad {

    CCNode *overlayImage = [delegate overlayImage:self];
    CCNode *underlayImage = [delegate underlayImage:self];
    
    [self addChild:underlayImage z:0];
    [self addChild:overlayImage z:10];
    
//    CGSize size = [delegate sizeOfPickerView:self];
    CGSize size=overlayImage.contentSize;
    
    //CGFloat spacing = [delegate spaceBetweenComponents:self];
    
    self.contentSize = size;
    
//    CCSprite* background;
//    background = [CCSprite node];
//    background.color = ccWHITE;
//    background.textureRect = CGRectMake(0, 0, size.width-spacing, size.height-spacing);
//    [self addChild:background];
    

    
    rect = CGRectMake(self.position.x - size.width/2, self.position.y - (size.height/2), size.width, size.height);
    
//    clippingRegion=CGRectMake(-rect.size.width / 2.0f, -rect.size.height / 2.0f, rect.size.width, rect.size.height);
    clippingRegion=CC_RECT_POINTS_TO_PIXELS(rect);
    
    [self reloadAllComponents];    
}

-(void)setDelegate:(id<CCPickerViewDelegate>)newDelegate {
    delegate = newDelegate;
    
    if (dataSource != nil) {
        [self initialLoad];
    }
}

-(void)setDataSource:(id<CCPickerViewDataSource>)newDataSource {
    dataSource = newDataSource;
    
    if (delegate != nil) {
        [self initialLoad];
    }
}

-(void)setLocked:(BOOL)newValue {
    self.isLocked=newValue;
}

-(void)setIsLocked:(BOOL)theIsLocked
{
    isLocked = theIsLocked;
    
//    for (ScrollLayer *sl in ) {
//        if(theIsLocked) [sl stopTouching];
//        else [sl startTouching];
//    }
    
    [self reloadAllComponents];
}

- (void)autoRepeatNodes:(BOOL)repeat {
    repeatNodes = repeat;
    [self reloadAllComponents];
}

- (void)spinComponent:(NSInteger)component speed:(float)speed easeRate:(float)rate repeat:(NSInteger)repeat stopRow:(NSInteger)row {
    if (repeatNodes) {
        ScrollLayer *scrollLayer = (ScrollLayer *)[self getChildByTag:component];
        [scrollLayer spin:speed rate:rate repeat:repeat stopPage:row];
    } else {
        CCLOG(@"You need to turn on autoRepeatNodes");
    }
}

- (NSInteger)numberOfRowsInComponent:(NSInteger)component {
    ScrollLayer *scrollLayer = (ScrollLayer *)[self getChildByTag:component];
    
    return [scrollLayer.arrayPages count];
}

- (void)reloadAllComponents {
    for (int c = 0; c < [dataSource numberOfComponentsInPickerView:self]; c++) {
        [self reloadComponent:c];
    }
}

- (void)reloadComponent:(NSInteger)component {
    NSInteger numComponents = [dataSource numberOfComponentsInPickerView:self];
    CGFloat componentsWidth = 0;
    NSInteger pickerStart = 0;
    CGFloat spacing = [delegate spaceBetweenComponents:self];

    [self removeChildByTag:component cleanup:YES];
    
    ScrollLayer *scrollLayer = [ScrollLayer node];
    scrollLayer.delegate = self;
    
    for (int i = 0; i < numComponents; i++) {
        componentsWidth += [delegate pickerView:self widthForComponent:i];
    }
    
    componentsWidth += (numComponents-1)*spacing;

    pickerStart = -componentsWidth/2;
    for (int c = 0; c < component; c++) {
        CGSize componentSize = CGSizeMake([delegate pickerView:self widthForComponent:c], [delegate pickerView:self rowHeightForComponent:c]);
        pickerStart += componentSize.width + spacing;
    }

    CGSize componentSize = CGSizeMake([delegate pickerView:self widthForComponent:component], [delegate pickerView:self rowHeightForComponent:component]);

    scrollLayer.contentSize = componentSize;
    scrollLayer.position = ccp(pickerStart+componentSize.width/2, 0);
        
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
    NSInteger pageSize = [dataSource pickerView:self numberOfRowsInComponent:component];
    
    // Duplicate the nodes if we have repeatNodes on.
    int numPages = repeatNodes?3:1;
    
    for (int r = 0; r < numPages; r++) {
        for (int p = 0; p < pageSize; p++) {
            [array addObject:[delegate pickerView:self nodeForRow:p forComponent:component reusingNode:nil]];
        }
    }
    
    scrollLayer.isLocked=isLocked;
    scrollLayer.arrayPages = array;
    scrollLayer.pageSize = pageSize;
    [scrollLayer setCurrentPage:0];
    scrollLayer.touchSize = CGSizeMake(componentSize.width, self.contentSize.height);
    [scrollLayer makePages];
        
    [self addChild:scrollLayer z:0 tag:component];
}

- (CGSize)rowSizeForComponent:(NSInteger)component {
    ScrollLayer *scrollLayer = (ScrollLayer *)[self getChildByTag:component];
    
    return scrollLayer.contentSize;
}

- (NSInteger)selectedRowInComponent:(NSInteger)component {
    ScrollLayer *scrollLayer = (ScrollLayer *)[self getChildByTag:component];
    
    return scrollLayer.currentPage;
}

- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated {
    ScrollLayer *scrollLayer = (ScrollLayer *)[self getChildByTag:component];
    [scrollLayer setCurrentPage:row];    
}

- (CCNode *)nodeForRow:(NSInteger)row forComponent:(NSInteger)component {
    ScrollLayer *scrollLayer = (ScrollLayer *)[self getChildByTag:component];
    
    return [scrollLayer getChildByTag:row];
}

- (void) visit {
	if (!self.visible)
		return;
    
    glEnable(GL_SCISSOR_TEST);
    
//    CGRect clip=CGRectMake(position_.x - 150, position_.y -100, 300, 300);
//    clip=CC_RECT_POINTS_TO_PIXELS(clip);
    
    glScissor(clippingRegion.origin.x, clippingRegion.origin.y, clippingRegion.size.width, clippingRegion.size.height);
    
//    glScissor(clip.origin.x + position_.x, clip.origin.y + position_.y,
//              clip.size.width, clip.size.height);
    
    [super visit];
    
    glDisable(GL_SCISSOR_TEST);
}

#pragma mark - ScrollLayerDelegate
-(void)onDoneSelecting:(ScrollLayer *)scrollLayer {
    if ([delegate respondsToSelector:@selector(pickerView: didSelectRow: inComponent:)]) {
        [delegate pickerView:self didSelectRow:scrollLayer.currentPage inComponent:scrollLayer.tag];
    }
}

-(void)onDoneSpinning:(ScrollLayer *)scrollLayer {
    if ([delegate respondsToSelector:@selector(onDoneSpinning: component:)]) {
        [delegate onDoneSpinning:self component:scrollLayer.tag];
    }
}

@end

