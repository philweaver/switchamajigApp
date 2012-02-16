//
//  rootSwitchViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "rootSwitchViewController.h"
#import "switchPanelViewController.h"
#import "helpDisplayViewController.h"
#import "configViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation rootSwitchViewController
@synthesize bgColorLabel;
@synthesize bgColorSegControl;
@synthesize helpButton;
@synthesize panelSelectionScrollView;
@synthesize switchNameTableView;
@synthesize SwitchStatusText;
@synthesize SwitchStatusActivity;

- (void)dealloc {
    [switchNameTableView release];
    switchNameTableView = nil;
    [switchNameTableView release];
    [panelSelectionScrollView release];
    CFRelease(switchPanelURLDictionary);
    [SwitchStatusText release];
    [SwitchStatusActivity release];
    [helpButton release];
    [bgColorSegControl release];
    [bgColorLabel release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication]delegate];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
#define switch_select_button_w 102
#define switch_select_button_h 77
#define switch_select_button_spacing 50
#define switch_label_height 36
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // Make background color selector disappear
    [bgColorLabel setHidden:YES];
    [bgColorSegControl setHidden:YES];
    // Make nav bar disappear
    [[self navigationController] setNavigationBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switch_names_updated:) name:@"switch_list_was_updated" object:nil];
    [self initializeScrollPanelWithSwitchPanels];
}

- (void)initializeScrollPanelWithSwitchPanels {
    UIColor *bgColor = [UIColor blackColor];
    UIColor *fgColor = [UIColor whiteColor];

    if(switchPanelURLDictionary) {
        CFDictionaryRemoveAllValues(switchPanelURLDictionary);
        CFRelease(switchPanelURLDictionary);
    }
    switchPanelURLDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    // Find all switch panel files
    NSArray *xmlUrls = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"xml" subdirectory:nil];
    NSURL *url;
    
    int current_button_x = switch_select_button_spacing;
    int current_button_y = switch_select_button_spacing;
    
    for(url in xmlUrls) {
        // Render view controller into image
        switchPanelViewController *viewController = [switchPanelViewController alloc];
        [viewController setUrlToLoad:url];
        CGSize size = [[viewController view] bounds].size;
        UIGraphicsBeginImageContext(size);
        [[[viewController view] layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // Create button with image
        // Create the specified button
        id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myButton setFrame:CGRectMake((CGFloat)current_button_x, (CGFloat)current_button_y, switch_select_button_w, switch_select_button_h)];
        // Also set rectangle for label
        CGRect panelNameLabelRect = CGRectMake((CGFloat)current_button_x, (CGFloat)current_button_y + switch_select_button_h, switch_select_button_w, switch_label_height);
        [myButton addTarget:self action:@selector(launchSwitchPanel:) forControlEvents:(UIControlEventTouchUpInside)]; 
        [panelSelectionScrollView addSubview:myButton];
        current_button_y += switch_select_button_h + switch_select_button_spacing;
        if(current_button_y + switch_select_button_h >= [panelSelectionScrollView bounds].size.height) {
            current_button_y = switch_select_button_spacing;
            current_button_x += switch_select_button_w + switch_select_button_spacing;
        }
        size = [myButton bounds].size;
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [myButton setImage:scaledImage forState:UIControlStateNormal];
        // Add text label
         UILabel *panelNameLabel = [[UILabel alloc] initWithFrame:panelNameLabelRect];
        [panelNameLabel setBackgroundColor:bgColor];
        [panelNameLabel setTextColor:fgColor];
        [panelNameLabel setText:[viewController switchPanelName]];
        [panelNameLabel setTextAlignment:UITextAlignmentCenter];
        [panelSelectionScrollView addSubview:panelNameLabel];
        [panelNameLabel release];
        [viewController release];
        CFDictionaryAddValue(switchPanelURLDictionary, myButton, url);
    }
    [panelSelectionScrollView setContentSize:CGSizeMake(current_button_x, 100)];
    [panelSelectionScrollView setScrollEnabled:YES];
}

- (void)viewDidUnload
{
    [self setSwitchNameTableView:nil];
    [self setPanelSelectionScrollView:nil];
    [self setSwitchStatusText:nil];
    [self setSwitchStatusActivity:nil];
    [self setHelpButton:nil];
    [self setBgColorSegControl:nil];
    [self setBgColorLabel:nil];
    [super viewDidUnload];
    CFRelease(switchPanelURLDictionary);

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    return NO;
}

-(void)ResetScrollPanel {
    // Deconstruct the scroll panel
    NSArray *subviewArray = [panelSelectionScrollView subviews];
    UIView *thisView;
    for(thisView in subviewArray) {
        NSArray *subviewArray2 = [thisView subviews];
        UIView *thisView2;
        for(thisView2 in subviewArray2) {
            [thisView2 removeFromSuperview];
        }
        [thisView removeFromSuperview];
    }
    // Reinitialize the scroll panel
    [self initializeScrollPanelWithSwitchPanels];
}


-(void) viewWillAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES];
    [self reload_switch_name_table];
}

- (IBAction)launchSwitchPanel:(id)sender {
    // Load programatically-created view
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    NSURL *url;
    if(!CFDictionaryGetValueIfPresent(switchPanelURLDictionary, sender, (const void **) &url)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Select error!" message:@"Panel dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        [viewController release];
        return;
    }

    [viewController setUrlToLoad:url];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (IBAction)display_help:(id)sender {
    [[self navigationController] setNavigationBarHidden:NO];
    helpDisplayViewController *helpViewCtrl = [helpDisplayViewController alloc];
    [self.navigationController pushViewController:helpViewCtrl animated:YES];
    [helpViewCtrl release];
}
- (IBAction)config_pressed:(id)sender {
    //[[self navigationController] setNavigationBarHidden:NO];
    configViewController *configViewCtrl = [[configViewController alloc] initWithNibName:@"configViewController" bundle:nil];
    [configViewCtrl setModalPresentationStyle:UIModalPresentationFormSheet];
    [configViewCtrl setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    configViewCtrl->appDelegate = appDelegate;
    configViewCtrl->switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([appDelegate switchNameArray], [appDelegate active_switch_index])];

    [self presentModalViewController:configViewCtrl animated:YES];
    [configViewCtrl release];
}

- (void) switch_names_updated:(NSNotification *) notification {
    [self performSelectorOnMainThread:@selector(reload_switch_name_table) withObject:nil waitUntilDone:NO];
}
- (void) reload_switch_name_table {
    [[appDelegate switchDataLock] lock];
    [switchNameTableView reloadData];
    if(CFDictionaryGetCount([appDelegate switchNameDictionary])) {
        [SwitchStatusText setText:@"Choose A Switch"];
        [SwitchStatusActivity stopAnimating];
    } else {
        [SwitchStatusText setText:@"Searching For Controllers"];
        [SwitchStatusActivity startAnimating];
    }
    
    [[appDelegate switchDataLock] unlock];
}

// Code to support table displaying the names of the switches discovered during detect
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return CFDictionaryGetCount([appDelegate switchNameDictionary]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"] autorelease];
    }
    NSString *switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([appDelegate switchNameArray], indexPath.row)];
    cell.textLabel.text = switchName;
    if(indexPath.row == [appDelegate active_switch_index]) {
        cell.detailTextLabel.text = @"Connected";
        UIButton *configButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        configButton.frame = CGRectMake(0.0, 0.0, 60, 44);
        [configButton setTitle:[NSString stringWithCString:"Config" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
        [configButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [configButton addTarget:self action:@selector(config_pressed:) forControlEvents:UIControlEventTouchUpInside];
        [configButton setEnabled:YES];
        cell.accessoryView = configButton;
    }
    else {
        cell.detailTextLabel.text = @"";
        cell.accessoryView = nil;
    }
    return cell;
}

// Support for connecting to a switch when its name is selected from the table
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [appDelegate connect_to_switch:indexPath.row protocol:switch_control_protocol_normal retries:10 showMessagesOnError:YES];
    if([appDelegate switch_socket])
        [appDelegate sendSwitchState];

    [self reload_switch_name_table];
}

- (IBAction)bgColorSegControlIndexChanged:(id) sender {
    int segmentIndex = [[self bgColorSegControl] selectedSegmentIndex];
    if(segmentIndex == 0) {
        // Set switch panel background to black
        [appDelegate setBackgroundColor:[UIColor blackColor]];
    } else {
        // Set switch panel background to black
        [appDelegate setBackgroundColor:[UIColor whiteColor]];
    }
    [self ResetScrollPanel];
}

@end
