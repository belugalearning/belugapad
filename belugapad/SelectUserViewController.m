//
//  SelectUserViewController.m
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SelectUserViewController.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "UsersService.h"
#import "EditZubi.h"
#import "User.h"

#import <CouchCocoa/CouchCocoa.h>

@interface SelectUserViewController ()
{
    @private
    AppDelegate *app;
    UsersService *usersService;
    unsigned char zubiColorRGBAByteData[4];
    
    NSArray *deviceUsersByLastSession;
    IBOutlet UITableView *selectUserTableView;
    UIButton *newUserButton;
    UIButton *existingUserButton;
    
    UITextField *newUserNameTF;
    UITextField *newUserPasswordTF;
    UIButton *cancelNewUserButton;
    UIButton *saveNewUserButton;
    
    UITextField *existingUserNameTF;
    UITextField *existingUserPasswordTF;
    UIButton *cancelExistingUserButton;
    UIButton *loadExistingUserButton;
}
-(void) buildSelectUserView;
-(void) buildEditUserView;
-(void) setActiveView:(UIView *)view;
@end

@implementation SelectUserViewController

@synthesize colorWheel;

// TODO: ensure this line doesn't want restoring: [newUserNameTF addTarget:self action:@selector(handleNameChanged:) forControlEvents:UIControlEventValueChanged];

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    app = [[UIApplication sharedApplication] delegate];
    usersService = app.usersService;
    
    [self buildSelectUserView];
    [self buildEditUserView];
    [self buildLoadExistingUserView];
    
    AppDelegate *ad = [[UIApplication sharedApplication] delegate];    
    deviceUsersByLastSession = [[ad.usersService deviceUsersByLastSessionDate] retain];
    if ([deviceUsersByLastSession count] == 0)
    {
        [cancelNewUserButton setHidden:YES];
        [self setActiveView:editUserView];
    }
    else [self setActiveView:selectUserView];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    //DLog(@"viewWillAppear");
    [super viewWillAppear:animated];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return  YES;
}

- (void) setActiveView:(UIView *)view
{
    NSAssert(view == selectUserView || view == editUserView || view == loadExistingUserView, @"bad args: method requires either selectUserView or editUserView");
    [selectUserView setHidden:(view != selectUserView)];
    [editUserView setHidden:(view != editUserView)];
    [loadExistingUserView setHidden:(view != loadExistingUserView)];
    if (view == selectUserView)
    {
        [backgroundImageView setImage:[UIImage imageNamed:(@"/select-edit-user-images/SelectUserBackground.png")]];
    }
    else if (view == editUserView)
    {
        [backgroundImageView setImage:[UIImage imageNamed:(@"/select-edit-user-images/EditUserBackground.png")]];
    }
    else
    {
        [backgroundImageView setImage:[UIImage imageNamed:(@"/select-edit-user-images/ExistingUserBackground.png")]];
    }
}

#pragma mark -
#pragma mark SelectUserView

- (void) buildSelectUserView
{
    newUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    newUserButton.frame = CGRectMake(261.0f, 458.0f, 539.0f, 81.0f);
    [newUserButton setImage:[UIImage imageNamed:@"/select-edit-user-images/NewUserButton.png"] forState:UIControlStateNormal];
    [newUserButton addTarget:self action:@selector(handleNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:newUserButton];
    
    existingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    existingUserButton.frame = CGRectMake(261.0f, 558.0f, 539.0f, 81.0f);
    [existingUserButton setImage:[UIImage imageNamed:@"/select-edit-user-images/SyncExistingUser_btn.png"] forState:UIControlStateNormal];
    [existingUserButton addTarget:self action:@selector(handleExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [selectUserView addSubview:existingUserButton];
}

- (void) handleNewUserClicked:(id)button
{
    [self setActiveView:editUserView];
}

- (void) handleExistingUserClicked:(id)button
{
    [self setActiveView:loadExistingUserView];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [deviceUsersByLastSession count];
}

 - (UITableViewCell *)tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"/select-edit-user-images/TableCellBackground.png"]] autorelease];
        cell.backgroundView.contentMode = UIViewContentModeLeft;
        cell.textLabel.contentMode = UIViewContentModeLeft;
        cell.textLabel.font = [UIFont fontWithName:@"Lucida Grande" size:34];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    User *user = [deviceUsersByLastSession objectAtIndex:indexPath.row];     
    cell.textLabel.text = user.nickName;
    cell.imageView.image = user.zubiScreenshot;
    return cell;
 }

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = [deviceUsersByLastSession objectAtIndex:indexPath.row];
    usersService.currentUser = user;
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:NO];
}

#pragma mark -
#pragma mark EditUserView

- (void) buildEditUserView
{
    [colorWheel addObserver: self forKeyPath: @"lastColorRGBAData" options: 0 context: NULL];
    
    EAGLView *glview = [EAGLView viewWithFrame:CGRectMake(632, 290, 160, 160) pixelFormat:kEAGLColorFormatRGBA8 depthFormat:0];
    glview.opaque = NO;
    [[CCDirector sharedDirector] setOpenGLView:glview];    
    [CCDirector sharedDirector].openGLView.backgroundColor = [UIColor clearColor];
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [[CCDirector sharedDirector] runWithScene:[EditZubi scene]];
    [editUserView addSubview:glview];
    
    newUserNameTF = [[UITextField alloc] initWithFrame:CGRectMake(358.0f, 114.0f, 400.0f, 45.0f)];
    newUserNameTF.delegate = self;
    newUserNameTF.font = [UIFont fontWithName:@"Lucida Grande" size:28];
    newUserNameTF.placeholder = @"name";
    newUserNameTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    newUserNameTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    newUserNameTF.autocorrectionType = UITextAutocorrectionTypeNo;
    newUserNameTF.keyboardType = UIKeyboardTypeNamePhonePad;
    newUserNameTF.returnKeyType = UIReturnKeyDone;
    [newUserNameTF setTextColor:[UIColor darkGrayColor]];
    [newUserNameTF setBorderStyle:UITextBorderStyleNone];
    [editUserView addSubview:newUserNameTF];
    
    newUserPasswordTF = [[UITextField alloc] initWithFrame:CGRectMake(358.0f, 186.0f, 400.0f, 45.0f)];
    newUserPasswordTF.delegate = self;
    newUserPasswordTF.font = [UIFont fontWithName:@"Lucida Grande" size:28];
    newUserPasswordTF.placeholder = @"password";
    newUserPasswordTF.secureTextEntry = YES;
    newUserPasswordTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    newUserPasswordTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    newUserPasswordTF.autocorrectionType = UITextAutocorrectionTypeNo;
    newUserPasswordTF.keyboardType = UIKeyboardTypeNamePhonePad;
    newUserPasswordTF.returnKeyType = UIReturnKeyDone;
    [newUserPasswordTF setTextColor:[UIColor darkGrayColor]];
    [newUserPasswordTF setBorderStyle:UITextBorderStyleNone];
    [editUserView addSubview:newUserPasswordTF];    
    
    cancelNewUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelNewUserButton.frame = CGRectMake(229.0f, 66.0f, 50.0f, 50.0f);
    [cancelNewUserButton setImage:[UIImage imageNamed:@"/select-edit-user-images/Cancel.png"] forState:UIControlStateNormal];
    [cancelNewUserButton addTarget:self action:@selector(handleCancelNewUserClicked:) forControlEvents:UIControlEventTouchDown];
    [editUserView addSubview:cancelNewUserButton];
    
    saveNewUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveNewUserButton.frame = CGRectMake(261.0f, 528.0f, 539.0f, 81.0f);
    [saveNewUserButton setImage:[UIImage imageNamed:@"/select-edit-user-images/Save.png"] forState:UIControlStateNormal];
    [saveNewUserButton addTarget:self action:@selector(handleSaveNewUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [editUserView addSubview:saveNewUserButton];
}

- (void) observeValueForKeyPath:(NSString*)keyPath
                       ofObject:(id)object 
                         change:(NSDictionary*)change
                        context:(void*)context
{
    if (object == colorWheel && keyPath == @"lastColorRGBAData")
    {        
        memcpy(zubiColorRGBAByteData, [colorWheel.lastColorRGBAData bytes], 4);
        
        CCScene *scene = [[CCDirector sharedDirector] runningScene];
        EditZubi *layer = [scene.children objectAtIndex:0];
        
        [layer setZubiColor:(ccColor4F){
            .r = zubiColorRGBAByteData[0] / 255.0f,
            .g = zubiColorRGBAByteData[1] / 255.0f,
            .b = zubiColorRGBAByteData[2] / 255.0f,
            .a = zubiColorRGBAByteData[3] / 255.0f
        }];
    }
}

- (void) handleCancelNewUserClicked:(id*)button
{
    newUserNameTF.text = @"";
    newUserPasswordTF.text = @"";
    [newUserNameTF resignFirstResponder];
    [newUserPasswordTF resignFirstResponder];
    [self setActiveView:selectUserView];
}

- (void) handleSaveNewUserClicked:(id*)button
{
    if (!newUserNameTF.text || !newUserNameTF.text.length)
    {
        [newUserNameTF becomeFirstResponder];
        return;
    }
    
    if (!newUserPasswordTF.text || !newUserPasswordTF.text.length)
    {
        [newUserPasswordTF becomeFirstResponder];
        return;
    }
    
    if (![usersService nickNameIsAvailable:newUserNameTF.text])
    {
        UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Sorry"
                                                             message:@"This nickname is already in use. Please try another one." delegate:self 
                                                   cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }
    
    CCScene *scene = [[CCDirector sharedDirector] runningScene];
    EditZubi *layer = [scene.children objectAtIndex:0];
    NSString *screenshotPath = [layer takeScreenshot];    
    UIImage *image = [UIImage imageWithContentsOfFile:screenshotPath];
    
    User *newUser = [[usersService createUserWithNickName:newUserNameTF.text
                                              andPassword:newUserPasswordTF.text    
                                            andZubiColor:colorWheel.lastColorRGBAData
                                       andZubiScreenshot:image] autorelease];
    usersService.currentUser = newUser;
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:YES];
}

#pragma mark -
#pragma mark LoadExistingUserView;

- (void) buildLoadExistingUserView
{
    existingUserNameTF = [[UITextField alloc] initWithFrame:CGRectMake(358.0f, 114.0f, 400.0f, 45.0f)];
    existingUserNameTF.delegate = self;
    existingUserNameTF.font = [UIFont fontWithName:@"Lucida Grande" size:28];
    existingUserNameTF.placeholder = @"name";
    existingUserNameTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    existingUserNameTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    existingUserNameTF.autocorrectionType = UITextAutocorrectionTypeNo;
    existingUserNameTF.keyboardType = UIKeyboardTypeDefault;
    existingUserNameTF.returnKeyType = UIReturnKeyDone;
    [existingUserNameTF setTextColor:[UIColor darkGrayColor]];
    [existingUserNameTF setBorderStyle:UITextBorderStyleNone];
    [loadExistingUserView addSubview:existingUserNameTF];
    
    existingUserPasswordTF = [[UITextField alloc] initWithFrame:CGRectMake(358.0f, 186.0f, 400.0f, 45.0f)];
    existingUserPasswordTF.delegate = self;
    existingUserPasswordTF.font = [UIFont fontWithName:@"Lucida Grande" size:28];
    existingUserPasswordTF.placeholder = @"password";
    existingUserPasswordTF.secureTextEntry = YES;
    existingUserPasswordTF.clearButtonMode = UITextFieldViewModeWhileEditing;
    existingUserPasswordTF.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    existingUserPasswordTF.autocorrectionType = UITextAutocorrectionTypeNo;
    existingUserPasswordTF.keyboardType = UIKeyboardTypeDefault;
    existingUserPasswordTF.returnKeyType = UIReturnKeyDone;
    [existingUserPasswordTF setTextColor:[UIColor darkGrayColor]];
    [existingUserPasswordTF setBorderStyle:UITextBorderStyleNone];
    [loadExistingUserView addSubview:existingUserPasswordTF];
    
    cancelExistingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelExistingUserButton.frame = CGRectMake(229.0f, 66.0f, 50.0f, 50.0f);
    [cancelExistingUserButton setImage:[UIImage imageNamed:@"/select-edit-user-images/Cancel.png"] forState:UIControlStateNormal];
    [cancelExistingUserButton addTarget:self action:@selector(handleCancelExistingUserClicked:) forControlEvents:UIControlEventTouchDown];
    [loadExistingUserView addSubview:cancelExistingUserButton];
    
    loadExistingUserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    loadExistingUserButton.frame = CGRectMake(261.0f, 270.0f, 539.0f, 81.0f);
    [loadExistingUserButton setImage:[UIImage imageNamed:@"/select-edit-user-images/SyncExistingUser_btn.png"] forState:UIControlStateNormal];
    [loadExistingUserButton addTarget:self action:@selector(handleLoadExistingUserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [loadExistingUserView addSubview:loadExistingUserButton];
}

- (void) handleCancelExistingUserClicked:(id*)button
{
    existingUserNameTF.text = @"";
    existingUserPasswordTF.text = @"";
    [existingUserNameTF resignFirstResponder];
    [existingUserPasswordTF resignFirstResponder];
    [self setActiveView:selectUserView];
}

- (void) handleLoadExistingUserClicked:(id*)button
{
    User *usr = [usersService userMatchingNickName:existingUserNameTF.text  andPassword:existingUserPasswordTF.text];    
    if (usr == nil)
    {
        UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Sorry"
                                                            message:@"We could not find a match for those login details. Please double-check and try again." delegate:self 
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alertView show];
        return;
    }
    
    usersService.currentUser = usr;
    
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:NO];
}


#pragma mark -
#pragma mark Destruction

- (void)dealloc
{
    [[CCDirector sharedDirector] end];
    [deviceUsersByLastSession release];
    if (colorWheel) [colorWheel removeObserver:self forKeyPath:@"lastColorRGBAData"];
    [backgroundImageView release];
    [newUserNameTF release];
    [editUserView release];
    [selectUserView release];
    [selectUserTableView release];
    [loadExistingUserView release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [[CCDirector sharedDirector] end];
    [deviceUsersByLastSession release];
    deviceUsersByLastSession = nil;
    if (colorWheel) [colorWheel removeObserver:self forKeyPath:@"lastColorRGBAData"];
    [backgroundImageView release];
    backgroundImageView = nil;
    [newUserNameTF release];
    newUserNameTF = nil;
    [editUserView release];
    editUserView = nil;
    [selectUserView release];
    selectUserView = nil;
    [selectUserTableView release];
    selectUserTableView = nil;
    [loadExistingUserView release];
    loadExistingUserView = nil;
    [super viewDidUnload];
}
@end
