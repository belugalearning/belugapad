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
#import "SimpleAudioEngine.h"
#import "UIView+UIView_DragLogPosition.h"
#import "CODialog.h"

@interface SelectUserViewController ()
{
    @private
    AppController *app;
    UsersService *usersService;
    
    // select user
    UIView *selectUserView;
    UIImageView *selectUserBG;
    UILabel *noUsersAdvisoryText;
    UITableView *selectUserTableView;
    UIImageView *selectUserTableMask;
    UIButton *playButton;
    UIButton *joinClassButton;
    
    UIImageView *selectUserModalUnderlay;
    UIView *selectUserModalContainer;
    UIButton *loginButton;
    PassCodeView *selectUserPassCodeModalView;
    UIImageView *tickCrossImg;
    
    NSMutableArray *deviceUsers;
    
    // new user
    UIView *editUserView;
    UITextField *newUserNameTF;
    PassCodeView *newUserPassCodeView;
    UIButton *cancelNewUserButton;
    UIButton *saveNewUserButton;
    
    // download user
    UIView *loadExistingUserView;
    UITextField *existingUserNameTF;
    PassCodeView *downloadUserPassCodeView;
    UIButton *cancelExistingUserButton;
    UIButton *loadExistingUserButton;
    
    // change nick
    UILabel *nickTakenLabel;
    UIView *changeNickView;
    UITextField *changeNickTF;
    UIButton *cancelChangeNickButton;
    UIButton *saveChangeNickButton;
    
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
    
    CGRect frame = CGRectMake(0, 0, 1024, 768);
    
    selectUserView = [[[UIView alloc] initWithFrame:frame] autorelease];
    [self.view addSubview:selectUserView];
    [self buildSelectUserView];
    [selectUserView setHidden:YES];
    
    editUserView = [[[UIView alloc] initWithFrame:frame] autorelease];
    [self.view addSubview:editUserView];
    [self buildEditUserView];
    [editUserView setHidden:YES];
    
    loadExistingUserView = [[[UIView alloc] initWithFrame:frame] autorelease];
    [self.view addSubview:loadExistingUserView];
    [self buildLoadExistingUserView];
    [loadExistingUserView setHidden:YES];

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
    
    selectUserView.center = CGPointMake(512, -312);
    editUserView.center = loadExistingUserView.center = CGPointMake(1408, 384);
    
    bgOverlay.alpha = 0.0;
    [UIView animateWithDuration:0.8
                     animations:^{ bgOverlay.alpha = 1.0; }];
    
    
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
     
                     animations:^{
                         selectUserView.center = CGPointMake(512, 384);
                     }
                     completion:^(BOOL finished){ }];
    
}

-(void)buttonTap
{
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_button_tap.wav")];
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
    freezeUI = YES;
    
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_login_transition.wav")];
    
    UIView *currentView = nil;
    if (![selectUserView isHidden])
    {
        currentView = selectUserView;
    }
    else if (![editUserView isHidden])
    {
        currentView = editUserView;
    }
    else if (![loadExistingUserView isHidden])
    {
        currentView = loadExistingUserView;
    }
    
    __block BOOL currentViewAnimating = currentView != nil;;
    __block BOOL nextViewAnimating = view != nil;
    
    // animate currentView off screen and hide
    if (currentView)
    {        
        [UIView animateWithDuration:1.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                        animations:^{
                            if (currentView == selectUserView)
                            {
                                currentView.center = CGPointMake(-512, 384);
                            }
                            else
                            {
                                currentView.center = CGPointMake(1408, 384);
                            }
                         }
                         completion:^(BOOL finished){
                             [currentView setHidden:YES];
                             currentViewAnimating = NO;
                             freezeUI = nextViewAnimating;
                             
                             if (currentView == loadExistingUserView)
                             {
                                 existingUserNameTF.text = @"";
                                 [downloadUserPassCodeView clearText];
                             }
                             else if (currentView == editUserView)
                             {
                                 newUserNameTF.text = @"";
                                 [newUserPassCodeView clearText];
                             }
                         }];
    }
    
    // animate next view into position
    if (view)
    {
        if (view == selectUserView)
        {
            BOOL deviceHasUsers = [deviceUsers count] && [((NSDictionary*)deviceUsers[0]) count];
            [selectUserBG setImage:[UIImage imageNamed:deviceHasUsers ? @"/login-images/select_user_BG.png" : @"/login-images/Create_account_BG.png"]];
            [noUsersAdvisoryText setHidden:deviceHasUsers];
            [selectUserTableView setHidden:!deviceHasUsers];
            [selectUserTableMask setHidden:!deviceHasUsers];
            [joinClassButton setHidden:!deviceHasUsers];
            [playButton setHidden:!deviceHasUsers];
        }
        
        [view setHidden:NO];
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                            view.center = CGPointMake(512, 384);
                         }
                         completion:^(BOOL finished){
                             nextViewAnimating = NO;
                             freezeUI = currentViewAnimating;
                         }];
    
    }
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
    selectUserBG = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/select_user_BG.png"]] autorelease];
    selectUserBG.center = CGPointMake(512, 364);
    [selectUserView addSubview:selectUserBG];
    
    noUsersAdvisoryText = [[[UILabel alloc] initWithFrame:CGRectMake(237, 286, 550, 50)] autorelease];
    noUsersAdvisoryText.text = @"CREATE AN ACCOUNT TO BEGIN YOUR JOURNEY THROUGH THE WORLD OF MATHS";
    noUsersAdvisoryText.lineBreakMode = UILineBreakModeWordWrap;
    noUsersAdvisoryText.numberOfLines = 2;
    noUsersAdvisoryText.textAlignment = UITextAlignmentCenter;
    noUsersAdvisoryText.textColor = [UIColor whiteColor];
    noUsersAdvisoryText.backgroundColor = [UIColor clearColor];
    noUsersAdvisoryText.shadowColor = [UIColor blackColor];
    noUsersAdvisoryText.shadowOffset = CGSizeMake(2,2);
    noUsersAdvisoryText.font = [UIFont fontWithName:@"Chango" size:16];
    [noUsersAdvisoryText setTransform:CGAffineTransformMakeRotation(-M_PI / 160)];
    [selectUserView addSubview:noUsersAdvisoryText];
    
    selectUserTableView = [[[UITableView alloc] initWithFrame:CGRectMake(322.0f,247.0f,378.0f,137.0f) style:UITableViewStylePlain] autorelease];
    selectUserTableView.backgroundColor = [UIColor clearColor];
    selectUserTableView.opaque = YES;
    selectUserTableView.backgroundView = nil;
    selectUserTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    selectUserTableView.dataSource = self;
    selectUserTableView.delegate = self;
    [selectUserView addSubview:selectUserTableView];
    
    selectUserTableMask = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/table-mask.png"]] autorelease];
    selectUserTableMask.frame = CGRectMake(320.0f,243.0f,381.0f,146.0f);
    [selectUserView addSubview:selectUserTableMask];
    
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
    
    changeNickView = [[UIView alloc]  initWithFrame:CGRectMake(0, 0, 699, 459)];
    [changeNickView setCenter:CGPointMake(511.0f, 377.0f)];
    UIImageView *changeNickBG = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/change_username_bg.png"]] autorelease];
    [changeNickView addSubview:changeNickBG];
    
    nickTakenLabel = [[[UILabel alloc] initWithFrame:CGRectMake(56, 113, 360.0f, 42.0f)] autorelease];
    nickTakenLabel.font = [UIFont fontWithName:@"Chango" size:24];
    nickTakenLabel.text = @"Name Taken!";
    [nickTakenLabel setTextColor:[UIColor whiteColor]];
    [nickTakenLabel setBackgroundColor:[UIColor clearColor]];
    [changeNickView addSubview:nickTakenLabel];
    
    changeNickTF = [[[UITextField alloc] initWithFrame:CGRectMake(56, 163, 360.0f, 42.0f)] autorelease];
    changeNickTF.delegate = self;
    changeNickTF.font = [UIFont fontWithName:@"Chango" size:24];
    changeNickTF.clearButtonMode = UITextFieldViewModeNever;
    changeNickTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    changeNickTF.autocorrectionType = UITextAutocorrectionTypeNo;
    changeNickTF.keyboardType = UIKeyboardTypeNamePhonePad;
    changeNickTF.returnKeyType = UIReturnKeyDone;
    [changeNickTF setTextColor:[UIColor whiteColor]];
    [changeNickTF setBorderStyle:UITextBorderStyleLine];
    [changeNickView addSubview:changeNickTF];
    
    cancelChangeNickButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelChangeNickButton setImage:[UIImage imageNamed:@"/login-images/cancel_button_2.png"] forState:UIControlStateNormal];
    cancelChangeNickButton.frame = CGRectMake(57, 246, 131, 51);
    [cancelChangeNickButton addTarget:self action:@selector(handleCancelChangeNickClicked:) forControlEvents:UIControlEventTouchUpInside];
    [changeNickView addSubview:cancelChangeNickButton];
    
    saveChangeNickButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveChangeNickButton setImage:[UIImage imageNamed:@"/login-images/change_button.png"] forState:UIControlStateNormal];
    saveChangeNickButton.frame = CGRectMake(289, 246, 131, 51);
    [saveChangeNickButton addTarget:self action:@selector(handleSaveChangeNickClicked:) forControlEvents:UIControlEventTouchUpInside];
    [changeNickView addSubview:saveChangeNickButton];
    
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
    if (user[@"nickName"]){
        [self buttonTap];
        [self enablePlayButton];
    }// i.e. a real user, not empty one
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

    if (selectUserModalContainer) return;
    
    [self buttonTap];
    
    // TEMP way of allowing users who don't yet have valid passcodes to continue to login (i.e. we don't ask them for their passcode)
    NSDictionary *ur = deviceUsers[ip.row];
    NSRegularExpression *m = [[[NSRegularExpression alloc] initWithPattern:@"^\\d{4}$" options:0 error:nil] autorelease];
    if (![m numberOfMatchesInString:ur[@"password"] options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, [ur[@"password"] length])])
    {
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loginUser:) userInfo:ur repeats:NO];
        return;
    }
    // -----------------
    
    selectUserModalUnderlay = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/BG_Shade.png"]] autorelease];
    selectUserModalUnderlay.userInteractionEnabled = YES; // prevents buttons behind modal view from receiving touch events
    [self.view addSubview:selectUserModalUnderlay];
    
    selectUserModalContainer = [[[UIView alloc] initWithFrame:CGRectMake(286, -283, 452, 283)] autorelease];
    [self.view addSubview:selectUserModalContainer];
    
    UIView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/passcode_modal.png"]] autorelease];
    [selectUserModalContainer addSubview:bg];
    
    UILabel *nameLabel = [[[UILabel alloc] initWithFrame:CGRectMake(44, 67, 359, 30)] autorelease];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.font = [UIFont fontWithName:@"Chango" size:24];
    nameLabel.textAlignment = UITextAlignmentCenter;
    nameLabel.text = ur[@"nickName"];
    [selectUserModalContainer addSubview:nameLabel];
    
    UIButton *back = [[[UIButton alloc] init] autorelease];
    back.frame = CGRectMake(36.0f, 181.0f, 131.0f, 51.0f);
    [back setImage:[UIImage imageNamed:@"/login-images/back_button.png"] forState:UIControlStateNormal];
    [back addTarget:self action:@selector(handleBackToSelectUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserModalContainer addSubview:back];
    
    loginButton = [[[UIButton alloc] init] autorelease];
    loginButton.frame = CGRectMake(289.0f, 181.0f, 131.0f, 51.0f);
    [loginButton setImage:[UIImage imageNamed:@"/login-images/login_button_grey.png"] forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(handleLoginButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserModalContainer addSubview:loginButton];
    
    selectUserPassCodeModalView = [[[PassCodeView alloc] initWithFrame:CGRectMake(100, 115, 245.0f, 46.0f)] autorelease];
    selectUserPassCodeModalView.delegate = self;
    [selectUserModalContainer addSubview:selectUserPassCodeModalView];
    
    tickCrossImg = [[[UIImageView alloc] initWithFrame:CGRectMake(651, 344, 22, 17)] autorelease];
    [self.view addSubview:tickCrossImg];
    
    [UIView animateWithDuration:0.8
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         selectUserModalContainer.center = CGPointMake(512.0f, 354.0f);
                     }
                     completion:^(BOOL finished){
                         [selectUserPassCodeModalView becomeFirstResponder];
                     }];
}

-(void)handleBackToSelectUserClicked:(id)button
{
    if (freezeUI) return;
    
    [self buttonTap];
    
    [selectUserModalUnderlay removeFromSuperview];
    selectUserModalUnderlay = nil;
    [button removeFromSuperview];
    loginButton = nil;
    selectUserPassCodeModalView = nil;
    [selectUserModalContainer removeFromSuperview];
    selectUserModalContainer = nil;
    [tickCrossImg removeFromSuperview];
    tickCrossImg = nil;
}

-(void)handleLoginButtonClicked:(id)button
{
    if (freezeUI) return;
    
    
    if (!selectUserPassCodeModalView.isValid)
    {
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_login_failure.wav")];
        [tickCrossImg setImage:[UIImage imageNamed:@"/login-images/wrong_cross.png"]];
        tickCrossImg.alpha = 1;
        [selectUserPassCodeModalView becomeFirstResponder];
        return;
    }
    
    NSIndexPath *ip = [selectUserTableView indexPathForSelectedRow];
    NSDictionary *ur = deviceUsers[ip.row];
    
    if ([ur[@"password"] isEqualToString:selectUserPassCodeModalView.text])
    {
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_login_success.wav")];
        [tickCrossImg setImage:[UIImage imageNamed:@"/login-images/correct_tick.png"]];
        tickCrossImg.alpha = 1;
        freezeUI = YES;
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loginUser:) userInfo:ur repeats:NO];
    }
    else
    {
        [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_journey_map_general_login_failure.wav")];
        [tickCrossImg setImage:[UIImage imageNamed:@"/login-images/wrong_cross.png"]];
        tickCrossImg.alpha = 1;
        [selectUserPassCodeModalView clearText];
    }
}

-(void)loginUser:(NSTimer*)timer
{
    NSDictionary *ur = [timer userInfo];
    
    [usersService setCurrentUserToUserWithId:ur[@"id"]];
    
    // does user need to change their nick
    if ([ur[@"nickClash"] integerValue] == 2)
    {
        [selectUserModalUnderlay removeFromSuperview];
        [selectUserPassCodeModalView removeFromSuperview];
        loginButton = nil;
        [selectUserModalContainer removeFromSuperview];
        [playButton removeFromSuperview];
        tickCrossImg.alpha = 0;
        [tickCrossImg setCenter:CGPointMake(595, 331)];
        
        [loadingImg setCenter:CGPointMake(596, 415)];
        changeNickTF.text = ur[@"nickName"];
        [selectUserView addSubview:changeNickView];
    }
    else
    {
        [self.view removeFromSuperview];
        [app proceedFromLoginViaIntro:NO];
    }
}

-(void)handleCancelChangeNickClicked:(id)button
{
    if (freezeUI) return;
    [self buttonTap];
    freezeUI = YES;
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:NO];
}

-(void)handleSaveChangeNickClicked:(id)button
{
    if (freezeUI) return;
    [self buttonTap];
    freezeUI = YES;
    
    loadingImg.alpha = 1;
    nickTakenLabel.alpha = 0;
    tickCrossImg.alpha = 0;
    
    SEL proceed = @selector(proceedAfterPause:);
    
    __block typeof(self) bself = self;
    void (^changeNickCallback)() = ^(BL_USER_NICK_CHANGE_RESULT result) {
        bself->loadingImg.alpha = 0;
        
        switch (result) {
            case BL_USER_NICK_CHANGE_SUCCESS:
                [bself->tickCrossImg setImage:[UIImage imageNamed:@"/login-images/correct_tick.png"]];
                bself->tickCrossImg.alpha = 1;
                [NSTimer scheduledTimerWithTimeInterval:0.5 target:bself selector:proceed userInfo:nil repeats:NO];
                break;
            case BL_USER_NICK_CHANGE_CONFLICT:
                freezeUI = NO;
                [bself->tickCrossImg setImage:[UIImage imageNamed:@"/login-images/wrong_cross.png"]];
                bself->tickCrossImg.alpha = 1;
                bself->loadingImg.alpha = 0;
                bself->nickTakenLabel.alpha = 1;
                break;
            case BL_USER_NICK_CHANGE_ERROR:
                bself->loadingImg.alpha = 0;
                
                self.dialog=[CODialog dialogWithWindow:self.view.window];
                [self.dialog resetLayout];
                
                self.dialog.dialogStyle=CODialogStyleDefault;
                self.dialog.title=@"Sorry";
                self.dialog.subtitle=@"There was a problem connecting to the server. You can change your username next time you log in.";
                [self.dialog addButtonWithTitle:@"OK" target:self selector:@selector(hideDialogAndGoToIntro:)];
                
                [self.dialog sizeToFit];
                [self.dialog showOrUpdateAnimated:YES];
                
                break;
        }
    };
    [usersService changeCurrentUserNick:changeNickTF.text callback:changeNickCallback];
}

-(void)proceedAfterPause:(NSTimer*)timer
{
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:NO];
}

- (void)hideDialog:(id)sender {
    [self.dialog hideAnimated:YES];
}

- (void)hideDialogAndGoToIntro:(id)sender {
    [self.dialog hideAnimated:YES];
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
    newUserNameTF.placeholder = @"USERNAME";
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
    [[SimpleAudioEngine sharedEngine]playEffect:BUNDLE_FULL_PATH(@"/sfx/go/sfx_generic_login_transition.wav")];
    [newUserNameTF resignFirstResponder];
    [newUserPassCodeView resignFirstResponder];
    [self setActiveView:selectUserView];
}

-(void)handleSaveNewUserClicked:(id)button
{
    if (freezeUI) return;
    [self buttonTap];
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
            self.dialog=[CODialog dialogWithWindow:self.view.window];
            [self.dialog resetLayout];
            
            self.dialog.dialogStyle=CODialogStyleDefault;
            self.dialog.title=@"Sorry";
            self.dialog.subtitle=@"This nickname is already in use. Please try another one.";
            [self.dialog addButtonWithTitle:@"OK" target:self selector:@selector(hideDialog:)];
            
            [self.dialog sizeToFit];
            [self.dialog showOrUpdateAnimated:YES];
            
        }
        else if (BL_USER_CREATION_SUCCESS_NICK_AVAILABLE == status || BL_USER_CREATION_SUCCESS_NICK_AVAILABILITY_UNCONFIRMED == status)
        {            
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
    existingUserNameTF.placeholder = @"USERNAME";
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
    [existingUserNameTF resignFirstResponder];
    [downloadUserPassCodeView resignFirstResponder];
    [self setActiveView:selectUserView];
}

-(void)handleLoadExistingUserClicked:(id)button
{
    if (freezeUI) return;
    [self buttonTap];
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
    
    __block typeof(self) bself = self;
    __block SEL bOnDownloadUserStateComplete = @selector(onDownloadUserStateComplete:);
    
    void (^callback)() = ^(NSDictionary *ur) {
        if (!ur)
        {
            self.dialog=[CODialog dialogWithWindow:self.view.window];
            [self.dialog resetLayout];
            
            self.dialog.dialogStyle=CODialogStyleDefault;
            self.dialog.title=@"Sorry";
            self.dialog.subtitle=@"We could not find a match for those login details. Please double-check and try again.";
            [self.dialog addButtonWithTitle:@"OK" target:self selector:@selector(hideDialog:)];
            
            [self.dialog sizeToFit];
            [self.dialog showOrUpdateAnimated:YES];
            
            
            bself->loadingImg.alpha = 0;
            bself->freezeUI = NO;
            return;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:bOnDownloadUserStateComplete name:DOWNLOAD_USER_STATE_COMPLETE object:nil];
        [bself->usersService setCurrentUserToUserWithId:[ur objectForKey:@"id"]];
    };
    
    [usersService downloadUserMatchingNickName:existingUserNameTF.text
                                   andPassword:downloadUserPassCodeView.text
                                      callback:callback];
}

-(void)onDownloadUserStateComplete:(NSNotification*)notification
{
    if (![[notification userInfo][@"userId"] isEqualToString:usersService.currentUserId])
    {
         return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOAD_USER_STATE_COMPLETE object:nil];
    
    if ([[notification userInfo][@"success"] boolValue])
    {
        [usersService applyDownloadedStateUpdatesForCurrentUser];
    }
    
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:NO];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 999)
    {
        [app proceedFromLoginViaIntro:NO];
    }
}

#pragma mark -
#pragma mark PassCodeViewDelegate
-(void)passCodeWasEdited:(PassCodeView*)passCodeView
{
    if (passCodeView == selectUserPassCodeModalView) tickCrossImg.alpha = 0;
}

-(void)passCodeBecameInvalid:(PassCodeView*)passCodeView
{
    if (passCodeView == selectUserPassCodeModalView)
        [loginButton setImage:[UIImage imageNamed:@"/login-images/login_button_grey.png"] forState:UIControlStateNormal];
}

-(void)passCodeBecameValid:(PassCodeView*)passCodeView
{
    if (passCodeView == selectUserPassCodeModalView)
        [loginButton setImage:[UIImage imageNamed:@"/login-images/login_button_orange.png"] forState:UIControlStateNormal];
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
    if (changeNickView)[changeNickView release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
@end
