//
//  BelugaNewsViewController.h
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2013.
//
//

#import <UIKit/UIKit.h>
@protocol BelugaNewsDelegate;

@interface BelugaNewsViewController : UIViewController

@property (retain) id<BelugaNewsDelegate> delegate;

@end


@protocol BelugaNewsDelegate
-(void)newPanelWasClosed;
@end
