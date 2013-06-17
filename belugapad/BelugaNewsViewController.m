//
//  BelugaNewsView.m
//  belugapad
//
//  Created by Nicholas Cartwright on 07/06/2013.
//
//

#import "BelugaNewsViewController.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BelugaNewsViewController()
{
    UIWebView *webView;
    UIButton *prev;
    UIButton *next;
    
    NSArray *newsItems;
    int currentItemIndex;
    
    UsersService *usersService;
}
@end

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
    
    prev = [UIButton buttonWithType:UIButtonTypeCustom];
    prev.frame = CGRectMake(103, 619, 131, 51);
    [prev setImage:[UIImage imageNamed:@"/images/news-panel/previous_button.png"] forState:UIControlStateNormal];
    [prev setImage:[UIImage imageNamed:@"/images/news-panel/previous_button_disabled.png"] forState:UIControlStateDisabled];
    [prev addTarget:self action:@selector(prev:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:prev];
    
    next = [UIButton buttonWithType:UIButtonTypeCustom];
    next.frame = CGRectMake(235, 619, 131, 51);
    [next setImage:[UIImage imageNamed:@"/images/news-panel/next_button.png"] forState:UIControlStateNormal];
    [next setImage:[UIImage imageNamed:@"/images/news-panel/next_button_disabled.png"] forState:UIControlStateDisabled];
    [next addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:next];
    
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(114, 233, 805, 367)];
    webView.opaque = NO;
    [webView.scrollView setBounces:NO];
    [self.view addSubview:webView];
    webView.delegate = self;
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    usersService = ac.usersService;
}

-(void)viewDidAppear:(BOOL)animated
{
    if (newsItems) [newsItems release];
    newsItems = [[usersService currentUserDateOrderedNewsItems] copy];
    
    currentItemIndex = [newsItems count] - 1;
    if (currentItemIndex < 1)
    {
        [self closePanel:nil]; // no news items to display!
    }
    else
    {
        [self showItemAtIndex:currentItemIndex];
    }
}

-(void)showItemAtIndex:(int)ix
{
    prev.enabled = ix > 0;
    next.enabled = ix < [newsItems count] - 1;
    
    NSDictionary *item = [newsItems objectAtIndex:ix];
    [webView loadHTMLString:item[@"html"] baseURL:nil];
    [usersService recordNewsItemView:item[@"id"]];
}

-(void)prev:(id)button
{
    [self showItemAtIndex:--currentItemIndex];
}

-(void)next:(id)button
{
    [self showItemAtIndex:++currentItemIndex];
}

-(void)closePanel:(id)button
{
    [self.view removeFromSuperview];
    if (self.delegate) [self.delegate newPanelWasClosed];
}


-(BOOL) webView:(UIWebView*)wv
    shouldStartLoadWithRequest:(NSURLRequest*)req
    navigationType:(UIWebViewNavigationType)navType
{
    if (navType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:[req URL]];
        return NO;
    }
    
    return YES;
}

-(void)dealloc
{
    self.delegate = nil;
    if (newsItems)
    {
        [newsItems release];
        newsItems = nil;
    }
    [super dealloc];
}

@end
