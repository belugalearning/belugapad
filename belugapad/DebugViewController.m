//
//  DebugViewController.m
//  belugapad
//
//  Created by gareth on 06/10/2012.
//
//

#import "DebugViewController.h"

@interface DebugViewController ()

@end

@implementation DebugViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{    
    NSString *us=request.URL.absoluteString;
    NSLog(@"handling link to %@", us);
    
    if([us rangeOfString:@"belugadebug://skip"].location != NSNotFound)
    {
        NSNumberFormatter *nf=[[[NSNumberFormatter alloc] init] autorelease];
        NSNumber *skipCount=[nf numberFromString:[us substringFromIndex:19]];
        [self.handlerInstance performSelector:self.skipProblemMethod withObject:skipCount];
    }
    
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
