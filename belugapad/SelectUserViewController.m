//
//  SelectUserViewController.m
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SelectUserViewController.h"
#import "global.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "UsersService.h"
#import "PassCodeView.h"
#import "UIView+UIView_DragLogPosition.h"

@interface SelectUserViewController ()
{
    @private
    AppController *app;
    UsersService *usersService;
    
    // select user
    UIView *selectUserView;
    UITableView *selectUserTableView;
    UIButton *playButton;
    UIButton *joinClassButton;
    
    UIImageView *selectUserModalUnderlay;
    UIImageView *selectUserModalBgView;
    PassCodeView *selectUserPassCodeModalView;
    UIButton *backToSelectUserButton;
    UIButton *loginButton;
    UIImageView *tickCrossImg;
    
    NSMutableArray *deviceUsers;
    
    // new user
    UIView *editUserView;
    UITextField *newUserNameTF;
    PassCodeView *newUserPassCodeView;
    UIButton *cancelNewUserButton;
    UIButton *saveNewUserButton;
    
    // sync user
    UIView *loadExistingUserView;
    UITextField *existingUserNameTF;
    PassCodeView *downloadUserPassCodeView;
    UIButton *cancelExistingUserButton;
    UIButton *loadExistingUserButton;
    
    UIImageView *loadingImg;
    
    BOOL freezeUI;
}
-(void) loadDeviceUsers;
-(void) buildSelectUserView;
-(void) buildEditUserView;
-(void) setActiveView:(UIView *)view;
@end

@implementation SelectUserViewController

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    app = (AppController*)[[UIApplication sharedApplication] delegate];
    usersService = app.usersService;
    
    [app.loggingService logEvent:BL_SUVC_LOAD withAdditionalData:nil];
    
    [app.usersService syncDeviceUsers];
    [app.loggingService sendData];
    
    [self loadDeviceUsers];
    
    backgroundImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:(@"/login-images/Island_BG.png")]] autorelease];
    [self.view addSubview:backgroundImageView];
    
    UIImageView *bgOverlay = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/BG_Shade.png"]] autorelease];
    [self.view addSubview:bgOverlay];
    
    CGRect frame = self.view.frame;
    
    selectUserView = [[[UIView alloc] initWithFrame:frame] autorelease];
    [self.view addSubview:selectUserView];
    [self buildSelectUserView];
    
    editUserView = [[[UIView alloc] initWithFrame:frame] autorelease];
    [self.view addSubview:editUserView];
    [self buildEditUserView];
    
    loadExistingUserView = [[[UIView alloc] initWithFrame:frame] autorelease];
    [self.view addSubview:loadExistingUserView];
    [self buildLoadExistingUserView];
    
    [self setActiveView:selectUserView];
    
    loadingImg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/loadwheel.png"]] autorelease];
    [loadingImg setCenter:CGPointMake(706,429)];
    [self.view addSubview:loadingImg];
    loadingImg.alpha = 0;
    
    CABasicAnimation* rotationAnimation;
    double secsPerRev = 1;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = secsPerRev;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [loadingImg.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return  YES;
}

-(void)setActiveView:(UIView *)view
{
    [selectUserView setHidden:(view != selectUserView)];
    [editUserView setHidden:(view != editUserView)];
    [loadExistingUserView setHidden:(view != loadExistingUserView)];
}

#pragma mark -
#pragma mark SelectUserView

-(void)loadDeviceUsers
{
    if (deviceUsers) [deviceUsers release];
    AppController *ad = (AppController*)[[UIApplication sharedApplication] delegate];
    deviceUsers = [[ad.usersService deviceUsersByNickName] retain];
    while ([deviceUsers count] < 4) [deviceUsers addObject:@{}]; // add fake users -> produce extra table cells -> create alternating table cell background appearance
}

-(void)buildSelectUserView
{
    UIImageView *panel = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/select_user_BG.png"]] autorelease];
    [panel setCenter:CGPointMake(511.0f, 377.0f)];
    [selectUserView addSubview:panel];
    
    selectUserTableView = [[[UITableView alloc] initWithFrame:CGRectMake(322.0f,247.0f,378.0f,137.0f) style:UITableViewStylePlain] autorelease];
    selectUserTableView.backgroundColor = [UIColor clearColor];
    selectUserTableView.opaque = YES;
    selectUserTableView.backgroundView = nil;
    selectUserTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    selectUserTableView.dataSource = self;
    selectUserTableView.delegate = self;
    [selectUserView addSubview:selectUserTableView];
    
    UIImageView *mask = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/table-mask.png"]] autorelease];
    mask.frame = CGRectMake(320.0f,243.0f,381.0f,146.0f);
    [selectUserView addSubview:mask];
    
    UIButton *newUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newUserButton.frame = CGRectMake(331.0f, 403.0f, 131.0f, 51.0f);
    [newUserButton setImage:[UIImage imageNamed:@"/login-images/new_button.png"] forState:UIControlStateNormal];
    [newUserButton addTarget:self action:@selector(handleNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:newUserButton];
    
    UIButton *existingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    existingUserButton.frame = CGRectMake(559.0f, 404.0f, 131.0f, 51.0f);
    [existingUserButton setImage:[UIImage imageNamed:@"/login-images/download_button.png"] forState:UIControlStateNormal];
    [existingUserButton addTarget:self action:@selector(handleExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:existingUserButton];
    
    playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(698.0f, 502.0f, 138.0f, 66.0f);
    [playButton setImage:[UIImage imageNamed:@"/login-images/play_button_disabled.png"] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"/login-images/play_button_disabled.png"] forState:UIControlStateHighlighted];
    [playButton addTarget:self action:@selector(handlePlayButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [playButton addTarget:self action:@selector(handlePlayButtonTouchEnd:) forControlEvents:UIControlEventTouchUpOutside];
    [playButton addTarget:self action:@selector(handlePlayButtonTouchEnd:) forControlEvents:UIControlEventTouchUpInside];
    [playButton addTarget:self action:@selector(handlePlayButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:playButton];
    playButton.enabled = NO;
    
    joinClassButton = [UIButton buttonWithType:UIButtonTypeCustom];
    joinClassButton.frame = CGRectMake(220.0f, 447.0f, 100.0f, 95.0f);
    [joinClassButton setImage:[UIImage imageNamed:@"/login-images/join_class_button_disabled.png"] forState:UIControlStateNormal];
    [joinClassButton setImage:[UIImage imageNamed:@"/login-images/join_class_button_disabled.png"] forState:UIControlStateHighlighted];
    [selectUserView addSubview:joinClassButton];
}

-(void)enablePlayButton
{
    playButton.enabled = YES;
    [playButton setImage:[UIImage imageNamed:@"/login-images/play_button_enabled.png"] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"/login-images/play_button_enabled.png"] forState:UIControlStateHighlighted];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [deviceUsers count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 38;
}

-(UITableViewCell*)tableView:(UITableView *)tableView
       cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *user = deviceUsers[indexPath.row];
    NSString *nickName = user[@"nickName"]; // nil if this is just a placeholder cell
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSeparatorStyleNone;
        cell.backgroundView.contentMode = UIViewContentModeLeft;
        cell.textLabel.contentMode = UIViewContentModeLeft;
        cell.textLabel.font = [UIFont fontWithName:@"Chango" size:24];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:indexPath.row % 2 == 0 ? @"/login-images/table_cell_black.png" : @"/login-images/table_cell_transparent"]] autorelease];
    
    if (!nickName)
    {
        // just a placeholder cell to maintain the alternating cell background look
        cell.selectedBackgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else
    {
        cell.selectedBackgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/table_cell_orange.png"]] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    cell.textLabel.text = nickName ? nickName : @"";
    cell.imageView.image = nil;
    return cell;
 }

#pragma mark UITableViewDelegate

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // return nil & prevent selection if 'fake user' (placeholder that keeps the alertnating cell background look).
    return deviceUsers[[indexPath row]][@"nickName"] ? indexPath : nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *user = deviceUsers[indexPath.row];
    if (user[@"nickName"]) [self enablePlayButton];// i.e. a real user, not empty one
}

#pragma mark interactions
-(void)handlePlayButtonTouchDown:(id)button
{
    if (freezeUI) return;
    ((UIButton*)button).transform = CGAffineTransformMakeScale(1.2, 1.2);
}

-(void)handlePlayButtonTouchEnd:(id)button
{
    if (freezeUI) return;
    ((UIButton*)button).transform = CGAffineTransformIdentity;
}

-(void)handlePlayButtonClicked:(id)button
{
    if (freezeUI) return;
    
    NSIndexPath *ip = [selectUserTableView indexPathForSelectedRow];

    if (selectUserModalBgView) return;
    
    // TEMP
    // N.B. Next few lines are a temp way of allowing users who don't yet have valid passcodes to continue to login (i.e. we don't ask them for their passcode)
    NSDictionary *ur = deviceUsers[ip.row];
    NSRegularExpression *m = [[NSRegularExpression alloc] initWithPattern:@"^\\d{4}$" options:0 error:nil];
    if (![m numberOfMatchesInString:ur[@"password"] options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, [ur[@"password"] length])])
    {
        [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(loginUser:) userInfo:@{ @"urId":ur[@"id"] } repeats:NO];
        return;
    }
    
    selectUserModalUnderlay = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/BG_Shade.png"]] autorelease];
    selectUserModalUnderlay.userInteractionEnabled = YES; // prevents buttons behind modal view from receiving touch events
    [self.view addSubview:selectUserModalUnderlay];
    
    CGPoint p = CGPointMake(512.0f, 354.0f);
    
    selectUserModalBgView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/passcode_modal.png"]] autorelease];
    selectUserModalBgView.center = p;
    [self.view addSubview:selectUserModalBgView];
    
    selectUserPassCodeModalView = [[[PassCodeView alloc] initWithFrame:CGRectMake(387.0f, 327.0f, 245.0f, 46.0f)] autorelease];
    selectUserPassCodeModalView.delegate = self;
    [self.view addSubview:selectUserPassCodeModalView];
    
    backToSelectUserButton = [[[UIButton alloc] init] autorelease];
    backToSelectUserButton.frame = CGRectMake(322.0f, 394.0f, 131.0f, 51.0f);
    [backToSelectUserButton setImage:[UIImage imageNamed:@"/login-images/back_button.png"] forState:UIControlStateNormal];
    [backToSelectUserButton addTarget:self action:@selector(handleBackToSelectUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:backToSelectUserButton];
    
    loginButton = [[[UIButton alloc] init] autorelease];
    loginButton.frame = CGRectMake(577.0f, 394.0f, 131.0f, 51.0f);
    [loginButton setImage:[UIImage imageNamed:@"/login-images/login_button_grey.png"] forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(handleLoginButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loginButton];
    
    tickCrossImg = [[[UIImageView alloc] initWithFrame:CGRectMake(651, 344, 22, 17)] autorelease];
    [self.view addSubview:tickCrossImg];
}

-(void)handleBackToSelectUserClicked:(id)button
{
    if (freezeUI) return;
    
    [selectUserModalUnderlay removeFromSuperview];
    selectUserModalUnderlay = nil;
    [selectUserModalBgView removeFromSuperview];
    selectUserModalBgView = nil;
    [selectUserPassCodeModalView removeFromSuperview];
    selectUserPassCodeModalView = nil;
    [backToSelectUserButton removeFromSuperview];
    backToSelectUserButton = nil;
    [loginButton removeFromSuperview];
    loginButton = nil;
    [tickCrossImg removeFromSuperview];
    tickCrossImg = nil;
}

-(void)handleLoginButtonClicked:(id)button
{
    if (freezeUI) return;
    
    if (!selectUserPassCodeModalView.isValid)
    {
        [tickCrossImg setImage:[UIImage imageNamed:@"/login-images/wrong_cross.png"]];
        tickCrossImg.alpha = 1;
        [selectUserPassCodeModalView becomeFirstResponder];
        return;
    }
    
    NSIndexPath *ip = [selectUserTableView indexPathForSelectedRow];
    NSDictionary *ur = deviceUsers[ip.row];
    
    if ([ur[@"password"] isEqualToString:selectUserPassCodeModalView.text])
    {
        [tickCrossImg setImage:[UIImage imageNamed:@"/login-images/correct_tick.png"]];
        tickCrossImg.alpha = 1;
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loginUser:) userInfo:@{ @"urId":ur[@"id"] } repeats:NO];
        [backToSelectUserButton removeTarget:self action:@selector(handleBackToSelectUserClicked:) forControlEvents:UIControlEventTouchUpInside];
        [loginButton removeTarget:self action:@selector(handleLoginButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [tickCrossImg setImage:[UIImage imageNamed:@"/login-images/wrong_cross.png"]];
        tickCrossImg.alpha = 1;
        [selectUserPassCodeModalView clearText];
    }
}

-(void)loginUser:(NSTimer*)timer
{
    [usersService setCurrentUserToUserWithId:[timer userInfo][@"urId"]];
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:NO];
}

-(void)handleNewUserClicked:(id)button
{
    if (freezeUI) return;
    [self setActiveView:editUserView];
}

-(void)handleExistingUserClicked:(id)button
{
    if (freezeUI) return;
    [self setActiveView:loadExistingUserView];
}

#pragma mark -
#pragma mark EditUserView

-(void)buildEditUserView
{
    UIImageView *panel = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/sign_up_BG.png"]] autorelease];
    [panel setCenter:CGPointMake(511.0f, 377.0f)];
    [editUserView addSubview:panel];
    
    newUserNameTF = [[[UITextField alloc] initWithFrame:CGRectMake(334.0f, 288.0f, 360.0f, 42.0f)] autorelease];
    newUserNameTF.delegate = self;
    newUserNameTF.font = [UIFont fontWithName:@"Chango" size:24];
    newUserNameTF.placeholder = @"Name";
    newUserNameTF.clearButtonMode = UITextFieldViewModeNever;
    newUserNameTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    newUserNameTF.autocorrectionType = UITextAutocorrectionTypeNo;
    newUserNameTF.keyboardType = UIKeyboardTypeNamePhonePad;
    newUserNameTF.returnKeyType = UIReturnKeyDone;
    [newUserNameTF setTextColor:[UIColor whiteColor]];
    [newUserNameTF setBorderStyle:UITextBorderStyleNone];
    [editUserView addSubview:newUserNameTF];
    
    newUserPassCodeView = [[[PassCodeView alloc] initWithFrame:CGRectMake(389.0f, 341.0f, 245.0f, 46.0f)] autorelease];
    newUserPassCodeView.delegate = self;
    [editUserView addSubview:newUserPassCodeView];
    [newUserPassCodeView registerForDragAndLog];
    
    cancelNewUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelNewUserButton.frame = CGRectMake(330.0f, 407.0f, 103.0f, 49.0f);
    [cancelNewUserButton setImage:[UIImage imageNamed:@"/login-images/cancel_button.png"] forState:UIControlStateNormal];
    [cancelNewUserButton addTarget:self action:@selector(handleCancelNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [editUserView addSubview:cancelNewUserButton];
    
    saveNewUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveNewUserButton.frame = CGRectMake(591.0f, 407.0f, 103.0f, 49.0f);
    [saveNewUserButton setImage:[UIImage imageNamed:@"/login-images/save_button.png"] forState:UIControlStateNormal];
    [saveNewUserButton addTarget:self action:@selector(handleSaveNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [editUserView addSubview:saveNewUserButton];
}

-(void)handleCancelNewUserClicked:(id)button
{
    if (freezeUI) return;
    newUserNameTF.text = @"";
    [newUserPassCodeView clearText];
    [newUserNameTF resignFirstResponder];
    [newUserPassCodeView resignFirstResponder];
    [self setActiveView:selectUserView];
}

-(void)handleSaveNewUserClicked:(id)button
{
    if (freezeUI) return;
    
    if (!newUserNameTF.text || !newUserNameTF.text.length)
    {
        [newUserNameTF becomeFirstResponder];
        return;
    }
    
    if (!newUserPassCodeView.isValid)
    {
        [newUserPassCodeView becomeFirstResponder];
        return;
    }
    
    __block typeof(self) bself = self;
    __block NSString *bnick = newUserNameTF.text;
    void (^createSetUrCallback)() = ^(BL_USER_CREATION_STATUS status) {
        bself->loadingImg.alpha = 0;
        bself->freezeUI = NO;
        
        if (BL_USER_CREATION_FAILURE_NICK_UNAVAILABLE == status)
        {
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Sorry"
                                                                 message:@"This nickname is already in use. Please try another one."
                                                                delegate:bself
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] autorelease];
            [alertView show];
        }
        else if (BL_USER_CREATION_SUCCESS_NICK_AVAILABLE == status || BL_USER_CREATION_SUCCESS_NICK_AVAILABILITY_UNCONFIRMED == status)
        {
            newUserNameTF.text = @"";
            [newUserPassCodeView clearText];
            
            [bself loadDeviceUsers];
            [bself->selectUserTableView reloadData];
            for (uint i=0; i<[bself->deviceUsers count]; i++)
            {
                if ([bnick isEqualToString:[[bself->deviceUsers objectAtIndex:i] valueForKey:@"nickName"]])
                {
                    NSUInteger indexPath[] = {0,i};
                    NSIndexPath *ip = [NSIndexPath indexPathWithIndexes:indexPath length:2];
                    [bself->selectUserTableView selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionNone];
                    [bself enablePlayButton];
                    break;
                }
            }
            [bself setActiveView:selectUserView];
        }
    };
    
    loadingImg.alpha = 1;
    freezeUI = YES;
    
    [usersService createNewUserWithNick:newUserNameTF.text
                            andPassword:newUserPassCodeView.text
                               callback:createSetUrCallback];
}

#pragma mark -
#pragma mark LoadExistingUserView;

-(void)buildLoadExistingUserView
{
    UIImageView *panel = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/sync_account_BG.png"]] autorelease];
    [panel setCenter:CGPointMake(511.0f, 377.0f)];
    [loadExistingUserView addSubview:panel];
    
    existingUserNameTF = [[[UITextField alloc] initWithFrame:CGRectMake(334.0f, 288.0f, 360.0f, 42.0f)] autorelease];
    existingUserNameTF.delegate = self;
    existingUserNameTF.font = [UIFont fontWithName:@"Chango" size:24];
    existingUserNameTF.placeholder = @"Name";
    existingUserNameTF.clearButtonMode = UITextFieldViewModeNever;
    existingUserNameTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    existingUserNameTF.autocorrectionType = UITextAutocorrectionTypeNo;
    existingUserNameTF.keyboardType = UIKeyboardTypeNamePhonePad;
    existingUserNameTF.returnKeyType = UIReturnKeyDone;
    [existingUserNameTF setTextColor:[UIColor whiteColor]];
    [existingUserNameTF setBorderStyle:UITextBorderStyleNone];
    [loadExistingUserView addSubview:existingUserNameTF];
    
    downloadUserPassCodeView = [[[PassCodeView alloc] initWithFrame:CGRectMake(388.0f, 344.0f, 255.0f, 46.0f)] autorelease];
    downloadUserPassCodeView.delegate = self;
    [loadExistingUserView addSubview:downloadUserPassCodeView];
    
    cancelExistingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelExistingUserButton.frame = CGRectMake(330.0f, 402.0f, 131.0f, 51.0f);
    [cancelExistingUserButton setImage:[UIImage imageNamed:@"/login-images/cancel_button_2.png"] forState:UIControlStateNormal];
    [cancelExistingUserButton addTarget:self action:@selector(handleCancelExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [loadExistingUserView addSubview:cancelExistingUserButton];
    
    loadExistingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loadExistingUserButton.frame = CGRectMake(563.0f, 401.0f, 131.0f, 51.0f);
    [loadExistingUserButton setImage:[UIImage imageNamed:@"/login-images/download_button.png"] forState:UIControlStateNormal];
    [loadExistingUserButton addTarget:self action:@selector(handleLoadExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [loadExistingUserView addSubview:loadExistingUserButton];
}

-(void)handleCancelExistingUserClicked:(id)button
{
    if (freezeUI) return;
    existingUserNameTF.text = @"";
    [downloadUserPassCodeView clearText];
    [existingUserNameTF resignFirstResponder];
    [downloadUserPassCodeView resignFirstResponder];
    [self setActiveView:selectUserView];
}

-(void)handleLoadExistingUserClicked:(id)button
{
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Sorry"
                                 message:@"We could not find a match for those login details. Please double-check and try again."
                                delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles:nil] autorelease];
    
    if (freezeUI) return;
    
    __block typeof(self) bself = self;
    void (^callback)() = ^(NSDictionary *ur) {
        bself->loadingImg.alpha = 0;
        bself->freezeUI = NO;
        
        if (!ur)
        {
            [alertView show];
            return;

        }
        
        [bself->usersService setCurrentUserToUserWithId:[ur objectForKey:@"id"]];        
        [self.view removeFromSuperview];
        [bself->app proceedFromLoginViaIntro:NO];
    };
    
    if (!existingUserNameTF.text || !existingUserNameTF.text.length)
    {
        [existingUserNameTF becomeFirstResponder];
        return;
    }
    
    if (!downloadUserPassCodeView.isValid)
    {
        [downloadUserPassCodeView becomeFirstResponder];
        return;
    }
    
    loadingImg.alpha = 1;    
    freezeUI = YES;
    
    [usersService downloadUserMatchingNickName:existingUserNameTF.text
                                   andPassword:downloadUserPassCodeView.text
                                      callback:callback];
}


#pragma mark -
#pragma mark PassCodeViewDelegate
-(void)passCodeWasEdited:(PassCodeView*)passCodeView
{
    if (passCodeView == selectUserPassCodeModalView) tickCrossImg.alpha = 0;
}

-(void)passCodeBecameInvalid:(PassCodeView*)passCodeView
{
}

-(void)passCodeBecameValid:(PassCodeView*)passCodeView
{
}

#pragma mark -
#pragma mark lose keyboard focus when tapping outside textfield
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIView *firstResponder = [self findFirstResponderWithin:self.view];
    if (firstResponder && ([firstResponder isKindOfClass:[UITextField class]] || [firstResponder isKindOfClass:[PassCodeView class]]))
    {
        [firstResponder resignFirstResponder];
    }
}

-(UIView*)findFirstResponderWithin:(UIView*)view
{
    if (view.isFirstResponder) return view;
    for (UIView *subView in view.subviews)
    {
        UIView *firstResponder = [self findFirstResponderWithin:subView];
        if (firstResponder) return firstResponder;
    }
    return nil;
}

#pragma mark -
#pragma mark Destruction

-(void)dealloc
{
    if (deviceUsers)[deviceUsers release];
    [super dealloc];
}
@end
