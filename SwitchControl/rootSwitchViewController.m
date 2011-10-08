//
//  rootSwitchViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "rootSwitchViewController.h"
#import "switchPanelViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation rootSwitchViewController
@synthesize panelSelectionScrollView;
@synthesize switchNameTableView;

- (void)dealloc {
    [switchNameTableView release];
    switchNameTableView = nil;
    [switchNameTableView release];
    [panelSelectionScrollView release];
    CFRelease(switchPanelURLDictionary);
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
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    switchPanelURLDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    // Make nav bar disappear
    [[self navigationController] setNavigationBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switch_names_updated:) name:@"switch_list_was_updated" object:nil];
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

- (IBAction)detect:(id)sender {
    return;
}

- (void) switch_names_updated:(NSNotification *) notification {
    [self performSelectorOnMainThread:@selector(reload_switch_name_table) withObject:nil waitUntilDone:NO];
}
- (void) reload_switch_name_table {
    [[appDelegate switchDataLock] lock];
    [switchNameTableView reloadData];
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
    }
    NSString *switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([appDelegate switchNameArray], indexPath.row)];
    cell.textLabel.text = switchName;
    if(indexPath.row == [appDelegate active_switch_index])
        cell.detailTextLabel.text = @"Connected";
    else
        cell.detailTextLabel.text = @"";
    return cell;
}

// Support for connecting to a switch when its name is selected from the table
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [appDelegate connect_to_switch:indexPath.row retries:10 showMessagesOnError:YES];
    [self reload_switch_name_table];
}
@end
