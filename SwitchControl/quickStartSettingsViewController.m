/*
Copyright 2014 PAW Solutions LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

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
    return NO;
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
    [qirViewCtrl setDeviceGroup:@"TV"];
    UINavigationController *navController = [self navigationController];
    [navController pushViewController:qirViewCtrl animated:YES];
}

- (IBAction)didSelectQuickConfigDVD:(id)sender {
    quickIRConfigViewController *qirViewCtrl = [quickIRConfigViewController alloc];
    [qirViewCtrl setAppDelegate:[self appDelegate]];
    [qirViewCtrl setUrlForControlPanel:[[NSBundle mainBundle] URLForResource:@"qs_dvd" withExtension:@"xml"]];
    [qirViewCtrl setDeviceGroup:@"DVD/Blu Ray"];
    UINavigationController *navController = [self navigationController];
    [navController pushViewController:qirViewCtrl animated:YES];
}

- (IBAction)didSelectQuickConfigCable:(id)sender {
    quickIRConfigViewController *qirViewCtrl = [quickIRConfigViewController alloc];
    [qirViewCtrl setAppDelegate:[self appDelegate]];
    [qirViewCtrl setUrlForControlPanel:[[NSBundle mainBundle] URLForResource:@"qs_cable" withExtension:@"xml"]];
    [qirViewCtrl setDeviceGroup:@"Cable/Satellite"];
    UINavigationController *navController = [self navigationController];
    [navController pushViewController:qirViewCtrl animated:YES];
}
@end
