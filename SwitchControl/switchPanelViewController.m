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

@implementation switchPanelViewController

@synthesize activateButtonDictionary;
@synthesize deactivateButtonDictionary;
@synthesize urlToLoad;
@synthesize switchPanelName;
@synthesize editingActive;
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
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
    UIColor *bgColor = [appDelegate backgroundColor];
    
	CGRect cgRct = CGRectMake(0, 20, 1024, 748);
    UIView *myView = [[UIView alloc] initWithFrame:cgRct];
    [myView setBackgroundColor:bgColor];
	myView.autoresizesSubviews = YES;
    [self setActivateButtonDictionary:[NSMutableDictionary dictionaryWithCapacity:10]]; 
    [self setDeactivateButtonDictionary:[NSMutableDictionary dictionaryWithCapacity:10]]; 
    
    NSError *xmlError=nil, *fileError=nil;
    NSString *xmlString = [NSString stringWithContentsOfURL:urlToLoad encoding:NSUTF8StringEncoding error:&fileError];
    
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
        NSArray *frameNodes = [element nodesForXPath:@".//frame" error:&xmlError];
        NSArray *colorNodes = [element nodesForXPath:@".//rgbacolor" error:&xmlError];
        NSArray *textNodes = [element nodesForXPath:@".//switchtext" error:&xmlError];
        NSArray *activateNodes = [element nodesForXPath:@".//onswitchactivate/actionsequenceondevice" error:&xmlError];
        NSArray *deactivateNodes = [element nodesForXPath:@".//onswitchdeactivate/actionsequenceondevice" error:&xmlError];

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
        id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myButton setFrame:buttonRect];
        [myButton setBackgroundColor:[UIColor colorWithRed:r green:g blue:b alpha:a]];
        [myButton addTarget:self action:@selector(onSwitchActivated:) forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragEnter)]; 
        [myButton addTarget:self action:@selector(onSwitchDeactivated:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragExit)];
        
        // Read text for switch
        if([textNodes count]) {
            [myButton setTitle:[[textNodes objectAtIndex:0] stringValue] forState:UIControlStateNormal];
        } 
        [myButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        // Associate the actions for pressing the button
        NSValue *value = [NSValue valueWithNonretainedObject:myButton];
        [[self activateButtonDictionary] setObject:activateNodes forKey:value];
        [[self deactivateButtonDictionary] setObject:deactivateNodes forKey:value];
        
        [myView addSubview:myButton];
    }
    
    oneButtonNavigation = [[NSUserDefaults standardUserDefaults] boolForKey:@"singleTapBackButtonPreference"] & !editingActive;
    bool allowEditing = [[NSUserDefaults standardUserDefaults] boolForKey:@"allowEditingOfSwitchPanelsPreference"];
    CGRect backButtonRect;
    backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    if(!oneButtonNavigation) {
        // If we're allowing editing, don't bother with "Enable Back Button"
        if(!allowEditing) {
            // Create two-button combo to allow navigation
            id allowNavButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
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
        backButtonRect = CGRectMake(0, 0, backButtonWidth, backButtonHeight);
        [backButton setEnabled:YES];
    }
    [backButton setFrame:backButtonRect];
    [backButton setTitle:[NSString stringWithCString:"Back" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
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
            id editButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            CGRect buttonRect = CGRectMake(150, 0, 100, 44);
            [editButton setFrame:buttonRect];
            [editButton setTitle:[NSString stringWithCString:"Edit Panel" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
            [editButton addTarget:self action:@selector(editPanel:) forControlEvents:UIControlEventTouchUpInside]; 
            [myView addSubview:editButton];
        }
        // If this panel is built-in or we're editting it, don't allow deleting it
        if(!isBuiltInPanel && !editingActive) {
            id deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            CGRect buttonRect = CGRectMake(300, 0, 100, 44);
            [deleteButton setFrame:buttonRect];
            [deleteButton setTitle:[NSString stringWithCString:"Delete Panel" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
            [deleteButton addTarget:self action:@selector(deletePanel:) forControlEvents:UIControlEventTouchUpInside]; 
            [myView addSubview:deleteButton];
        }
    }
    // Show status
    CGRect textRect = CGRectMake(700, 0, 324, 36);
    textToShowSwitchName = [[SJUIStatusMessageLabel alloc] initWithFrame:textRect];
    [textToShowSwitchName setBackgroundColor:bgColor];
    [myView addSubview:textToShowSwitchName];

    // OK always to create hidden button
    confirmDeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmDeleteButton setFrame:CGRectMake(412, 704, 200, 44)];
    [confirmDeleteButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f] forState:UIControlStateNormal];
    [confirmDeleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmDeleteButton setTitle:@"Confirm Delete" forState:UIControlStateNormal];
    [confirmDeleteButton addTarget:self action:@selector(deletePanel:) forControlEvents:UIControlEventTouchUpInside];
    [confirmDeleteButton setHidden:YES];
    [myView addSubview:confirmDeleteButton];
    
    // Display configuration UI
    if(editingActive) {
        CGRect panelNameTextFieldRect = CGRectMake(50, 0, 200, 31);
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
    }
    
	self.view = myView;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

// Handlers for switches activated/deactivated. Send XML node information to delegate.
- (IBAction)onSwitchActivated:(id)sender {
    [self disallowNavigation:sender];
    NSValue *value = [NSValue valueWithNonretainedObject:sender];
    NSArray *actions = [[self activateButtonDictionary] objectForKey:value];
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
- (IBAction)onSwitchDeactivated:(id)sender {
    [self disallowNavigation:sender];
    NSValue *value = [NSValue valueWithNonretainedObject:sender];
    NSArray *actions = [[self deactivateButtonDictionary] objectForKey:value];
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

NSURL *GetURLWithNoConflictWithName(NSString *name);
NSURL *GetURLWithNoConflictWithName(NSString *name) {
    unsigned int i=0;
    NSURL *newFileURL;
    do {
        ++i;
        NSString *fileName = [NSString stringWithFormat:@"%@ %d.xml", name, i];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        newFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]]);
    return newFileURL;
}

// Replace the current panel with one that enables editing
- (void)editPanel:(id)sender {
    // If this is a built-in panel, save it to a new file that we'll edit
    if(isBuiltInPanel) {
        urlToLoad = GetURLWithNoConflictWithName(@"Panel");
        // Create a new name for the panel
        [self setSwitchPanelName:[[urlToLoad lastPathComponent] stringByDeletingPathExtension]];
        [self savePanelToPath:urlToLoad];
    }
    UINavigationController *navController = self.navigationController;
    [navController popViewControllerAnimated:NO];
    switchPanelViewController *newViewController = [switchPanelViewController alloc];
    [newViewController setUrlToLoad:[self urlToLoad]];
    [newViewController setEditingActive:YES];
    UIView *view = [newViewController view]; // Force initialization
    view = view; // Suppress warning
    NSString *panelNameWithExtension = [urlToLoad lastPathComponent];
    [newViewController setSwitchPanelName:[panelNameWithExtension stringByDeletingPathExtension]];
    [navController pushViewController:newViewController animated:YES];
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
        UIButton *button = (UIButton *)view;
        // Don't save UI buttons
        NSString *buttonTitle = [button titleForState:UIControlStateNormal];
        if(([buttonTitle isEqualToString:@"Back"]) || ([buttonTitle isEqualToString:@"Enable Back Button"]) || ([buttonTitle isEqualToString:@"Edit Panel"]) || ([buttonTitle isEqualToString:@"Delete Panel"]) || ([buttonTitle isEqualToString:@"Confirm Delete"])) {
            continue;  
        }
        [stringToSave appendString:@"\t<panelelement>\n"];
        CGRect frame = [button frame];
        [stringToSave appendString:[NSString stringWithFormat:@"\t\t<frame>%d %d %d %d</frame>\n", (int)frame.origin.x, (int)frame.origin.y, (int)frame.size.width, (int)frame.size.height]];
        CGFloat r, g, b, a;
        [[button backgroundColor] getRed:&r green:&g blue:&b alpha:&a];
        [stringToSave appendString:[NSString stringWithFormat:@"\t\t<rgbacolor>%3.1f %3.1f %3.1f %3.1f</rgbacolor>\n", r, g, b, a]];
        [stringToSave appendString:[NSString stringWithFormat:@"\t\t<switchtext>%@</switchtext>\n", [button titleForState:UIControlStateNormal]]];
        // Store actions for switch activate and deactivate
        NSValue *value = [NSValue valueWithNonretainedObject:button];
        [stringToSave appendString:@"\t\t<onswitchactivate>\n"];
        NSArray *actions = [[self activateButtonDictionary] objectForKey:value];
        DDXMLNode *action;
        for(action in actions) {
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t\t%@\n", [action XMLString]]];
        }
        [stringToSave appendString:@"\t\t</onswitchactivate>\n"];
        [stringToSave appendString:@"\t\t<onswitchdeactivate>\n"];
        actions = [[self deactivateButtonDictionary] objectForKey:value];
        for(action in actions) {
            [stringToSave appendString:[NSString stringWithFormat:@"\t\t\t%@\n", [action XMLString]]];
        }
        [stringToSave appendString:@"\t\t</onswitchdeactivate>\n"];
        [stringToSave appendString:@"\t</panelelement>\n"];
    }
    [stringToSave appendString:@"</panel>"];
    NSError *fileError;
    [stringToSave writeToURL:url atomically:YES encoding:NSASCIIStringEncoding error:&fileError];
    if(fileError) {
        NSLog(@"File write error: %@", fileError);
    }
}

// Configuration UI
- (void)onPanelNameChange:(id)sender {
    [self setSwitchPanelName:[panelNameTextField text]];
}

- (void)deletePanel:(id)sender {
    if(sender == confirmDeleteButton) {
        NSError *fileError;
        [[NSFileManager defaultManager] removeItemAtURL:urlToLoad error:&fileError];
        if(fileError) {
            NSLog(@"Error deleting panel. Url = %@, error = %@", urlToLoad, fileError);
        }
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [confirmDeleteButton setHidden:NO];
}

@end
