//
//  NumpadInputController.m
//  belugapad
//
//  Created by Nicholas Cartwright on 27/11/2012.
//
//

#import "NumpadInputController.h"

@interface NumpadInputController ()
@end

@implementation NumpadInputController
@synthesize delegate;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(IBAction)buttonPress:(id)sender
{
    if (self.delegate)
    {
        UIButton *btn = (UIButton*)sender;
        [self.delegate buttonTappedWithText:btn.titleLabel.text];
    }
}

-(void)dealloc
{
    self.delegate = nil;
    [super dealloc];
}

@end
