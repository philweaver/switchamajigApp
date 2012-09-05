//
//  chooseIconViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "chooseIconViewController.h"

@interface chooseIconViewController ()

@end

@implementation chooseIconViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self setContentSizeForViewInPopover:CGSizeMake(320, 250)];
        iconImageNames = [NSArray arrayWithObjects:@"onoff.png", @"CH_UpArrow.png", @"CH_DownArrow.png", @"VOL_UpArrow.png", @"VOL_DownArrow.png", @"play.png", @"stop.png", @"pause.png", @"fastforward.png", @"fastbackward.png", @"skipforward.png", @"skipbackward.png", @"eject.png", @"slowplay.png", @"reverse", @"uparrow", @"downarrow", nil];
    }
    return self;
}

-(void) loadView {
    CGSize viewSize = [self contentSizeForViewInPopover];
    CGRect cgRct = CGRectMake(0, 0, viewSize.width, viewSize.height);
    UIView *myView = [[UIView alloc] initWithFrame:cgRct];
    [self setView:myView];
    [myView setBackgroundColor:[UIColor blackColor]];

    iconPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(85, 50, 150, 162)];
    [iconPicker setDelegate:self];
    [iconPicker setDataSource:self];
    [iconPicker setShowsSelectionIndicator:YES];
    int indexOfName = [iconImageNames indexOfObject:[self iconName]];
    if(indexOfName != NSNotFound)
        [iconPicker selectRow:(indexOfName+1) inComponent:0 animated:NO];
    else
        [iconPicker selectRow:0 inComponent:0 animated:NO];
    [myView addSubview:iconPicker];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if(pickerView == iconPicker)
        return 1;
    NSLog(@"chooseIconViewController: numberOfComponentsInPickerView: PickerView unrecognized.");
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView == iconPicker) {
        return [iconImageNames count] + 1;
    }
    NSLog(@"chooseIconViewController: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == iconPicker) {
        if(row == 0)
            [self setIconName:nil];
        else
            [self setIconName:[iconImageNames objectAtIndex:(row-1)]];
        return;
    }
    NSLog(@"chooseIconViewController: pickerView didSelectRow: PickerView unrecognized.");
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    if(pickerView == iconPicker) {
        if(row == 0)
            return nil; // No image by default
        UIImageView *newview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        [newview setImage:[UIImage imageNamed:[iconImageNames objectAtIndex:(row-1)]]];
        return newview;
    }
    NSLog(@"chooseIconViewController: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    if(pickerView == iconPicker) {
        if(component == 0)
            return 70;
    }
    NSLog(@"chooseIconViewController: pickerView rowHeightForComponent: PickerView unrecognized.");
    return 0;    
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if(pickerView == iconPicker) {
        if(component == 0)
            return 100;
    }
    NSLog(@"chooseIconViewController: pickerView widthForComponent: PickerView unrecognized.");
    return 0;
}

@end
