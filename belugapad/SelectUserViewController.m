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
    
    NSMutableArray *deviceUsers;
    IBOutlet UITableView *selectUserTableView;
    UIButton *playButton;
    UIButton *joinClassButton;
    
    UIImageView *modalPassCodeImageBgView;
    PassCodeView *modalPassCodeView;
    
    UITextField *newUserNameTF;
    PassCodeView *newUserPassCodeView;
    UIButton *cancelNewUserButton;
    UIButton *saveNewUserButton;
    
    UITextField *existingUserNameTF;
    PassCodeView *downloadUserPassCodeView;
    UIButton *cancelExistingUserButton;
    UIButton *loadExistingUserButton;
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
    
    [self buildSelectUserView];
    [self buildEditUserView];
    [self buildLoadExistingUserView];
    
    [self setActiveView:selectUserView];
}

-(void)viewWillAppear:(BOOL)animated
{
    //DLog(@"viewWillAppear");
    [super viewWillAppear:animated];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return  YES;
}

-(void)setActiveView:(UIView *)view
{
    NSAssert(view == selectUserView || view == editUserView || view == loadExistingUserView, @"bad args: method requires either selectUserView or editUserView");
    [selectUserView setHidden:(view != selectUserView)];
    [editUserView setHidden:(view != editUserView)];
    [loadExistingUserView setHidden:(view != loadExistingUserView)];
    if (view == selectUserView)
    {
        [backgroundImageView setImage:[UIImage imageNamed:(@"/login-images/Island_BG.png")]];
    }
    else if (view == editUserView)
    {
        [backgroundImageView setImage:[UIImage imageNamed:(@"/login-images/New.png")]];
    }
    else
    {
        [backgroundImageView setImage:[UIImage imageNamed:(@"/login-images/Sync.png")]];
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
    UIImageView *panel = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/select_user_BG.png"]] autorelease];
    [panel setCenter:CGPointMake(511.0f, 377.0f)];
    [selectUserView addSubview:panel];
    
    UIButton *newUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newUserButton.frame = CGRectMake(331.0f, 393.0f, 131.0f, 51.0f);
    [newUserButton setImage:[UIImage imageNamed:@"/login-images/new_button.png"] forState:UIControlStateNormal];
    [newUserButton addTarget:self action:@selector(handleNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:newUserButton];
    
    UIButton *existingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    existingUserButton.frame = CGRectMake(559.0f, 394.0f, 131.0f, 51.0f);
    [existingUserButton setImage:[UIImage imageNamed:@"/login-images/download_button.png"] forState:UIControlStateNormal];
    [existingUserButton addTarget:self action:@selector(handleExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:existingUserButton];
    
    playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(698.0f, 502.0f, 138.0f, 66.0f);
    [playButton setImage:[UIImage imageNamed:@"/login-images/play_button_disabled.png"] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"/login-images/play_button_disabled.png"] forState:UIControlStateHighlighted];
    [playButton addTarget:self action:@selector(handlePlayButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:playButton];
    
    joinClassButton = [UIButton buttonWithType:UIButtonTypeCustom];
    joinClassButton.frame = CGRectMake(220.0f, 447.0f, 100.0f, 95.0f);
    [joinClassButton setImage:[UIImage imageNamed:@"/login-images/join_class_button_disabled.png"] forState:UIControlStateNormal];
    [joinClassButton setImage:[UIImage imageNamed:@"/login-images/join_class_button_disabled.png"] forState:UIControlStateHighlighted];
    //[joinClassButton addTarget:self action:@selector(handleExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:joinClassButton];
    
    selectUserTableView = [[[UITableView alloc] initWithFrame:CGRectMake(322.0f,234.0f,378.0f,140.0f) style:UITableViewStylePlain] autorelease];
    selectUserTableView.backgroundColor = [UIColor clearColor];
    selectUserTableView.opaque = YES;
    selectUserTableView.backgroundView = nil;
    selectUserTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    selectUserTableView.dataSource = self;
    selectUserTableView.delegate = self;
    [selectUserView addSubview:selectUserTableView];
    
    UIImageView *mask = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/table-mask.png"]] autorelease];
    mask.frame = CGRectMake(320.0f,233.0f,381.0f,146.0f);
    [selectUserView addSubview:mask];
}

-(void)enablePlayButton
{
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
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:indexPath.row % 2 == 0 ? @"/login-images/table_cell_black.png" : @"/login-images/table_cell_transparent"]] autorelease];
        cell.selectionStyle = UITableViewCellSeparatorStyleNone;
        cell.backgroundView.contentMode = UIViewContentModeLeft;
        cell.textLabel.contentMode = UIViewContentModeLeft;
        cell.textLabel.font = [UIFont fontWithName:@"Chango" size:24];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
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
-(void)handlePlayButtonClicked:(id)button
{
    NSIndexPath *ip = [selectUserTableView indexPathForSelectedRow];
    if (ip)
    {
        NSDictionary *ur = [deviceUsers objectAtIndex:ip.row];
        [usersService setCurrentUserToUserWithId:[ur objectForKey:@"id"]];
        [self.view removeFromSuperview];
        [app proceedFromLoginViaIntro:NO];
        
        
        
        /*modalPassCodeImageBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/login-images/passcode_modal.png"]];
        modalPassCodeImageBgView.center = CGPointMake(512.0f, 354.0f);
        [self.view addSubview:modalPassCodeImageBgView];
        
        [modalPassCodeImageBgView registerForDragAndLog];*/
    }
}

-(void)handleNewUserClicked:(id)button
{
    [self setActiveView:editUserView];
}

-(void)handleExistingUserClicked:(id)button
{
    [self setActiveView:loadExistingUserView];
}

#pragma mark -
#pragma mark EditUserView

-(void)buildEditUserView
{    
    newUserNameTF = [[[UITextField alloc] initWithFrame:CGRectMake(334.0f, 278.0f, 360.0f, 42.0f)] autorelease];
    newUserNameTF.delegate = self;
    newUserNameTF.font = [UIFont fontWithName:@"Chango" size:24];
    //newUserNameTF.placeholder = @"name";
    newUserNameTF.clearButtonMode = UITextFieldViewModeNever;
    newUserNameTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    newUserNameTF.autocorrectionType = UITextAutocorrectionTypeNo;
    newUserNameTF.keyboardType = UIKeyboardTypeNamePhonePad;
    newUserNameTF.returnKeyType = UIReturnKeyDone;
    [newUserNameTF setTextColor:[UIColor whiteColor]];
    [newUserNameTF setBorderStyle:UITextBorderStyleNone];
    [editUserView addSubview:newUserNameTF];
    
    newUserPassCodeView = [[[PassCodeView alloc] initWithFrame:CGRectMake(390.0f, 334.0f, 255.0f, 46.0f)] autorelease];
    newUserPassCodeView.delegate = self;
    [editUserView addSubview:newUserPassCodeView];
    
    cancelNewUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelNewUserButton.frame = CGRectMake(330.0f, 397.0f, 103.0f, 49.0f);
    [cancelNewUserButton setImage:[UIImage imageNamed:@"/login-images/cancel_button.png"] forState:UIControlStateNormal];
    [cancelNewUserButton addTarget:self action:@selector(handleCancelNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [editUserView addSubview:cancelNewUserButton];
    
    saveNewUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveNewUserButton.frame = CGRectMake(591.0f, 397.0f, 103.0f, 49.0f);
    [saveNewUserButton setImage:[UIImage imageNamed:@"/login-images/save_button.png"] forState:UIControlStateNormal];;
    [saveNewUserButton addTarget:self action:@selector(handleSaveNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [editUserView addSubview:saveNewUserButton];
}

-(void)handleCancelNewUserClicked:(id*)button
{
    newUserNameTF.text = @"";
    [newUserPassCodeView clearText];
    [newUserNameTF resignFirstResponder];
    [newUserPassCodeView resignFirstResponder];
    [self setActiveView:selectUserView];
}

-(void)handleSaveNewUserClicked:(id*)button
{
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
        if (BL_USER_CREATION_FAILURE_NICK_UNAVAILABLE == status)
        {
            UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Sorry"
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
    
    [usersService createNewUserWithNick:newUserNameTF.text
                            andPassword:newUserPassCodeView.text
                               callback:createSetUrCallback];
}

#pragma mark -
#pragma mark LoadExistingUserView;

-(void)buildLoadExistingUserView
{
    existingUserNameTF = [[[UITextField alloc] initWithFrame:CGRectMake(334.0f, 276.0f, 360.0f, 42.0f)] autorelease];
    existingUserNameTF.delegate = self;
    existingUserNameTF.font = [UIFont fontWithName:@"Chango" size:24];
    //existingUserNameTF.placeholder = @"name";
    existingUserNameTF.clearButtonMode = UITextFieldViewModeNever;
    existingUserNameTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    existingUserNameTF.autocorrectionType = UITextAutocorrectionTypeNo;
    existingUserNameTF.keyboardType = UIKeyboardTypeNamePhonePad;
    existingUserNameTF.returnKeyType = UIReturnKeyDone;
    [existingUserNameTF setTextColor:[UIColor whiteColor]];
    [existingUserNameTF setBorderStyle:UITextBorderStyleNone];
    [loadExistingUserView addSubview:existingUserNameTF];
    
    downloadUserPassCodeView = [[[PassCodeView alloc] initWithFrame:CGRectMake(390.0f, 334.0f, 255.0f, 46.0f)] autorelease];
    downloadUserPassCodeView.delegate = self;
    [loadExistingUserView addSubview:downloadUserPassCodeView];
    
    cancelExistingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelExistingUserButton.frame = CGRectMake(330.0f, 392.0f, 131.0f, 51.0f);
    [cancelExistingUserButton setImage:[UIImage imageNamed:@"/login-images/cancel_button_2.png"] forState:UIControlStateNormal];
    [cancelExistingUserButton addTarget:self action:@selector(handleCancelExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [loadExistingUserView addSubview:cancelExistingUserButton];
    
    loadExistingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loadExistingUserButton.frame = CGRectMake(563.0f, 391.0f, 131.0f, 51.0f);
    [loadExistingUserButton setImage:[UIImage imageNamed:@"/login-images/download_button.png"] forState:UIControlStateNormal];
    [loadExistingUserButton addTarget:self action:@selector(handleLoadExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [loadExistingUserView addSubview:loadExistingUserButton];
}

-(void)handleCancelExistingUserClicked:(id*)button
{
    existingUserNameTF.text = @"";
    [downloadUserPassCodeView clearText];
    [existingUserNameTF resignFirstResponder];
    [downloadUserPassCodeView resignFirstResponder];
    [self setActiveView:selectUserView];
}

-(void)handleLoadExistingUserClicked:(id*)button
{
    __block typeof(self) bself = self;
    void (^callback)() = ^(NSDictionary *ur) {
        if (ur == nil)
        {
            UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Sorry"
                                                                 message:@"We could not find a match for those login details. Please double-check and try again."
                                                                delegate:bself 
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] autorelease];
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
    
    [usersService downloadUserMatchingNickName:existingUserNameTF.text
                                   andPassword:downloadUserPassCodeView.text
                                      callback:callback];
}


#pragma mark -
#pragma mark PassCodeViewDelegate
-(void)passCodeBecameInvalid:(PassCodeView*)passCodeView
{
}

-(void)passCodeBecameValid:(PassCodeView*)passCodeView
{
}


#pragma mark -
#pragma mark Destruction

-(void)dealloc
{
    if (deviceUsers)[deviceUsers release];
    if (backgroundImageView)[backgroundImageView release];
    if (editUserView)[editUserView release];
    if (selectUserView)[selectUserView release];
    if (selectUserTableView)[selectUserTableView release];
    if (loadExistingUserView)[loadExistingUserView release];
    [super dealloc];
}
@end
