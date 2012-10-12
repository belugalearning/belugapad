//
//  DebugViewController.h
//  belugapad
//
//  Created by gareth on 06/10/2012.
//
//

#import <UIKit/UIKit.h>

@interface DebugViewController : UIViewController <UIWebViewDelegate>

@property SEL skipProblemMethod;
@property (retain) id handlerInstance;

@end
