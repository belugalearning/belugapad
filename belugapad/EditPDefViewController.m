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

#if !RELEASE_MODE
-(void)updateClientScripts;
#endif

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
        
        libraryDir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] retain];
        editPDefDir = [[libraryDir stringByAppendingPathComponent:@"edit-pdef-client-files"] retain];
        
        handlerInstance = [handler retain];
        endEditAndTest = endEditAndTestSel;
        
#if !RELEASE_MODE
        // only web service serving client script updates is currently local to my machine, so comment out call below until updates available from zubi.me
        // [self updateClientScripts];
#endif
        
        // if haven't been able to get latest client scripts from server at least once, will need to copy bundled scripts into library
        NSString *bundledEditPDefDir = BUNDLE_FULL_PATH(@"/edit-pdef-client-files");
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:editPDefDir]) [fm copyItemAtPath:bundledEditPDefDir toPath:editPDefDir error:nil];
        
        self.view = webView = [[UIWebView alloc] initWithFrame:frame];
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
        [handlerInstance performSelector:endEditAndTest withObject:[NSNumber numberWithBool:NO]];
    }
    else if ([@"test-edits" isEqualToString:message])
    {
        [self localSaveEditState];
        [handlerInstance performSelector:endEditAndTest withObject:[NSNumber numberWithBool:YES]];
    }
    else if ([@"save" isEqualToString:message])
    {
        [self localSaveEditState];
        if ([self serverSaveCurrentProblemOverwritingRev:self.problem._rev])
        {
            [handlerInstance performSelector:endEditAndTest withObject:[NSNumber numberWithBool:YES]];
        }
    }
    else if ([@"save-override-conflict" isEqualToString:message])
    {
        NSString *query = [[request URL] query];
        if ([query hasPrefix:@"rev="])
        {
            if ([self serverSaveCurrentProblemOverwritingRev:[query substringFromIndex:4]])
            {
                [handlerInstance performSelector:endEditAndTest withObject:[NSNumber numberWithBool:YES]];
            }
        }
    }
    
    return YES;
}

-(void)localSaveEditState
{
    NSDictionary *editState = [[webView stringByEvaluatingJavaScriptFromString:@"appInterface.getState()"] objectFromJSONString];
    [self.problem updatePDef:[editState valueForKey:@"pdef"]
              andChangeStack:[[editState valueForKey:@"changeStack"] JSONString]
           stackCurrentIndex:[[editState valueForKey:@"currStackIndex"] intValue]
          stackLastSaveIndex:[[editState valueForKey:@"lastSaveStackIndex"] intValue]];
}

-(BOOL)serverSaveCurrentProblemOverwritingRev:(NSString*)rev
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    NSString *kcmLoginName = [ac.LocalSettings objectForKey:@"KCM_LOGIN_NAME"];
    
    NSURL *url = [NSURL URLWithString:@"app-edit-pdef" relativeToURL:contentService.kcmServerBaseURL];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setTimeoutInterval:7.0];
    [req setHTTPMethod: @"POST"];
    [req setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [req setHTTPBody:[@{
                      @"_id":self.problem._id
                      , @"_rev":rev
                      , @"pdef":self.problem.pdef
                      , @"userLoginName": kcmLoginName } JSONData]];
    
    NSError *error = nil;
    NSHTTPURLResponse *res = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&error];
    
    NSInteger statusCode = res ? [res statusCode] : 500;
    
    NSString *body = nil;
    if (data) body = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
    if (statusCode == 201)
    {
        // successs
        [self.problem updateOnSaveWithRevision:body];
        return YES;
    }
    
    NSString *errorString = error ? [error description] : nil;
    body = (body && [body JSONData]) ? [body JSONString] : nil;
    
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"appInterface.serverSaveCallback(%@, %d, %@)", errorString, statusCode, body]];
    return NO;
}

#if !RELEASE_MODE
-(void)updateClientScripts
{
    NSURL *url = [NSURL URLWithString:@"http://23.23.23.23:1234"]; // TODO: Update url (relative to ContentService.kcmServerBaseURL) ********************************************************************
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:2.0];
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
}
#endif

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
    if (libraryDir) [libraryDir release];
    if (editPDefDir) [editPDefDir release];
    if (handlerInstance) [handlerInstance release];
    if (contentService) [contentService release];
    self.problem = nil;
    [super dealloc];
}

@end
