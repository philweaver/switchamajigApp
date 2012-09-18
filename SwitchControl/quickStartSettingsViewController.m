//
//  quickStartSettingsViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/14/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "quickStartSettingsViewController.h"
#import "quickIRConfigViewController.h"
@interface quickStartSettingsViewController ()

@end

@implementation quickStartSettingsViewController
@synthesize supportSwitchamajigControllerSwitch;
@synthesize supportSwitchamajigIRSwitch;
@synthesize allowEditingSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self supportSwitchamajigControllerSwitch] setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigControllerPreference"] animated:NO];
    BOOL supportSwitchamajigIRPreference = [[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigIRPreference"];
    //NSLog(@"supportSwitchamajigIRPreference = %d", supportSwitchamajigIRPreference);
    [[self supportSwitchamajigIRSwitch] setOn:supportSwitchamajigIRPreference animated:NO];
    [[self allowEditingSwitch] setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"allowEditingOfSwitchPanelsPreference"] animated:NO];
}

- (void)viewDidUnload
{
    [self setSupportSwitchamajigControllerSwitch:nil];
    [self setSupportSwitchamajigIRSwitch:nil];
    [self setAllowEditingSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)didChangeSupportSwitchamajigController:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[[self supportSwitchamajigControllerSwitch] isOn] forKey:@"supportSwitchamajigControllerPreference"];
}

- (IBAction)didChangeSupportSwitchamajigIR:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[[self supportSwitchamajigIRSwitch] isOn] forKey:@"supportSwitchamajigIRPreference"];
}

- (IBAction)didChangeAllowEditing:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[[self allowEditingSwitch] isOn] forKey:@"allowEditingOfSwitchPanelsPreference"];
}

- (IBAction)didSelectQuickConfigIR:(id)sender {
    quickIRConfigViewController *qirViewCtrl = [quickIRConfigViewController alloc];
    [qirViewCtrl setAppDelegate:[self appDelegate]];
    [qirViewCtrl setUrlForControlPanel:[[NSBundle mainBundle] URLForResource:@"qs_tv" withExtension:@"xml"]];
    [qirViewCtrl setDeviceType:@"TV"];
    UINavigationController *navController = [self navigationController];
    [navController popViewControllerAnimated:NO];
    [navController pushViewController:qirViewCtrl animated:YES];
}
@end
