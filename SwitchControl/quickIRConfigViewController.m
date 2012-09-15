//
//  quickIRConfigViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/14/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "quickIRConfigViewController.h"
#import "switchPanelViewController.h"
@interface quickIRConfigViewController ()

@end

@implementation quickIRConfigViewController
@synthesize codeSetPickerView;
@synthesize brandPickerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Show the switch panel for the TV
    switchPanelViewController *switchPanelVC = [[switchPanelViewController alloc] init];
    [self addChildViewController:switchPanelVC];
    [switchPanelVC setUrlToLoad:[[NSBundle mainBundle] URLForResource:@"qs_tv" withExtension:@"xml"]];
    [switchPanelVC hideUserButtons];
    [[switchPanelVC view] setFrame:CGRectMake(650, 75, 300, 650)];
    [[self view] addSubview:[switchPanelVC view]];
    [switchPanelVC didMoveToParentViewController:self];
}

- (void)viewDidUnload
{
    [self setCodeSetPickerView:nil];
    [self setBrandPickerView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 1;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == brandPickerView) {
        return;
    }
    if(pickerView == codeSetPickerView) {
        return;
    }
    NSLog(@"quickIRConfigViewController: pickerView didSelectRow: PickerView unrecognized.");
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == brandPickerView) {
        return nil;
    }
    if(pickerView == codeSetPickerView) {
        return nil;
    }
    NSLog(@"quickIRConfigViewController: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 400;
}

@end
