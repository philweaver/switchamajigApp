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

#import "quickIRConfigViewController.h"
#import "switchPanelViewController.h"
#import "Flurry.h"
@interface quickIRConfigViewController ()

@end


@implementation quickIRConfigViewController
@synthesize codeSetPickerView;
@synthesize brandPickerView;
@synthesize deviceGroup;
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

- (void) setupBrandsForFiltering:(BOOL)filter {
    brands = [NSMutableArray arrayWithCapacity:50];
    NSArray *devices = [[self deviceGroup] componentsSeparatedByString:@"/"];
    NSString *device;
    for (device in devices) {
        NSArray *brandsFromDatabase = [SwitchamajigIRDeviceDriver getIRDatabaseBrandsForDevice:device];
        if(filter)
            brandsFromDatabase = filterBrands(brandsFromDatabase);
        NSString *brand;
        for(brand in brandsFromDatabase) {
            NSString *brandWithDeviceName = [NSString stringWithFormat:@"%@:%@", brand, device];
            [brands addObject:brandWithDeviceName];
        }
    }
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
    [[switchPanelVC view] setFrame:CGRectMake(625, 75, 375, 650)];
    [[self view] addSubview:[switchPanelVC view]];
    [switchPanelVC didMoveToParentViewController:self];
    [self setupBrandsForFiltering:YES];
    // Initialize the picker wheels
    NSString *currentBrand = [[self appDelegate] getIRBrandForDeviceGroup:[self deviceGroup]];
    NSString *currentDevice = [[self appDelegate] getIRDeviceForDeviceGroup:[self deviceGroup]];
    NSString *currentBrandWithDevice = [NSString stringWithFormat:@"%@:%@", currentBrand, currentDevice];
    int brandIndex = [brands indexOfObject:currentBrandWithDevice];
    if((brandIndex == NSNotFound) && ([[[self filterBrandButton] titleForState:UIControlStateNormal] isEqualToString:@"Show More Brands"])) {
        // Un-filter the brands
        [[self filterBrandButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
        brandIndex = [brands indexOfObject:currentBrandWithDevice];
        if(brandIndex == NSNotFound) {
            [[self filterBrandButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
            brandIndex = 0;
        }
    }
    [[self brandPickerView] selectRow:brandIndex inComponent:0 animated:NO];
    [self pickerView:[self brandPickerView] didSelectRow:brandIndex inComponent:0];
    NSString *codeSet = [[self appDelegate] getIRCodeSetForDeviceGroup:[self deviceGroup]];
    int codeSetIndex = [codeSets indexOfObject:codeSet];
    if(codeSetIndex == NSNotFound)
        codeSetIndex = 0;
    [[self codeSetPickerView] selectRow:codeSetIndex inComponent:0 animated:NO];
    [self pickerView:[self codeSetPickerView] didSelectRow:codeSetIndex inComponent:0];
    [Flurry logEvent:@"QuickStartIR" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"deviceGroup", [self deviceGroup], nil]];
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
    return NO;
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
    NSString *currentPickerTitle = [self pickerView:[self brandPickerView] titleForRow:[[self brandPickerView] selectedRowInComponent:0] forComponent:0];
    NSArray *brandAndDevice = [currentPickerTitle componentsSeparatedByString:@":"];
    if([brandAndDevice count] != 2) {
        NSLog(@"quickIRConfigViewController - didSelectRow: brand and device invalid");
        return;
    }
    NSString *brand = [brandAndDevice objectAtIndex:0];
    NSString *device = [brandAndDevice objectAtIndex:1];
    if(pickerView == [self brandPickerView]) {
        codeSets = [SwitchamajigIRDeviceDriver getIRDatabaseCodeSetsOnDevice:device forBrand:brand];
        [[self codeSetPickerView] reloadAllComponents];
        [[self codeSetPickerView] selectRow:0 inComponent:0 animated:NO];
        [self pickerView:[self codeSetPickerView] didSelectRow:0 inComponent:0];
        return;
    }
    if(pickerView == [self codeSetPickerView]) {
        [[self appDelegate] setIRBrand:brand andCodeSet:[codeSets objectAtIndex:row] andDevice:device forDeviceGroup:[self deviceGroup]];
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
        [self setupBrandsForFiltering:NO];
    } else {
        [[self filterBrandButton] setTitle:@"Show More Brands" forState:UIControlStateNormal];
        [self setupBrandsForFiltering:YES];
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
