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
    
    UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/images/news-panel/News_panel.png"]] autorelease];
    bg.center = CGPointMake(512, 410);
    [self.view addSubview:bg];
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    close.frame = CGRectMake(910, 121, 48, 48);
    [close setImage:[UIImage imageNamed:@"/images/news-panel/News_close_button.png"] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closePanel:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:close];
    
    UIButton *prev = [UIButton buttonWithType:UIButtonTypeCustom];
    prev.frame = CGRectMake(103, 619, 131, 51);
    [prev setImage:[UIImage imageNamed:@"/images/news-panel/previous_button.png"] forState:UIControlStateNormal];
    [prev setImage:[UIImage imageNamed:@"/images/news-panel/previous_button_disabled.png"] forState:UIControlStateDisabled];
    [prev addTarget:self action:@selector(prev:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:prev];
    
    UIButton *next = [UIButton buttonWithType:UIButtonTypeCustom];
    next.frame = CGRectMake(235, 619, 131, 51);
    [next setImage:[UIImage imageNamed:@"/images/news-panel/next_button.png"] forState:UIControlStateNormal];
    [next setImage:[UIImage imageNamed:@"/images/news-panel/next_button_disabled.png"] forState:UIControlStateDisabled];
    [next addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:next];
    
    prev.enabled = NO;
    next.enabled = NO;
}

-(void)closePanel:(id)button
{
    [self.view removeFromSuperview];
    if (self.delegate) [self.delegate newPanelWasClosed];
}

-(void)prev:(id)button
{
    
}

-(void)next:(id)button
{
    
}

-(void)dealloc
{
    self.delegate = nil;
    [super dealloc];
}

@end
