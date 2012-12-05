//
//  switchPanelViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/9/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "switchPanelViewController.h"
#import "stdio.h"
#import "../../KissXML/KissXML/DDXMLDocument.h"
#import "SJUIStatusMessageLabel.h"
#import "Flurry.h"

@implementation SJUIButtonWithActions

@synthesize activateActions;
@synthesize deactivateActions;
@synthesize imageFilePath;
@synthesize audioFilePath;
@end

// Workaround to prevent the imagePopover from trying to rotate the app, which can cause a crash
@interface SJUIImagePickerController : UIImagePickerController {
    
}
@end

@implementation SJUIImagePickerController
-(BOOL)shouldAutorotate{
    return NO;
}
@end



@implementation switchPanelViewController

@synthesize urlToLoad;
@synthesize switchPanelName;
@synthesize editingActive;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    appDelegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication]delegate];
    UIView *myView = [[UIView alloc] init];
	self.view = myView;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    UIColor *bgColor = [appDelegate backgroundColor];
    UIView *myView = [self view];
    [myView setBackgroundColor:bgColor];
    [[self view] setClipsToBounds:YES];
	myView.autoresizesSubviews = YES;
    settingScanOrder = NO;
    NSError *xmlError=nil, *fileError=nil;
    NSString *xmlString = [NSString stringWithContentsOfURL:urlToLoad encoding:NSUTF8StringEncoding error:&fileError];
    scanOrderIndices = [NSMutableArray arrayWithCapacity:20];
    
    DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:&xmlError];
    if(xmlDoc == nil) {
        NSLog(@"XML Open Failed.");
    }
    // Set name
    [self setSwitchPanelName:@"Panel"];
    NSArray *panelNameNodes = [xmlDoc nodesForXPath:@".//panel/panelname" error:&xmlError];
    if([panelNameNodes count]) {
        DDXMLNode *panelNameNode = [panelNameNodes objectAtIndex:0];
        [self setSwitchPanelName:[panelNameNode stringValue]];
    }
    
    NSArray *elementNodes = [xmlDoc nodesForXPath:@".//panel/panelelement" error:&xmlError];
    // Display all elements of the switch panel
    DDXMLNode *element;
    for(element in elementNodes) {
        SJUIButtonWithActions *myButton = [SJUIButtonWithActions buttonWithType:UIButtonTypeCustom];
        NSArray *frameNodes = [element nodesForXPath:@".//frame" error:&xmlError];
        NSArray *colorNodes = [element nodesForXPath:@".//rgbacolor" error:&xmlError];
        NSArray *textNodes = [element nodesForXPath:@".//switchtext" error:&xmlError];
        NSArray *actionArray = [element nodesForXPath:@".//onswitchactivate/actionsequenceondevice" error:&xmlError];
        NSArray *imageNodes = [element nodesForXPath:@".//image" error:&xmlError];
        NSArray *iconNodes = [element nodesForXPath:@".//icon" error:&xmlError];
        NSArray *audioNodes = [element nodesForXPath:@".//audioforswitchactivate" error:&xmlError];
        [myButton setActivateActions:[[NSMutableArray alloc] initWithCapacity:5]];
        [[myButton activateActions] setArray:actionArray];
        actionArray = [element nodesForXPath:@".//onswitchdeactivate/actionsequenceondevice" error:&xmlError];
        [myButton setDeactivateActions:[[NSMutableArray alloc] initWithCapacity:5]];
        [[myButton deactivateActions] setArray:actionArray];
        
        // Read frame
        if([frameNodes count] <= 0) {
            NSLog(@"No frame found.\n");
            continue;
        }
        
        DDXMLNode *frameNode = [frameNodes objectAtIndex:0];
        NSString *frameString = [frameNode stringValue];
        NSScanner *frameScan = [[NSScanner alloc] initWithString:frameString];
        int x, y, w, h;
        bool x_ok = [frameScan scanInt:&x];
        bool y_ok = [frameScan scanInt:&y];
        bool w_ok = [frameScan scanInt:&w];
        bool h_ok = [frameScan scanInt:&h];
        if(!x_ok || !y_ok || !w_ok || !h_ok)
            continue;
        CGRect buttonRect = CGRectMake((CGFloat)x, (CGFloat)y, (CGFloat)w, (CGFloat)h);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        // Image
        if([imageNodes count]) {
            NSString *imageNodePath = [[imageNodes objectAtIndex:0] stringValue];
            // Put the path in the proper directory
            NSString *fileName = [imageNodePath lastPathComponent];
            imageNodePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            [myButton setImageFilePath:imageNodePath];
            UIImage *image = [UIImage imageWithContentsOfFile:imageNodePath];
            [myButton setBackgroundImage:image forState:UIControlStateNormal];
        }
        
        // Icon
        if([iconNodes count]) {
            [myButton setIconName:[[iconNodes objectAtIndex:0] stringValue]];
            [myButton setImage:[[UIImage imageNamed:[myButton iconName]] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f] forState:UIControlStateNormal];
        }
        
        // Audio
        if([audioNodes count]) {
            NSString *audioNodePath = [[audioNodes objectAtIndex:0] stringValue];
            NSString *fileName = [audioNodePath lastPathComponent];
            audioNodePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            [myButton setAudioFilePath:audioNodePath];
        }
        
        // Read color
        if([colorNodes count] <= 0) {
            NSLog(@"No color found.\n");
            continue;
        }
        DDXMLNode *colorNode = [colorNodes objectAtIndex:0];
        NSString *colorString = [colorNode stringValue];
        NSScanner *colorScan = [[NSScanner alloc] initWithString:colorString];
        CGFloat r, g, b, a;
        bool r_ok = [colorScan scanFloat:&r];
        bool g_ok = [colorScan scanFloat:&g];
        bool b_ok = [colorScan scanFloat:&b];
        bool a_ok = [colorScan scanFloat:&a];
        if(!r_ok || !g_ok || !b_ok || !a_ok)
            continue;
        // Create the specified button
        [myButton setFrame:buttonRect];
        [myButton setBackgroundColor:[UIColor colorWithRed:r green:g blue:b alpha:a]];
        
        // Associate different actions for the buttons depending on whether or not we're editing
        if(editingActive) {
            [myButton addTarget:self action:@selector(onButtonDrag:withEvent:) forControlEvents:(UIControlEventTouchDragInside)];
            [myButton addTarget:self action:@selector(onButtonSelect:withEvent:) forControlEvents:(UIControlEventTouchDown)];
        } else {
            [myButton addTarget:self action:@selector(onSwitchActivated:) forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragEnter)];
            [myButton addTarget:self action:@selector(onSwitchDeactivated:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragExit)];
        }
        // Read text for switch
        if([textNodes count]) {
            [myButton setTitle:[[textNodes objectAtIndex:0] stringValue] forState:UIControlStateNormal];
        }
        [myButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [[myButton titleLabel] setFont:[UIFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"]]];
        
        [myView addSubview:myButton];
        [scanOrderIndices addObject:[NSNumber numberWithInt:[scanOrderIndices count]]];
    }

    oneButtonNavigation = [[NSUserDefaults standardUserDefaults] boolForKey:@"singleTapBackButtonPreference"] & !editingActive;
    bool allowEditing = [[NSUserDefaults standardUserDefaults] boolForKey:@"allowEditingOfSwitchPanelsPreference"];
    CGRect backButtonRect;
    backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    if(!oneButtonNavigation) {
        // If we're allowing editing, don't bother with "Enable Back Button"
        if(!allowEditing) {
            // Create two-button combo to allow navigation
            allowNavButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            CGRect buttonRect = CGRectMake(412, 704, 200, 44);
            [allowNavButton setFrame:buttonRect];
            [allowNavButton setTitle:[NSString stringWithCString:"Enable Back Button" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
            [allowNavButton addTarget:self action:@selector(allowNavigation:) forControlEvents:UIControlEventTouchUpInside];
            [myView addSubview:allowNavButton];
            [backButton setEnabled:NO];
        }
        backButtonRect = CGRectMake(490, 0, 44, 44);
    } else {
        float backButtonHeight = [[NSUserDefaults standardUserDefaults] integerForKey:@"switchPanelSizePreference"];
        float backButtonWidth = backButtonHeight * 1.5;
        int textFontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"];
        [[backButton titleLabel] setFont:[UIFont systemFontOfSize:textFontSize]];
        CGSize backTextSize = [@"Back" sizeWithFont:[UIFont systemFontOfSize:textFontSize]];
        if(backButtonHeight < backTextSize.height)
            backButtonHeight = backTextSize.height;
        if(backButtonWidth < backTextSize.width)
            backButtonWidth = backTextSize.width;
        backButtonRect = CGRectMake(512-backButtonWidth/2, 0, backButtonWidth, backButtonHeight);
        [backButton setEnabled:YES];
    }
    [backButton setFrame:backButtonRect];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [backButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [myView addSubview:backButton];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *urlPath = [urlToLoad path];
    NSPredicate *searchForDocumentsPredicate = [NSPredicate predicateWithFormat:@"SELF contains %@", documentsDirectory];
    isBuiltInPanel = ![searchForDocumentsPredicate evaluateWithObject:urlPath];
    if(allowEditing) {
        oneButtonNavigation = YES;
        // Show button to start editing if we aren't already editing
        if(!editingActive) {
            editButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            CGRect buttonRect = CGRectMake(150, 0, 100, 44);
            [editButton setFrame:buttonRect];
            [editButton setTitle:[NSString stringWithCString:"Edit Panel" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
            [editButton addTarget:self action:@selector(editPanel:) forControlEvents:UIControlEventTouchUpInside];
            [myView addSubview:editButton];
        }
        // If this panel is built-in or we're editting it, don't allow deleting it
        if(!isBuiltInPanel && !editingActive) {
            deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            CGRect buttonRect = CGRectMake(300, 0, 100, 44);
            [deleteButton setFrame:buttonRect];
            [deleteButton setTitle:[NSString stringWithCString:"Delete Panel" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
            [deleteButton addTarget:self action:@selector(deletePanel:) forControlEvents:UIControlEventTouchUpInside];
            [myView addSubview:deleteButton];
        }
    }
    if(!editingActive) {
        // Show status
        CGRect textRect = CGRectMake(700, 0, 324, 36);
        textToShowSwitchName = [[SJUIStatusMessageLabel alloc] initWithFrame:textRect];
        [textToShowSwitchName setBackgroundColor:bgColor];
        [myView addSubview:textToShowSwitchName];
    }
    
    // OK always to create hidden button
    confirmDeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmDeleteButton setFrame:CGRectMake(412, 650, 200, 44)];
    [confirmDeleteButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f] forState:UIControlStateNormal];
    [confirmDeleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmDeleteButton setTitle:@"Confirm Delete" forState:UIControlStateNormal];
    if(editingActive)
        [confirmDeleteButton addTarget:self action:@selector(deleteSwitch:) forControlEvents:UIControlEventTouchUpInside];
    else
        [confirmDeleteButton addTarget:self action:@selector(deletePanel:) forControlEvents:UIControlEventTouchUpInside];
    [confirmDeleteButton setHidden:YES];
    [myView addSubview:confirmDeleteButton];
    
    // Display configuration UI
    if(editingActive) {
        configurationUIElements = [NSMutableArray arrayWithCapacity:20];
        UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
        [myView addGestureRecognizer:pinchRecognizer];
        lastPinchScale = 1.0;
        
        CGRect panelNameTextFieldRect = CGRectMake(25, 0, 200, 44);
        panelNameTextField = [[UITextField alloc] initWithFrame:panelNameTextFieldRect];
        [panelNameTextField setText:[self switchPanelName]];
        [panelNameTextField addTarget:self action:@selector(onPanelNameChange:) forControlEvents:UIControlEventEditingDidEndOnExit];
        [panelNameTextField setBackgroundColor:[UIColor whiteColor]];
        [panelNameTextField setTextColor:[UIColor blackColor]];
        [panelNameTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [panelNameTextField setFont:[UIFont systemFontOfSize:14.0f]];
        [panelNameTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
        [panelNameTextField setReturnKeyType:UIReturnKeyDone];
        [myView addSubview:panelNameTextField];
        [configurationUIElements addObject:panelNameTextField];
        // Color buttons
        UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [colorButton setFrame:CGRectMake(980, 604, 44, 44)];
        [colorButton setBackgroundColor:[UIColor redColor]];
        [colorButton addTarget:self action:@selector(onSetColor:) forControlEvents:UIControlEventTouchUpInside];
        [myView addSubview:colorButton];
        [configurationUIElements addObject:colorButton];
        colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [colorButton setFrame:CGRectMake(980, 554, 44, 44)];
        [colorButton setBackgroundColor:[UIColor blueColor]];
        [colorButton addTarget:self action:@selector(onSetColor:) forControlEvents:UIControlEventTouchUpInside];
        [myView addSubview:colorButton];
        [configurationUIElements addObject:colorButton];
        colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [colorButton setFrame:CGRectMake(980, 504, 44, 44)];
        [colorButton setBackgroundColor:[UIColor greenColor]];
        [colorButton addTarget:self action:@selector(onSetColor:) forControlEvents:UIControlEventTouchUpInside];
        [myView addSubview:colorButton];
        [configurationUIElements addObject:colorButton];
        colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [colorButton setFrame:CGRectMake(980, 454, 44, 44)];
        [colorButton setBackgroundColor:[UIColor yellowColor]];
        [colorButton addTarget:self action:@selector(onSetColor:) forControlEvents:UIControlEventTouchUpInside];
        [myView addSubview:colorButton];
        [configurationUIElements addObject:colorButton];
        colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [colorButton setFrame:CGRectMake(980, 404, 44, 44)];
        [colorButton setBackgroundColor:[UIColor orangeColor]];
        [colorButton addTarget:self action:@selector(onSetColor:) forControlEvents:UIControlEventTouchUpInside];
        [myView addSubview:colorButton];
        [configurationUIElements addObject:colorButton];
        [colorButton setFrame:CGRectMake(980, 654, 44, 44)];
        [colorButton setBackgroundColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]];
        [colorButton addTarget:self action:@selector(onSetColor:) forControlEvents:UIControlEventTouchUpInside];
        [myView addSubview:colorButton];
        [configurationUIElements addObject:colorButton];
        
        UIButton *newSwitchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [newSwitchButton setFrame:CGRectMake(150, 704, 100, 44)];
        [newSwitchButton addTarget:self action:@selector(newSwitch:) forControlEvents:UIControlEventTouchUpInside];
        [newSwitchButton setTitle:@"New Switch" forState:UIControlStateNormal];
        [myView addSubview:newSwitchButton];
        [configurationUIElements addObject:newSwitchButton];
        
        UIButton *deleteSwitchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [deleteSwitchButton setFrame:CGRectMake(0, 704, 125, 44)];
        [deleteSwitchButton addTarget:self action:@selector(deleteSwitch:) forControlEvents:UIControlEventTouchUpInside];
        [deleteSwitchButton setTitle:@"Delete Switch" forState:UIControlStateNormal];
        [myView addSubview:deleteSwitchButton];
        [configurationUIElements addObject:deleteSwitchButton];
        
        UIButton *pressActionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [pressActionButton setFrame:CGRectMake(275, 704, 150, 44)];
        [pressActionButton addTarget:self action:@selector(defineAction:) forControlEvents:UIControlEventTouchUpInside];
        [pressActionButton setTitle:@"Action For Touch" forState:UIControlStateNormal];
        [myView addSubview:pressActionButton];
        [configurationUIElements addObject:pressActionButton];
        
        UIButton *releaseActionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [releaseActionButton setFrame:CGRectMake(450, 704, 150, 44)];
        [releaseActionButton addTarget:self action:@selector(defineAction:) forControlEvents:UIControlEventTouchUpInside];
        [releaseActionButton setTitle:@"Action For Release" forState:UIControlStateNormal];
        [myView addSubview:releaseActionButton];
        [configurationUIElements addObject:releaseActionButton];
        
        chooseIconButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [chooseIconButton setFrame:CGRectMake(625, 704, 100, 44)];
        [chooseIconButton addTarget:self action:@selector(chooseIcon:) forControlEvents:UIControlEventTouchUpInside];
        [chooseIconButton setTitle:@"Choose Icon" forState:UIControlStateNormal];
        [myView addSubview:chooseIconButton];
        [configurationUIElements addObject:chooseIconButton];
        
        chooseImageButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [chooseImageButton setFrame:CGRectMake(750, 704, 125, 44)];
        [chooseImageButton addTarget:self action:@selector(chooseImage:) forControlEvents:UIControlEventTouchUpInside];
        [chooseImageButton setTitle:@"Choose Image" forState:UIControlStateNormal];
        [myView addSubview:chooseImageButton];
        [configurationUIElements addObject:chooseImageButton];
        
        recordAudioButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [recordAudioButton setFrame:CGRectMake(900, 704, 124, 44)];
        [recordAudioButton addTarget:self action:@selector(recordAudio:) forControlEvents:UIControlEventTouchUpInside];
        [recordAudioButton setTitle:@"Record Sound" forState:UIControlStateNormal];
        [myView addSubview:recordAudioButton];
        [configurationUIElements addObject:recordAudioButton];
        
        CGRect switchNameTextFieldRect = CGRectMake(250, 0, 200, 44);
        switchNameTextField = [[UITextField alloc] initWithFrame:switchNameTextFieldRect];
        [switchNameTextField addTarget:self action:@selector(onSwitchTextChange:) forControlEvents:UIControlEventEditingDidEndOnExit];
        [switchNameTextField setBackgroundColor:[UIColor whiteColor]];
        [switchNameTextField setTextColor:[UIColor blackColor]];
        [switchNameTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [switchNameTextField setFont:[UIFont systemFontOfSize:14.0f]];
        [switchNameTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
        [switchNameTextField setReturnKeyType:UIReturnKeyDone];
        [myView addSubview:switchNameTextField];
        [configurationUIElements addObject:switchNameTextField];
 
        UIButton *setScanOrderButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [setScanOrderButton setFrame:CGRectMake(700, 0, 124, 44)];
        [setScanOrderButton addTarget:self action:@selector(setScanOrder:) forControlEvents:UIControlEventTouchUpInside];
        [setScanOrderButton setTitle:@"Set Scan Order" forState:UIControlStateNormal];
        [myView addSubview:setScanOrderButton];
        [configurationUIElements addObject:setScanOrderButton];
    } else {
        // If we're not editing, support scanning
        switchScanner = [[SJUIExternalSwitchScanner alloc] initWithSuperview:[self view] andScanType:[[NSUserDefaults standardUserDefaults] integerForKey:@"scanningStylePreference"]];
        [switchScanner setDelegate:self];
    }
    // Set up scanning
    NSArray *scanOrderNodes = [xmlDoc nodesForXPath:@".//panel/scanorder" error:&xmlError];
    if([scanOrderNodes count]) {
        // Override any defaults we have
        scanOrderIndices = [NSMutableArray arrayWithCapacity:20];
        DDXMLNode *scanOrderNode = [scanOrderNodes objectAtIndex:0];
        NSString *scanOrderString = [scanOrderNode stringValue];
        NSScanner *scanOrderScan = [[NSScanner alloc] initWithString:scanOrderString];
        int scanIndex;
        while([scanOrderScan scanInt:&scanIndex]) {
            [scanOrderIndices addObject:[NSNumber numberWithInt:scanIndex]];
        }
    }
    if(switchScanner ) {
        NSNumber *scanIndexNumber;
        for(scanIndexNumber in scanOrderIndices) {
            [switchScanner addButtonToScan:[[[self view] subviews] objectAtIndex:[scanIndexNumber integerValue]] withLabel:nil];
        }
    }

    if(userButtonsHidden)
        [self hideUserButtons];

}

- (void) viewDidAppear:(BOOL)animated {
    if(switchScanner != nil)
        [switchScanner superviewDidAppear];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if(interfaceOrientation == UIInterfaceOrientationLandscapeRight)
        return YES;
    return NO;
}

// Scanning support
- (void) SJUIExternalSwitchScannerItemWasSelected:(id)item {
    // Nothing for now
}

- (void) SJUIExternalSwitchScannerItemWasActivated:(id)item {
    if(item == backButton)
        [self goBack:item];
    else
        [self onSwitchActivated:item];
}



// Handlers for switches activated/deactivated. Send XML node information to delegate.
- (IBAction)onSwitchActivated:(id)sender {
    [self disallowNavigation:sender];
    SJUIButtonWithActions *button = (SJUIButtonWithActions *)sender;
    NSArray *actions = [button activateActions];
    if(actions == nil) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        return;
    }
    DDXMLNode *action;
    for(action in actions) {
        [appDelegate performActionSequence:action];
    }
    if([button audioFilePath]) {
        // Play sound
        if(player)
            [player stop];
        NSError *sessionError;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
        if(sessionError)
            NSLog(@"SJUIRecordAudioViewController: Audio session error: %@", sessionError);
        NSError *playError;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[button audioFilePath]] error:&playError];
        if(playError) {
            NSLog(@"Play error: %@", playError);
            return;
        }
        player.numberOfLoops = 0;
        [player play];
    }
}
- (IBAction)onSwitchDeactivated:(id)sender {
    [self disallowNavigation:sender];
    NSArray *actions = [sender deactivateActions];
    if(actions == nil) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        return;
    }
    DDXMLNode *action;
    for(action in actions) {
        [appDelegate performActionSequence:action];
    }
}
// Navigation back to root controller
- (IBAction)allowNavigation:(id)sender {
    [confirmDeleteButton setHidden:YES];
    [backButton setEnabled:YES];
}
- (IBAction)disallowNavigation:(id)sender{
    [confirmDeleteButton setHidden:YES];
    [backButton setEnabled:oneButtonNavigation];
}
- (IBAction)goBack:(id)sender{
    UINavigationController *navController = self.navigationController;
    if(editingActive) {
        [self savePanelToPath:urlToLoad];
        [self.navigationController popViewControllerAnimated:NO];
        // Push another panel that is the same as this one, but not being edited
        switchPanelViewController *newViewController = [switchPanelViewController alloc];
        [newViewController setUrlToLoad:[self urlToLoad]];
        [navController pushViewController:newViewController animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

NSURL *GetURLWithNoConflictWithName(NSString *name, NSString *extension);
NSURL *GetURLWithNoConflictWithName(NSString *name, NSString *extension) {
    unsigned int i=0;
    NSURL *newFileURL;
    do {
        ++i;
        NSString *fileName = [NSString stringWithFormat:@"%@ %d.%@", name, i, extension];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        newFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]]);
    return newFileURL;
}

// Replace the current panel with one that enables editing
- (void)editPanel:(id)sender {
    appDelegate->panelWasEdited = YES;
    switchPanelViewController *newViewController = [switchPanelViewController alloc];
    // If this is a built-in panel, save it to a new file that we'll edit
    if(isBuiltInPanel) {
        urlToLoad = GetURLWithNoConflictWithName(@"Panel", @"xml");
        // Create a new name for the panel
        [self setSwitchPanelName:[[urlToLoad lastPathComponent] stringByDeletingPathExtension]];
        [self savePanelToPath:urlToLoad];
        NSString *panelNameWithExtension = [urlToLoad lastPathComponent];
        [newViewController setSwitchPanelName:[panelNameWithExtension stringByDeletingPathExtension]];
    }
    UINavigationController *navController = self.navigationController;
    [navController popViewControllerAnimated:NO];
    [newViewController setUrlToLoad:[self urlToLoad]];
    [newViewController setEditingActive:YES];
    UIView *view = [newViewController view]; // Force initialization
    view = view; // Suppress warning
    [navController pushViewController:newViewController animated:YES];
    [Flurry logEvent:@"EditPanel Pressed"];
}


// Save the panel to a specified file
- (void)savePanelToPath:(NSURL *)url {
    UIView *panelView = [self view];
    NSMutableString *stringToSave = [NSMutableString stringWithCapacity:500];
    [stringToSave setString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
    [stringToSave appendString:@"<panel>\n"];
    [stringToSave appendString:[NSString stringWithFormat:@"\t<panelname>%@</panelname>\n", [self switchPanelName]]];
    // Loop over all panel elements
    UIView *view;
    for(view in [panelView subviews]) {
        if(![view isKindOfClass:[UIButton class]])
            continue; // Only look at buttons
        SJUIButtonWithActions *button = (SJUIButtonWithActions *)view;
        // Don't save UI buttons
        NSString *buttonTitle = [button titleForState:UIControlStateNormal];
        if(([buttonTitle isEqualToString:@"Back"]) || ([buttonTitle isEqualToString:@"Enable Back Button"]) || ([buttonTitle isEqualToString:@"Edit Panel"]) || ([buttonTitle isEqualToString:@"Delete Panel"]) || ([buttonTitle isEqualToString:@"Confirm Delete"]) || ([buttonTitle isEqualToString:@"Set Scan Order"])) {
            continue;  
        }
        // Ignore buttons along the bottom and on the right - color changers, etc
        if([button frame].origin.y > 700)
            continue;
        if([button frame].origin.x > 950)
            continue;
        [stringToSave appendString:@"\t<panelelement>\n"];
        CGRect frame = [button frame];
        [stringToSave appendString:[NSString stringWithFormat:@"\t\t<frame>%d %d %d %d</frame>\n", (int)frame.origin.x, (int)frame.origin.y, (int)frame.size.width, (int)frame.size.height]];
        CGFloat r, g, b, a;
        // iOS 5.0 allows getRed green blue, but for earlier releases we need this strange thing
#if 0
        [[button backgroundColor] getRed:&r green:&g blue:&b alpha:&a];
#else
        CGColorRef color = [[button backgroundColor] CGColor];
        const CGFloat *components = CGColorGetComponents(color);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
#endif
        [stringToSave appendString:[NSString stringWithFormat:@"\t\t<rgbacolor>%3.1f %3.1f %3.1f %3.1f</rgbacolor>\n", r, g, b, a]];
        if(buttonTitle)
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t<switchtext>%@</switchtext>\n", buttonTitle]];
        if([button imageFilePath]) {
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t<image>%@</image>\n", [button imageFilePath]]];
        }
        if([button iconName]) {
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t<icon>%@</icon>\n", [button iconName]]];
        }
        if([button audioFilePath]) {
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t<audioforswitchactivate>%@</audioforswitchactivate>\n", [button audioFilePath]]];
        }
        // Store actions for switch activate and deactivate
        [stringToSave appendString:@"\t\t<onswitchactivate>\n"];
        NSArray *actions = [button activateActions];
        DDXMLNode *action;
        for(action in actions) {
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t\t%@\n", [action XMLString]]];
        }
        [stringToSave appendString:@"\t\t</onswitchactivate>\n"];
        [stringToSave appendString:@"\t\t<onswitchdeactivate>\n"];
        actions = [button deactivateActions];
        for(action in actions) {
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t\t%@\n", [action XMLString]]];
        }
        [stringToSave appendString:@"\t\t</onswitchdeactivate>\n"];
        [stringToSave appendString:@"\t</panelelement>\n"];
    }
    // Add scanning info
    [stringToSave appendString:@"<scanorder>"];
    NSNumber *num;
    for(num in scanOrderIndices) {
        [stringToSave appendString:[NSString stringWithFormat:@"%d ", [num integerValue]]];
    }
    [stringToSave appendString:@"</scanorder>"];
    
    [stringToSave appendString:@"</panel>"];
    NSError *fileError;
    [stringToSave writeToURL:url atomically:YES encoding:NSASCIIStringEncoding error:&fileError];
    if(fileError) {
        NSLog(@"File write error: %@", fileError);
    }
}

// Configuration UI
- (void)onPanelNameChange:(id)sender {
    [confirmDeleteButton setHidden:YES];
    [self setSwitchPanelName:[panelNameTextField text]];
}

- (void)deletePanel:(id)sender {
    if(sender == confirmDeleteButton) {
        appDelegate->panelWasEdited = YES;
        NSError *fileError;
        [[NSFileManager defaultManager] removeItemAtURL:urlToLoad error:&fileError];
        if(fileError) {
            NSLog(@"Error deleting panel. Url = %@, error = %@", urlToLoad, fileError);
        }
        // Clean up after each switch - particularly images
        UIView *thisView;
        for(thisView in [[self view] subviews]) {
            if([thisView isKindOfClass:[SJUIButtonWithActions class]]) {
                currentButton = (SJUIButtonWithActions *) thisView;
                [self deleteSwitch:confirmDeleteButton];
            }
        }
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [confirmDeleteButton setHidden:NO];
}

- (void)deleteSwitch:(id)sender {
    if(confirmDeleteButton != nil) 
        [confirmDeleteButton setHidden:YES];
    if(currentButton == nil)
        return;
    if(![currentButton isKindOfClass:[SJUIButtonWithActions class]]) {
        NSLog(@"deleteSwitch: currentButton is not nil but also not a SJUIButtonWithActions");
        return;
    }
    if(sender == confirmDeleteButton) {
        // Remove any image file this button references
        NSError *fileError;
        [[NSFileManager defaultManager] removeItemAtPath:[currentButton imageFilePath] error:&fileError];
        if(fileError)
            NSLog(@"Error deleting image at %@: %@", [currentButton imageFilePath], fileError);
        // Remove any audio file as well
        [[NSFileManager defaultManager] removeItemAtPath:[currentButton audioFilePath] error:&fileError];
        if(fileError)
            NSLog(@"Error deleting image at %@: %@", [currentButton audioFilePath], fileError);
        [currentButton removeFromSuperview];
        currentButton = nil;
        return;
    }
    [confirmDeleteButton setHidden:NO];
}

- (void)newSwitch:(id)sender {
    [confirmDeleteButton setHidden:YES];
    SJUIButtonWithActions *newButton = [SJUIButtonWithActions buttonWithType:UIButtonTypeCustom];
    [newButton setFrame:CGRectMake(100,100,400,200)];
    [newButton setBackgroundColor:[UIColor blueColor]];
    [newButton addTarget:self action:@selector(onButtonDrag:withEvent:) forControlEvents:(UIControlEventTouchDragInside)]; 
    [newButton addTarget:self action:@selector(onButtonSelect:) forControlEvents:(UIControlEventTouchDown)]; 
    [newButton setTitle:@"Switch" forState:UIControlStateNormal];
    [newButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [[newButton titleLabel] setFont:[UIFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"]]];
    [newButton setActivateActions:[[NSMutableArray alloc] initWithCapacity:5]];
    [newButton setDeactivateActions:[[NSMutableArray alloc] initWithCapacity:5]];
    [[self view] addSubview:newButton];
    [Flurry logEvent:@"NewSwitch Pressed"];
}

- (void)onButtonDrag:(id)sender withEvent:(UIEvent *)event {
    [confirmDeleteButton setHidden:YES];
    if(settingScanOrder)
        return;
    NSSet *touches = [event allTouches];
    if([touches count] != 1)
        return;
    CGPoint point = [[touches anyObject] locationInView:self.view];
    UIControl *control = sender;
    if(sender == currentButtonBeingDragged) {
        CGPoint newCenter = CGPointMake(control.center.x + point.x - currentButtonBeingDraggedLastPoint.x, control.center.y + point.y - currentButtonBeingDraggedLastPoint.y);
        control.center = newCenter;
    } else {
        currentButtonBeingDragged = sender;
    }
    currentButtonBeingDraggedLastPoint = [[[event allTouches] anyObject] locationInView:self.view];
}

- (void)onButtonSelect:(id)sender withEvent:(UIEvent *)event {
    [confirmDeleteButton setHidden:YES];
    currentButton = sender;
    currentButtonBeingDragged = sender;
    currentButtonBeingDraggedLastPoint = [[[event allTouches] anyObject] locationInView:self.view];
    if(settingScanOrder) {
        int index = [[[self view] subviews] indexOfObject:sender];
        if(index == NSNotFound) {
            NSLog(@"switchPanelViewController: onButtonSelect: index not found.\n");
            return;
        }
        NSNumber *indexForArray = [NSNumber numberWithInt:index];
        [scanOrderIndices addObject:indexForArray];
        return;
    }
    // Highlight button
    [currentButton setHighlighted:YES];
    // Update switch name field
    [switchNameTextField setText:[currentButton titleForState:UIControlStateNormal]];
    if([currentButton backgroundImageForState:UIControlStateNormal])
        [chooseImageButton setTitle:@"Remove Image" forState:UIControlStateNormal];
    else {
        [chooseImageButton setTitle:@"Choose Image" forState:UIControlStateNormal];
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:[currentButton audioFilePath]]) {
        // Play sound when button is selected
        if(player)
            [player stop];
        NSError *sessionError;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
        if(sessionError)
            NSLog(@"SJUIRecordAudioViewController: Audio session error: %@", sessionError);
        NSError *playError;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[currentButton audioFilePath]] error:&playError];
        if(playError) {
            NSLog(@"Play error: %@", playError);
            return;
        }
        player.numberOfLoops = 0;
        [player play];
        
        [recordAudioButton setTitle:@"Delete Sound" forState:UIControlStateNormal];
    } else {
        [recordAudioButton setTitle:@"Record Sound" forState:UIControlStateNormal];
    }
}

- (void)onPinch:(id)sender {
    [confirmDeleteButton setHidden:YES];
    UIPinchGestureRecognizer *gestureRecognizer = sender;
    float scale = [gestureRecognizer scale];
    if([gestureRecognizer state] == UIGestureRecognizerStateEnded) {
        lastPinchScale = 1.0;
    }
    if(currentButton == nil)
        return;
    if([gestureRecognizer numberOfTouches] != 2)
        return;
    if([gestureRecognizer state] != UIGestureRecognizerStateChanged) 
        return;
    
    float relativeScale = scale / lastPinchScale;
    lastPinchScale = scale;
    CGPoint pt1 = [gestureRecognizer locationOfTouch:0 inView:[self view]];
    CGPoint pt2 = [gestureRecognizer locationOfTouch:1 inView:[self view]];
    CGRect buttonRect = [currentButton frame];
    // Adjust either width or height depending on position of touches
    if(fabs(pt1.x - pt2.x) > fabs(pt1.y-pt2.y)) {
        float currentWidth = buttonRect.size.width;
        buttonRect.size.width = currentWidth * relativeScale;
        buttonRect.origin.x += (currentWidth - buttonRect.size.width)/2.0;
    } else {
        float currentHeight = buttonRect.size.height;
        buttonRect.size.height = currentHeight * relativeScale;
        buttonRect.origin.y += (currentHeight - buttonRect.size.height)/2.0;
    }
    [currentButton setFrame:buttonRect];
}

- (void)onSetColor:(id)sender {
    [confirmDeleteButton setHidden:YES];
    if(currentButton == nil)
        return;
    UIButton *senderButton = sender;
    [currentButton setBackgroundColor:[senderButton backgroundColor]];
}

- (void)onSwitchTextChange:(id)sender {
    [confirmDeleteButton setHidden:YES];
    if(currentButton == nil)
        return;
    UITextField *testField = sender;
    [currentButton setTitle:[testField text] forState:UIControlStateNormal];
}

- (void)defineAction:(id)sender {
    [confirmDeleteButton setHidden:YES];
    if(currentButton == nil)
        return;
    UIButton *senderButton = sender;
    NSMutableArray *actions;
    if([[senderButton titleForState:UIControlStateNormal] isEqualToString:@"Action For Touch"])
        actions = [currentButton activateActions];
    else {
        actions = [currentButton deactivateActions];
    }
    defineActionViewController *newViewController = [[defineActionViewController alloc] initWithActions:actions appDelegate:appDelegate];
    [newViewController setDelegate:self];
    actionPopover = [[UIPopoverController alloc] initWithContentViewController:newViewController];
    [actionPopover setDelegate:self];
    [actionPopover presentPopoverFromRect:[sender frame] inView:[self view] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [Flurry logEvent:@"DefineAction Pressed"];
}

- (void)chooseImage:(id)sender {
    [confirmDeleteButton setHidden:YES];
    if(currentButton == nil)
        return;
    if([currentButton backgroundImageForState:UIControlStateNormal]) {
        // Remove the image
        NSError *fileError;
        [[NSFileManager defaultManager] removeItemAtPath:[currentButton imageFilePath] error:&fileError];
        [currentButton setBackgroundImage:nil forState:UIControlStateNormal];
        [currentButton setImageFilePath:nil];
        [chooseImageButton setTitle:@"Choose Image" forState:UIControlStateNormal];
        return;
    }
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        return;
    SJUIImagePickerController *mediaUI = [[SJUIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = YES;
    mediaUI.delegate = self;
    imagePopover = [[UIPopoverController alloc] initWithContentViewController:mediaUI];
    [imagePopover presentPopoverFromRect:[sender frame] inView:[self view] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [Flurry logEvent:@"ChooseImage Pressed"];
}

- (void)recordAudio:(id)sender {
    [confirmDeleteButton setHidden:YES];
    if(currentButton == nil)
        return;
    if([currentButton audioFilePath]) {
        // Remove the audio file
        NSError *fileError;
        [[NSFileManager defaultManager] removeItemAtPath:[currentButton audioFilePath] error:&fileError];
        [currentButton setAudioFilePath:nil];
        [recordAudioButton setTitle:@"Record Sound" forState:UIControlStateNormal];
        return;
    }
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        return;
    NSURL *audioURL = GetURLWithNoConflictWithName(@"Audio", @"caf");
    SJUIRecordAudioViewController *audioViewController = [[SJUIRecordAudioViewController alloc] initWithURL:audioURL andDelegate:self];
    audioPopover = [[UIPopoverController alloc] initWithContentViewController:audioViewController];
    [currentButton setAudioFilePath:[audioURL path]];
    [audioPopover setDelegate:self];
    [audioPopover presentPopoverFromRect:[sender frame] inView:[self view] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [Flurry logEvent:@"RecordAudio Pressed"];
}

- (void)chooseIcon:(id)sender {
    [confirmDeleteButton setHidden:YES];
    if(currentButton == nil)
        return;

    chooseIconViewController *iconViewController = [[chooseIconViewController alloc] init];
    [iconViewController setIconName:[currentButton iconName]];
    
    iconPopover = [[UIPopoverController alloc] initWithContentViewController:iconViewController];
    [iconPopover setDelegate:self];
    [iconPopover presentPopoverFromRect:[sender frame] inView:[self view] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [Flurry logEvent:@"ChooseIcon Pressed"];
}

- (void) setScanOrder:(id)sender {
    UIButton *setScanOrderButton = (UIButton *)sender;
    NSString *currentTitle = [setScanOrderButton titleForState:UIControlStateNormal];
    if([currentTitle isEqualToString:@"Set Scan Order"]) {
        [setScanOrderButton setTitle:@"End of Scan" forState:UIControlStateNormal];
        // Hide rest of UI
        UIView *view;
        for(view in configurationUIElements)
            [view setHidden:YES];
        [backButton setHidden:YES];
        [setScanOrderButton setHidden:NO]; // Keep this button
        settingScanOrder = YES;
        scanOrderIndices = [NSMutableArray arrayWithCapacity:10];
    } else {
        [setScanOrderButton setTitle:@"Set Scan Order" forState:UIControlStateNormal];
        [Flurry logEvent:@"Scan Order Set"];
        // Bring back UI
        UIView *view;
        for(view in configurationUIElements)
            [view setHidden:NO];
        [backButton setHidden:NO];
        //NSNumber *num;
        //for (num in scanOrderIndices)
        //    NSLog(@"Scan order: %d", [num integerValue]);
        settingScanOrder = NO;
    }
}

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    UIImage *imageToUse;
    UIImage *editedImage = (UIImage *) [info objectForKey:
                               UIImagePickerControllerEditedImage];
    UIImage *originalImage = (UIImage *) [info objectForKey:
                                 UIImagePickerControllerOriginalImage];
    if (editedImage) {
        imageToUse = editedImage;
    } else {
        imageToUse = originalImage;
    }
    
    [currentButton setBackgroundImage:imageToUse forState:UIControlStateNormal];
    // Choose a file name for the image and assign it to the button
    NSURL *imageURL = GetURLWithNoConflictWithName(@"Image", @"jpg");
    [currentButton setImageFilePath:[imageURL path]];
    NSData *imageData = UIImageJPEGRepresentation(imageToUse, 0.9);
    [imageData writeToURL:imageURL atomically:YES]; 
    [imagePopover setPopoverContentSize:CGSizeMake(200, 250)];
    [imagePopover dismissPopoverAnimated:YES];
    [chooseImageButton setTitle:@"Remove Image" forState:UIControlStateNormal];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [imagePopover dismissPopoverAnimated:YES];
}

- (void) SJUIRecordAudioViewControllerReadyForDismissal:(id)viewController {
    [audioPopover dismissPopoverAnimated:YES];
    [self popoverControllerDidDismissPopover:audioPopover];
}

- (void) SJUIDefineActionViewControllerReadyForDismissal:(id)viewController {
    [actionPopover dismissPopoverAnimated:YES];
    [self popoverControllerDidDismissPopover:actionPopover];
}


-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    if(popoverController == actionPopover) {
        return NO; // Only dismissed by cancel button
    }
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    //NSLog(@"switchPanelViewController: popoverControllerDidDismissPopover");
    if(popoverController == audioPopover) {
        // Check if we have valid audio for the switch
        if(!currentButton)
            return;
        if(![currentButton audioFilePath])
            return;
        if([[NSFileManager defaultManager] fileExistsAtPath:[currentButton audioFilePath]]) {
            [recordAudioButton setTitle:@"Delete Sound" forState:UIControlStateNormal];
        } else {
            [recordAudioButton setTitle:@"Record Sound" forState:UIControlStateNormal];
            [currentButton setAudioFilePath:nil];
        }
    }
    if(popoverController == iconPopover) {
        if(!currentButton)
            return;
        chooseIconViewController *iconVC = (chooseIconViewController *)[iconPopover contentViewController];
        [currentButton setIconName:[iconVC iconName]];
        if(![currentButton iconName])
            [currentButton setImage:nil forState:UIControlStateNormal];
        else
            [currentButton setImage:[[UIImage imageNamed:[currentButton iconName]] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f] forState:UIControlStateNormal];
    }
}

// This function is useful when displaying the viewcontroller as a sub-view of a larger view
- (void) hideUserButtons {
    if(backButton)
        [backButton setHidden:YES];
    if(editButton)
        [editButton setHidden:YES];
    if(deleteButton)
        [deleteButton setHidden:YES];
    if(allowNavButton)
        [allowNavButton setHidden:YES];
    userButtonsHidden = YES;
}
@end
