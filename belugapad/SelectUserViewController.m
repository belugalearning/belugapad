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
    
    UITextField *newUserNameTF;
    UITextField *newUserPasswordTF;
    UIButton *cancelButton;
    UIButton *saveButton;
    
    UITextField *existingUserNameTF;
    UITextField *existingUserPasswordTF;
    UIButton *cancelExistingUserButton;
    UIButton *loadExistingUserButton;
}
- (void) buildSelectUserView;
- (void) buildEditUserView;
- (void) setActiveView:(UIView *)view;
@end

@implementation SelectUserViewController

@synthesize colorWheel;

// TODO: Check what to do about delete button on swipe !!!!!

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
    
    deviceUsersByLastSession = [((AppDelegate*)[[UIApplication sharedApplication] delegate]).usersService deviceUsersByLastSessionDate];
    if ([deviceUsersByLastSession count] == 0)
    {
        [cancelButton setHidden:YES];
        [self setActiveView:editUserView];
    }
    else [self setActiveView:selectUserView];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    //DLog(@"viewWillAppear");
    [super viewWillAppear:animated];
}

- (void) setActiveView:(UIView *)view
{
    NSAssert(view == selectUserView || view == editUserView, @"bad args: method requires either selectUserView or editUserView");
    [selectUserView setHidden:(view != selectUserView)];
    [editUserView setHidden:(view != editUserView)];
    [backgroundImageView setImage:[UIImage imageNamed:(view == selectUserView 
                                                       ? @"/select-edit-user-images/SelectUserBackground.png"
                                                       : @"/select-edit-user-images/EditUserBackground.png")]];
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
}

- (void) handleNewUserClicked:(id)button
{
    [self setActiveView:editUserView];
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
    
    User *user = [deviceUsersByLastSession objectAtIndex:[indexPath indexAtPosition:0]];     
    cell.textLabel.text = user.nickName;
    cell.imageView.image = user.zubiScreenshot;
    return cell;
 }

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = [deviceUsersByLastSession objectAtIndex:[indexPath indexAtPosition:0]];
    usersService.currentUser = user;
    [self.view removeFromSuperview];
    [app proceedFromLoginViaIntro:NO];
}

#pragma mark -
#pragma mark EditUserView

- (void) buildEditUserView
{
    [colorWheel addObserver: self forKeyPath: @"lastColorRGBAData" options: 0 context: NULL];
    
    EAGLView *glview = [EAGLView viewWithFrame:CGRectMake(632, 220, 160, 160) pixelFormat:kEAGLColorFormatRGBA8 depthFormat:0];
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
    [newUserNameTF addTarget:self action:@selector(handleNameChanged:) forControlEvents:UIControlEventValueChanged];
    [editUserView addSubview:newUserNameTF];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(229.0f, 66.0f, 50.0f, 50.0f);
    [cancelButton setImage:[UIImage imageNamed:@"/select-edit-user-images/Cancel.png"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(handleCancelClicked:) forControlEvents:UIControlEventTouchDown];
    [editUserView addSubview:cancelButton];
    
    saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(261.0f, 458.0f, 539.0f, 81.0f);
    [saveButton setImage:[UIImage imageNamed:@"/select-edit-user-images/Save.png"] forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(handleSaveClicked:) forControlEvents:UIControlEventTouchUpInside];
    [editUserView addSubview:saveButton];
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

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [newUserNameTF resignFirstResponder];
    return  YES;
}

- (void) handleCancelClicked:(id*)button
{
    [newUserNameTF resignFirstResponder];
    [self setActiveView:selectUserView];
}

- (void) handleSaveClicked:(id*)button
{
    if (!newUserNameTF.text || !newUserNameTF.text.length)
    {
        [newUserNameTF becomeFirstResponder];
        return;
    }
    
    if (![usersService nickNameIsAvailable:newUserNameTF.text])
    {
        return;
    }
    
    CCScene *scene = [[CCDirector sharedDirector] runningScene];
    EditZubi *layer = [scene.children objectAtIndex:0];
    NSString *screenshotPath = [layer takeScreenshot];    
    UIImage *image = [UIImage imageWithContentsOfFile:screenshotPath];
    
    User *newUser = [[usersService createUserWithNickName:newUserNameTF.text
                                            andZubiColor:colorWheel.lastColorRGBAData
                                       andZubiScreenshot:image] autorelease];
    usersService.currentUser = newUser;    
    [app proceedFromLoginViaIntro:YES];
}

#pragma mark -
#pragma mark LoadExistingUserView

- (void) buildLoadExistingUserView
{    
    /*
     UITextField *existingUserNameTF;
     UITextField *existingUserPasswordTF;
     UIButton *cancelExistingUserButton;
     UIButton *loadExistingUserButton;
     */
    // will this force git tower to update????????
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
    [newUserNameTF addTarget:self action:@selector(handleNameChanged:) forControlEvents:UIControlEventValueChanged];
    [editUserView addSubview:newUserNameTF];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(229.0f, 66.0f, 50.0f, 50.0f);
    [cancelButton setImage:[UIImage imageNamed:@"/select-edit-user-images/Cancel.png"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(handleCancelClicked:) forControlEvents:UIControlEventTouchDown];
    [editUserView addSubview:cancelButton];
    
    saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(261.0f, 458.0f, 539.0f, 81.0f);
    [saveButton setImage:[UIImage imageNamed:@"/select-edit-user-images/Save.png"] forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(handleSaveClicked:) forControlEvents:UIControlEventTouchUpInside];
    [editUserView addSubview:saveButton];
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
    [super viewDidUnload];
}
@end
