//
//  UIView+UIView_DragLogPosition.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/11/2012.
//
//

#import <UIKit/UIKit.h>

@interface UIView (UIView_DragLogPosition)

@property (retain) NSArray *startPanCentre;

-(void)registerForDragAndLog;
-(void)handlePan:(id)sender;

@end
