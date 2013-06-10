//
//  BelugaNewsView.m
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2013.
//
//

#import "BelugaNewsViewController.h"
#import "UIView+UIView_DragLogPosition.h"

@implementation BelugaNewsViewController

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.view.frame = CGRectMake(0, 0, 699, 499);
    
    UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/images/news-panel/News_panel.png"]] autorelease];
    bg.center = CGPointMake(512, 364);
    [self.view addSubview:bg];
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    close.frame = CGRectMake(814, 130, 48, 48);
    [close setImage:[UIImage imageNamed:@"/images/news-panel/News_close_button.png"] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closePanel:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:close];
}

-(void)closePanel:(id)button
{
    [self.view removeFromSuperview];
    if (self.delegate) [self.delegate newPanelWasClosed];
}

-(void)dealloc
{
    self.delegate = nil;
    [super dealloc];
}

@end
