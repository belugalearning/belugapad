//
//  NumericKeypadTextField.m
//  NumericKeypad
//
//  Created by  on 11/12/01.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NumericKeypadTextField.h"
#import "NumericKeypadViewController.h"

@implementation NumericKeypadTextField

- (UIView *)inputView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        numPadViewController = [[NumericKeypadViewController alloc]
                                                             initWithNibName:@"NumericKeypad" bundle:nil];
        [numPadViewController setActionSubviews:numPadViewController.view];
        numPadViewController.delegate = self.delegate;
        // Controllerで操作できるように渡す
        numPadViewController.numpadTextFiled = self;
        return numPadViewController.view;
    }else {
        return nil;
    }
}

-(id)delegate
{
    return delegate;
}
-(void)setDelegate:(id)nextDelegate
{
    if (nextDelegate == delegate) return;
    
    if (nextDelegate) [nextDelegate retain];
    if (delegate) [delegate release];
    
    delegate = nextDelegate;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(paste:)) ? NO : [super canPerformAction:action withSender:sender];
}

- (void)dealloc {
    [numPadViewController release];
    self.delegate = nil;
    [super dealloc];
}


@end
