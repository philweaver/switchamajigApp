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
@synthesize deviceType;
@synthesize urlForControlPanel;
@synthesize filterBrandButton;

// Local prototype
static NSArray *filterBrands(NSArray *bigListOfBrands);

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
    [switchPanelVC setUrlToLoad:[self urlForControlPanel]];
    [switchPanelVC hideUserButtons];
    [[switchPanelVC view] setFrame:CGRectMake(650, 75, 300, 650)];
    [[self view] addSubview:[switchPanelVC view]];
    [switchPanelVC didMoveToParentViewController:self];
    brands = filterBrands([SwitchamajigIRDeviceDriver getIRDatabaseBrandsForDevice:[self deviceType]]);
    // Initialize the picker wheels
    NSString *currentBrand = [[self appDelegate] getIRBrandForDevice:[self deviceType]];
    int brandIndex = [brands indexOfObject:currentBrand];
    if((brandIndex == NSNotFound) && ([[[self filterBrandButton] titleForState:UIControlStateNormal] isEqualToString:@"Show More Brands"])) {
        // Un-filter the brands
        [[self filterBrandButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
        brandIndex = [brands indexOfObject:currentBrand];
    }
    if(brandIndex != NSNotFound) {
        [[self brandPickerView] selectRow:brandIndex inComponent:0 animated:NO];
        [self pickerView:[self brandPickerView] didSelectRow:brandIndex inComponent:0];
        NSString *codeSet = [[self appDelegate] getIRCodeSetForDevice:[self deviceType]];
        int codeSetIndex = [codeSets indexOfObject:codeSet];
        if(codeSetIndex != NSNotFound) {
            [[self codeSetPickerView] selectRow:codeSetIndex inComponent:0 animated:NO];
            [self pickerView:[self codeSetPickerView] didSelectRow:codeSetIndex inComponent:0];
        }
    }
}

- (void)viewDidUnload
{
    [self setCodeSetPickerView:nil];
    [self setBrandPickerView:nil];
    [self setFilterBrandButton:nil];
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
    if(pickerView == [self brandPickerView]) {
        return [brands count];
    }
    if(pickerView == [self codeSetPickerView]) {
        return [codeSets count];
    }
    NSLog(@"quickIRConfigViewController: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == [self brandPickerView]) {
        codeSets = [SwitchamajigIRDeviceDriver getIRDatabaseCodeSetsOnDevice:[self deviceType] forBrand:[self pickerView:[self brandPickerView] titleForRow:row forComponent:0]];
        [[self codeSetPickerView] reloadAllComponents];
        [[self codeSetPickerView] selectRow:0 inComponent:0 animated:NO];
        [self pickerView:[self codeSetPickerView] didSelectRow:0 inComponent:0];
        return;
    }
    if(pickerView == [self codeSetPickerView]) {
        [[self appDelegate] setIRBrand:[self pickerView:[self brandPickerView] titleForRow:[[self brandPickerView] selectedRowInComponent:0] forComponent:0] andCodeSet:[codeSets objectAtIndex:row] forDevice:[self deviceType]];
        return;
    }
    NSLog(@"quickIRConfigViewController: pickerView didSelectRow: PickerView unrecognized.");
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == brandPickerView) {
        if([brands count]>row)
            return [brands objectAtIndex:row];
        NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow out of bounds for brands");
        return nil;
    }
    if(pickerView == codeSetPickerView) {
        if([codeSets count]>row) {
            //return [codeSets objectAtIndex:row];
            // The code set names are obscure and take up too much horizontal space
            return [NSString stringWithFormat:@"Code Set %d", row+1];
        }
        NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow out of bounds for codesets");
        return nil;
    }
    NSLog(@"quickIRConfigViewController: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 400;
}

- (IBAction)filterBrandToggle:(id)sender {
    NSString *currentBrand = [self pickerView:[self brandPickerView] titleForRow:[[self brandPickerView] selectedRowInComponent:0] forComponent:0];
    if([[[self filterBrandButton] titleForState:UIControlStateNormal] isEqualToString:@"Show More Brands"]) {
        [[self filterBrandButton] setTitle:@"Show Fewer Brands" forState:UIControlStateNormal];
        brands = [SwitchamajigIRDeviceDriver getIRDatabaseBrandsForDevice:[self deviceType]];
    } else {
        [[self filterBrandButton] setTitle:@"Show More Brands" forState:UIControlStateNormal];
        brands = filterBrands([SwitchamajigIRDeviceDriver getIRDatabaseBrandsForDevice:[self deviceType]]);
    }
    int brandIndex = [brands indexOfObject:currentBrand];
    [[self brandPickerView] reloadComponent:0];
    if(brandIndex == NSNotFound) {
        brandIndex = 0;
        [[self brandPickerView] selectRow:brandIndex inComponent:0 animated:NO];
        [self pickerView:[self brandPickerView] didSelectRow:brandIndex inComponent:0];
    } else {
        // No need to reload other components
        [[self brandPickerView] selectRow:brandIndex inComponent:0 animated:NO];
    }
}

static NSArray *filterBrands(NSArray *bigListOfBrands) {
    NSMutableArray *filteredBrands = [[NSMutableArray alloc] initWithCapacity:10];
    NSString *brand;
    for(brand in bigListOfBrands) {
        if([brand isEqualToString:@"Panasonic"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Sony"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Samsung"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Philips"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Tivo"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Time Warner"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Comcast"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Sharp"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Sanyo"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Scientific Atlanta"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Roku"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"RCA"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Motorola"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"DirecTV"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Dish"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Coby"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"LG"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Kenwood"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Pioneer"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Apple"]) [filteredBrands addObject:brand];
    }
    return filteredBrands;
}

@end
