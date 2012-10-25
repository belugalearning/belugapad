//
//  EditPDefViewController.m
//  belugapad
//
//  Created by Nicholas Cartwright on 18/10/2012.
//
//

#import "EditPDefViewController.h"
#import "global.h"
#import "CCDirector.h"
#import "JSONKit.h"
#import "SSZipArchive.h"
#import "AppDelegate.h"
#import "ContentService.h"
#import "Problem.h"

@interface EditPDefViewController ()
{
    @private
    UIWebView *webView;
    id handlerInstance;
    SEL endEditAndTest;
    
    NSString *libraryDir;
    NSString *editPDefDir;
    
    ContentService *contentService;
}

@property (readwrite, retain) Problem *problem;

-(void)updateClientScripts;

@end


@implementation EditPDefViewController

- (id)initWithFrame:(CGRect)frame handlderInstance:(id)handler endEditAndTest:(SEL)endEditAndTestSel
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        contentService = [ac.contentService retain];
        self.problem = contentService.currentProblem;
        
        libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        editPDefDir = [libraryDir stringByAppendingPathComponent:@"edit-pdef-client-files"];
        
        handlerInstance = [handler retain];
        endEditAndTest = endEditAndTestSel;

        [self updateClientScripts];
        
        webView = [[UIWebView alloc] initWithFrame:frame];
        self.view = webView;
        webView.backgroundColor = [UIColor whiteColor];
        webView.opaque = YES;
        webView.delegate = self;
        
        NSURL *baseURL = [NSURL fileURLWithPath:editPDefDir];
        NSString *html = [NSString stringWithContentsOfFile:[editPDefDir stringByAppendingPathComponent:@"index.html"]
                                                   encoding:NSUTF8StringEncoding
                                                       error:nil];
        
        NSString *timeQuery = [NSString stringWithFormat:@".js?%f", [NSDate timeIntervalSinceReferenceDate]];
        NSString *htmlForceNoCacheJS = [html stringByReplacingOccurrencesOfString:@".js'" withString:timeQuery];
        
        [webView loadHTMLString:htmlForceNoCacheJS baseURL:baseURL];
    }
    return self;
}

-(BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *message = [[request URL] lastPathComponent];
    NSLog(@"EditPDefViewController handling message: %@", message);
    
    if ([@"ready" isEqualToString:message])
    {
        NSString *loadPDefCommand = [NSString stringWithFormat:@"appInterface.loadPDef(%@,%@,%d,%d)",
                                     [self.problem.pdef JSONString],
                                     self.problem.changeStack,
                                     self.problem.stackCurrentIndex,
                                     self.problem.stackLastSaveIndex];
        [webView stringByEvaluatingJavaScriptFromString:loadPDefCommand];
    }
    else if ([@"cancel" isEqualToString:message])
    {
        [handlerInstance performSelector:endEditAndTest withObject:NO];
    }
    else if ([@"test-edits" isEqualToString:message])
    {
        NSDictionary *editState = [[webView stringByEvaluatingJavaScriptFromString:@"appInterface.getState()"] objectFromJSONString];
        [self.problem updatePDef:[editState valueForKey:@"pdef"]
                  andChangeStack:[[editState valueForKey:@"changeStack"] JSONString]
               stackCurrentIndex:[[editState valueForKey:@"currStackIndex"] intValue]
              stackLastSaveIndex:[[editState valueForKey:@"lastSaveStackIndex"] intValue]];
        
        [handlerInstance performSelector:endEditAndTest withObject:YES];
    }
    
    return YES;
}

-(NSDictionary*)bodyDict:(NSData*)httpBody
{
    NSString *bodyString = [[[NSString alloc] initWithData:httpBody encoding:NSUTF8StringEncoding] autorelease];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    for (NSString *field in [bodyString componentsSeparatedByString:@"&"])
    {
        NSArray *kvPair = [field componentsSeparatedByString:@"="];
        NSString *key = [[[kvPair objectAtIndex:0] stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[[kvPair objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [dict setValue:val forKey:key];
    }
    return dict;
}


-(void)updateClientScripts
{
    NSString *bundledEditPDefDir = BUNDLE_FULL_PATH(@"/edit-pdef-client-files");    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL *url = [NSURL URLWithString:@"http://169.254.47.31:1234"]; // TODO: Update url to zubi.me ********************************************************************
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5];
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
    
    if (error || !response || [response statusCode] != 200)
    {
        NSString *resultString = [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Unable to update UIWebView client script -- %@", resultString);
    } else {
        NSString *zipPath = [libraryDir stringByAppendingPathComponent:@"/edit-pdef.zip"];
        [result writeToFile:zipPath atomically:YES];
        [SSZipArchive unzipFileAtPath:zipPath toDestination:editPDefDir];
    }
    
    if (![fm fileExistsAtPath:editPDefDir])
    {
        error = nil;
        [fm copyItemAtPath:bundledEditPDefDir toPath:editPDefDir error:&error];
    }
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

-(void)dealloc
{
    if (webView) [webView release];
    if (handlerInstance) [handlerInstance release];
    if (contentService) [contentService release];
    self.problem = nil;
    [super dealloc];
}

@end
