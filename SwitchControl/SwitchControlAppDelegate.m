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

#import "SwitchControlAppDelegate.h"
#import "rootSwitchViewController.h"
#import "Flurry.h"

// Silly widgit that probably means I should be signaling the action thread to stop in some better way
@interface SwitchamajigMutableBool : NSObject {
}
@property BOOL value;
@end
@implementation SwitchamajigMutableBool
@synthesize value;
@end


@implementation SwitchControlAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize friendlyNameSwitchamajigDictionary;
@synthesize actionnameActionthreadDictionary;
@synthesize statusMessages;
@synthesize statusInfoLock;
@synthesize backgroundColor = _backgroundColor;
@synthesize foregroundColor = _foregroundColor;

#define SETTINGS_UDP_PROTOCOL 0
#define SETTINGS_TCP_PROTOCOL 1

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    [Flurry logError:@"Uncaught" message:@"Crash!" exception:exception];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [Flurry startSession:@"YW295HVM32JWRQ6QFYDW"];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    // Initialize default settings values if needed
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self defaultsFromPlistNamed:@"Root"]];
    // Disable SIGPIPE
    struct sigaction sigpipeaction;
    memset(&sigpipeaction, 0, sizeof(sigpipeaction));
    sigpipeaction.sa_handler = SIG_IGN;
    sigaction(SIGPIPE, &sigpipeaction, NULL);
    // Initialize the list of switches and the lock that keeps it threadsafe
    [self setFriendlyNameSwitchamajigDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    [self setActionnameActionthreadDictionary:[[NSMutableDictionary alloc] initWithCapacity:20]];
    [self setStatusInfoLock:[[NSLock alloc] init]];
    
    // Initialize colors
    [self setBackgroundColor:[UIColor blackColor]];
    [self setForegroundColor:[UIColor whiteColor]];
    // Initialize the root view controller
    [self setNavigationController:[[UINavigationController alloc] initWithRootViewController:[[rootSwitchViewController alloc] initWithNibName:nil bundle:nil]]];
    [[self window] setRootViewController: [self navigationController]];
    [self.window makeKeyAndVisible];  
    // Listen for Switchamajigs
    sjigControllerListener = [[SwitchamajigControllerDeviceListener alloc] initWithDelegate:self];
    sjigIRListener = [[SwitchamajigIRDeviceListener alloc] initWithDelegate:self];
    sjigInsteonListener = [[SwitchamajigInsteonDeviceListener alloc] initWithDelegate:self];
    // Prepare to run status timer
    statusMessageTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(statusMessageCallback) userInfo:nil repeats:NO]; 
    friendlyNameDictionaryIndex = 0;
    [self setStatusMessages:[[NSMutableArray alloc] initWithCapacity:5]];
    listenerDevicesToIgnore = 0;
    // Add IR database
    NSString *irDatabasePath = [[NSBundle mainBundle] pathForResource:@"IRDB" ofType:@"sqlite"];
    NSError *error;
    [SwitchamajigIRDeviceDriver loadIRCodeDatabase:irDatabasePath error:&error];
    if(error) {
        NSLog(@"Error loading IR database: %@", error);
    }
    switchamajigIRLock = [[NSLock alloc] init];
    // Report key settings
    NSMutableDictionary *settingsDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigControllerPreference"])
        [settingsDictionary setObject:@"YES" forKey:@"supportSwitchamajigControllerPreference"];
    else
        [settingsDictionary setObject:@"NO" forKey:@"supportSwitchamajigControllerPreference"];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigIRPreference"])
        [settingsDictionary setObject:@"YES" forKey:@"supportSwitchamajigIRPreference"];
    else
        [settingsDictionary setObject:@"NO" forKey:@"supportSwitchamajigIRPreference"];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"allowEditingOfSwitchPanelsPreference"])
        [settingsDictionary setObject:@"YES" forKey:@"allowEditingOfSwitchPanelsPreference"];
    else
        [settingsDictionary setObject:@"NO" forKey:@"allowEditingOfSwitchPanelsPreference"];
    [Flurry logEvent:@"Launch" withParameters:settingsDictionary];
     return YES;
}

- (void) statusMessageCallback {
    // If there are any alerts, display them
    float secondsUntilNextCall = 365.0*24.0*60.0*60.0; // If nothing to update, fire once a year, if we need it or not...
    [[self statusInfoLock] lock];
    if([[self statusMessages] count]) {
        NSArray *messageArray = [[self statusMessages] objectAtIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetText" object:[messageArray objectAtIndex:0]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetColor" object:[messageArray objectAtIndex:2]];
        secondsUntilNextCall = [[messageArray objectAtIndex:1] floatValue];
        [[self statusMessages] removeObjectAtIndex:0];
    } 
    else if ([[self friendlyNameSwitchamajigDictionary] count] == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetText" object:@"No Switchamajigs Found"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetColor" object:[UIColor redColor]];
    } else {
        // Cycle through all connected switches
        NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeys];
        if(++friendlyNameDictionaryIndex >= [friendlyNames count])
            friendlyNameDictionaryIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetText" object:[NSString stringWithFormat:@"Connected to %@",[friendlyNames objectAtIndex:friendlyNameDictionaryIndex]]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetColor" object:[UIColor whiteColor]];
        secondsUntilNextCall = 3.0;
    }
    [[self statusInfoLock] unlock];
    statusMessageTimer = [NSTimer scheduledTimerWithTimeInterval:secondsUntilNextCall target:self selector:@selector(statusMessageCallback) userInfo:nil repeats:NO]; 
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
}

- (void)performActionSequence:(DDXMLNode *)actionSequenceOnDevice {
    // Get the friendly name for this sequence
    NSError *xmlError;
    NSArray *friendlyNames = [actionSequenceOnDevice nodesForXPath:@".//friendlyname" error:&xmlError];
    if([friendlyNames count] < 1) {
        NSLog(@"Can't find friendly name. Count = %d. Node string = %@", [friendlyNames count], [actionSequenceOnDevice XMLString]);
        return;
    }
    DDXMLNode *friendlyNameNode = [friendlyNames objectAtIndex:0];
    NSString *friendlyName = [friendlyNameNode stringValue];
    if(friendlyName == nil) {
        NSLog(@"performActionSequence: friendlyname is nil. Node string = %@", [actionSequenceOnDevice XMLString]);
        return;
    }
    // Look up the driver for friendly name
    SwitchamajigDriver *driver;
    if([friendlyName isEqualToString:@"Default"]) {
        // If the command is to go back, handle it here
        NSArray *backNodes = [actionSequenceOnDevice nodesForXPath:@".//back" error:&xmlError];
        if([backNodes count]) {
            [[self navigationController] popToRootViewControllerAnimated:YES];
        }
        BOOL isIRCommand = NO;
        // Check if the command is for the IR
        NSArray *irCommandNodes = [actionSequenceOnDevice nodesForXPath:@".//docommand" error:&xmlError];
        if([irCommandNodes count])
            isIRCommand = YES;
        irCommandNodes = [actionSequenceOnDevice nodesForXPath:@".//quickIrCommand" error:&xmlError];
        if([irCommandNodes count])
            isIRCommand = YES;
        if(isIRCommand) {
            driver = [self firstSwitchamajigIRDriver];
        } else {
            driver = [self firstSwitchamajigControllerDriver];
        }
    } else {
        [statusInfoLock lock];
        driver = [[self friendlyNameSwitchamajigDictionary] objectForKey:friendlyName];
        [statusInfoLock unlock];
    }
    NSArray *actionSequences = [actionSequenceOnDevice nodesForXPath:@".//actionsequence" error:&xmlError];
    if([actionSequences count] < 1){
        NSLog(@"performActionSequence: no action sequences for string %@", [actionSequenceOnDevice XMLString]);
        return;
    }
    DDXMLNode *actionSequence = [actionSequences objectAtIndex:0];

    NSArray *actionNames = [actionSequenceOnDevice nodesForXPath:@".//actionname" error:&xmlError];
    NSString *actionName;
    if([actionNames count]) {
        DDXMLNode *actionNameNode = [actionNames objectAtIndex:0];
        actionName = [actionNameNode stringValue];
    } else
        actionName = friendlyName;
    // Stop any existing thread with this name
    SwitchamajigMutableBool *killCurrentThread = [actionnameActionthreadDictionary valueForKey:actionName];
    if(killCurrentThread != nil) {
        [killCurrentThread setValue:YES];
    }
    // Create an array to pass to the background thread with the synchronization object
    SwitchamajigMutableBool *threadExitBool = [SwitchamajigMutableBool alloc];
    [threadExitBool setValue:NO];
    // Add a dictionary entry for this thread
    [actionnameActionthreadDictionary setValue:threadExitBool forKey:actionName];
    NSArray *threadInfoArray = [NSArray arrayWithObjects:actionSequence, threadExitBool, driver, nil];
    // Start a thread to perform the action
    [self performSelectorInBackground:@selector(executeActionSequence:) withObject:threadInfoArray];
}


- (void) executeActionSequence:(NSArray *)threadInfoArray {
    @autoreleasepool {
        // Unpack the thread info
        DDXMLNode *actionSequence = [threadInfoArray objectAtIndex:0];
        SwitchamajigMutableBool *threadExitBool = [threadInfoArray objectAtIndex:1];
        SwitchamajigDriver *driver = nil;
        // Allow for the driver to be nil since actions that just stop a thread don't
        // really need to have a driver associated with them.
        if([threadInfoArray count] == 3)
            driver = [threadInfoArray objectAtIndex:2];
        if((actionSequence == nil) || (threadExitBool == nil)) {
            NSLog(@"executeActionSequence: values are nil. Aborting action.");
            return;
        }
        NSArray *actions = [actionSequence children];
        DDXMLNode *action;
        for(action in actions) {
            // Exit if requested to do so
            if([threadExitBool value])
                break;
            if([[action name] isEqualToString:@"loop"]) {
                // Recursively call this function to perform the actions in the loop
                NSArray *loopInfoArray = [NSArray arrayWithObjects:action, threadExitBool, driver, nil];
                while(![threadExitBool value]) {
                    [self executeActionSequence:loopInfoArray];
                }
                continue;
            }
            if([[action name] isEqualToString:@"delay"]) {
                NSScanner *delayScan = [[NSScanner alloc] initWithString:[action stringValue]];
                double delay;
                bool delay_ok = [delayScan scanDouble:&delay];
                if(!delay_ok) {
                    NSLog(@"Problem reading delay amount");
                    continue;
                }
                [NSThread sleepForTimeInterval:delay];
                continue;
            }
            if([[action name] isEqualToString:@"stopactionwithname"]) {
                // Stop any existing thread with this name
                SwitchamajigMutableBool *killCurrentThread = [actionnameActionthreadDictionary valueForKey:[action stringValue]];
                if(killCurrentThread != nil) {
                    [killCurrentThread setValue:YES];
                }
                continue;
            }
            if([[action name] isEqualToString:@"quickIrCommand"]) {
                // Get device types and possible commands
                NSError *xmlError;
                NSArray *deviceTypeNodes = [action nodesForXPath:@".//deviceType" error:&xmlError];
                NSArray *functionNodes = [action nodesForXPath:@".//function" error:&xmlError];
                DDXMLNode *deviceTypeNode;
                // Try to find a device in the defaults where we can execute the command
                for(deviceTypeNode in deviceTypeNodes) {
                    NSString *deviceType = [deviceTypeNode stringValue];
                    NSString *brand = [self getIRBrandForDeviceGroup:deviceType];
                    NSString *codeSet = [self getIRCodeSetForDeviceGroup:deviceType];
                    NSString *device = [self getIRDeviceForDeviceGroup:deviceType];
                    if(brand && codeSet) {
                        DDXMLNode *functionNode;
                        for(functionNode in functionNodes) {
                            NSString *function = [functionNode stringValue];
                            NSString *irCommand = [SwitchamajigIRDeviceDriver irCodeForFunction:function inCodeSet:codeSet onDevice:device forBrand:brand];
                            NSLog(@"%@:%@:%@:%@  --  irCommand = %@", brand, device, codeSet, function, irCommand);
                            if(irCommand) {
                                // Wrap the command up as xml
                                NSString *irXmlCommand = [NSString stringWithFormat:@"<docommand key=\"0\" repeat=\"1\" seq=\"0\" command=\"0\" ir_data=\"%@\" ch=\"0\"></docommand>", irCommand];
                                DDXMLDocument *actionDoc = [[DDXMLDocument alloc] initWithXMLString:irXmlCommand options:0 error:&xmlError];
                                if(action == nil) {
                                    NSLog(@"Failed to create action XML. Error = %@. String = %@.\n", xmlError, irXmlCommand);
                                    return;
                                }
                                action = [[actionDoc children] objectAtIndex:0];
                                goto foundAction;
                            }
                        }
                    }
                }
                // Didn't find an action
                NSLog(@"executeActionSequence: Failed to find action set for command %@", [action XMLString]);
                return;
            }
        foundAction:
            // Send command to driver
            NSLog(@"Issuing command %@", [action XMLString]);
            if(driver == nil) {
                NSLog(@"executeActionSequence: driver is nil. Skipping action");
            } else {
                NSError *error;
                [driver issueCommandFromXMLNode:action error:&error];
            }
        }
    }
}

- (void) addStatusAlertMessage:(NSString *)message withColor:(UIColor*)color displayForSeconds:(float)seconds {
    NSArray *messageArray = [NSArray arrayWithObjects:message, [NSNumber numberWithFloat:seconds], color, nil];
    [[self statusInfoLock] lock];
    [[self statusMessages] addObject:messageArray];
    [[self statusInfoLock] unlock];
    if([statusMessageTimer isValid])
        [statusMessageTimer fire];
}

// SwitchamajigDeviceDriverDelegate
- (void) SwitchamajigDeviceDriverConnected:(id)deviceDriver {
}

- (void) SwitchamajigDeviceDriverDisconnected:(id)deviceDriver withError:(NSError*)error {
    // Show status message
    [statusInfoLock lock];
    NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeysForObject:deviceDriver];
    [statusInfoLock unlock];
    if([friendlyNames count] != 1) {
        // Hopefully this won't happen. Each driver should have exactly one name
        NSLog(@"SwitchamajigDeviceDriverConnected: %d names for driver on disconnect.", [friendlyNames count]);
    }
    NSString *friendlyName;
    for (friendlyName in friendlyNames) {
        [self addStatusAlertMessage:[NSString stringWithFormat:@"Disconnected from %@",friendlyName]  withColor:[UIColor redColor] displayForSeconds:5.0];
    }
    [statusInfoLock lock];
    [[self friendlyNameSwitchamajigDictionary] removeObjectsForKeys:friendlyNames];
    [statusInfoLock unlock];
}

// IR Delegate
-(void) SwitchamajigIRDeviceDriverDelegateDidReceiveLearnedIRCommand:(id)deviceDriver irCommand:(NSString *)irCommand {
    [switchamajigIRLock lock];
    lastLearnedIRCommand = irCommand;
    [switchamajigIRLock unlock];
}
-(void) SwitchamajigIRDeviceDriverDelegateErrorOnLearnIR:(id)deviceDriver error:(NSError *)error {
    [switchamajigIRLock lock];
    lastLearnedIRError = error;
    [switchamajigIRLock unlock];    
}

// Access to IR learning stuff
- (NSString *) getLastLearnedIRCommand {
    [switchamajigIRLock lock];
    NSString * retVal = lastLearnedIRCommand;
    [switchamajigIRLock unlock];
    return retVal;
}
- (NSError *) getLastLearnedIRError {
    [switchamajigIRLock lock];
    NSError * retVal = lastLearnedIRError;
    [switchamajigIRLock unlock];
    return retVal;
}
- (void) clearLastLearnedIRInfo {
    [switchamajigIRLock lock];
    lastLearnedIRError = nil;
    lastLearnedIRCommand = nil;
    [switchamajigIRLock unlock];
}


- (SwitchamajigControllerDeviceDriver *) firstSwitchamajigControllerDriver {
    SwitchamajigControllerDeviceDriver *firstDriver = nil;
    [statusInfoLock lock];
    NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeys];
    NSString *name;
    for(name in friendlyNames) {
        SwitchamajigDriver *driver = [[self friendlyNameSwitchamajigDictionary] objectForKey:name];
        if([driver isKindOfClass:[SwitchamajigControllerDeviceDriver class]]) {
            firstDriver = (SwitchamajigControllerDeviceDriver *)driver;
            break;
        }
    }
    [statusInfoLock unlock];
    return firstDriver;
}

- (SwitchamajigIRDeviceDriver *) firstSwitchamajigIRDriver {
    SwitchamajigIRDeviceDriver *firstDriver = nil;
    [statusInfoLock lock];
    NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeys];
    NSString *name;
    for(name in friendlyNames) {
        SwitchamajigDriver *driver = [[self friendlyNameSwitchamajigDictionary] objectForKey:name];
        if([driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]) {
            firstDriver = (SwitchamajigIRDeviceDriver *)driver;
            break;
        }
    }
    [statusInfoLock unlock];
    return firstDriver;
}

- (void)removeDriver:(SwitchamajigDriver *)driver {
    [statusInfoLock lock];
    NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeysForObject:driver];
    [[self friendlyNameSwitchamajigDictionary] removeObjectsForKeys:friendlyNames];
    [statusInfoLock unlock];
    listenerDevicesToIgnore = 1; // Total hack to avoid race condition
}

// SwitchamajigDeviceListenerDelegate
- (void) SwitchamajigDeviceListenerFoundDevice:(id)listener hostname:(NSString*)hostname friendlyname:(NSString*)friendlyname {
    if(listenerDevicesToIgnore) {
        --listenerDevicesToIgnore;
        return;
    }
    [statusInfoLock lock];
    SwitchamajigDriver *driver = [[self friendlyNameSwitchamajigDictionary] objectForKey:friendlyname];
    // Don't constantly reinitialize drivers
    if(driver != nil) {
        [statusInfoLock unlock];
        return;
    }
    if([listener isKindOfClass:[SwitchamajigControllerDeviceListener class]]) {
        SwitchamajigControllerDeviceDriver *sjcdriver = [SwitchamajigControllerDeviceDriver alloc];
        [sjcdriver setUseUDP:[[NSUserDefaults standardUserDefaults] boolForKey:@"useUDPWithSwitchamajigControllerPreference"]];
        [Flurry logEvent:@"Found Switchamajig Controller"];
        driver = sjcdriver;
    }
    else if([listener isKindOfClass:[SwitchamajigIRDeviceListener class]]) {
        SwitchamajigIRDeviceDriver *sjirdriver = [SwitchamajigIRDeviceDriver alloc];
        [Flurry logEvent:@"Found Switchamajig IR"];
        driver = sjirdriver;
    } else if ([listener isKindOfClass:[SwitchamajigInsteonDeviceListener class]]) {
        SwitchamajigInsteonDeviceDriver *insteonDriver = [SwitchamajigInsteonDeviceDriver alloc];
        driver = insteonDriver;
    }else {
        // Unrecognized
        NSLog(@"SwitchamajigDeviceListenerFoundDevice: Unrecognized listener");
        [statusInfoLock unlock];
        return;
    }
    driver = [driver initWithHostname:hostname];
    [driver setDelegate:self];
    [[self friendlyNameSwitchamajigDictionary] setObject:driver forKey:friendlyname];
    [statusInfoLock unlock];
    // Show status message
    NSString *statusString = [NSString stringWithFormat:@"Connected to %@",friendlyname];
    NSLog(@"%@", statusString);
    [self addStatusAlertMessage:statusString withColor:[UIColor whiteColor] displayForSeconds:5.0];
    
}
- (void) SwitchamajigDeviceListenerHandleError:(id)listener theError:(NSError*)error {
    NSLog(@"SwitchamajigDeviceListenerHandleError: %@", error); 
}
- (void) SwitchamajigDeviceListenerHandleBatteryWarning:(id)listener hostname:(NSString*)hostname friendlyname:(NSString*)friendlyname {
    [self addStatusAlertMessage:[NSString stringWithFormat:@"%@ needs its batteries replaced",friendlyname]  withColor:[UIColor redColor] displayForSeconds:5.0];
}

- (void) setIRBrand:(NSString *)brand andCodeSet:(NSString *)codeSet andDevice:(NSString *)device forDeviceGroup:(NSString *)deviceGroup {
    NSDictionary *irBrandDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"irDeviceGroupToBrandDictionary"];
    if(!irBrandDictionary)
        irBrandDictionary = [NSDictionary dictionary];
    NSMutableDictionary *newIRBrandDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    [newIRBrandDictionary addEntriesFromDictionary:irBrandDictionary];
    [newIRBrandDictionary setObject:brand forKey:deviceGroup];

    NSDictionary *irCodeSetDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"irDeviceGroupToCodeSetDictionary"];
    if(!irCodeSetDictionary)
        irCodeSetDictionary = [NSDictionary dictionary];
    NSMutableDictionary *newCodeSetBrandDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    [newCodeSetBrandDictionary addEntriesFromDictionary:irCodeSetDictionary];
    [newCodeSetBrandDictionary setObject:codeSet forKey:deviceGroup];

    NSDictionary *irDeviceDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"irDeviceGroupToDeviceDictionary"];
    if(!irDeviceDictionary)
        irDeviceDictionary = [NSDictionary dictionary];
    NSMutableDictionary *newIRDeviceDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    [newIRDeviceDictionary addEntriesFromDictionary:irDeviceDictionary];
    [newIRDeviceDictionary setObject:device forKey:deviceGroup];

    [[NSUserDefaults standardUserDefaults] setObject:newIRBrandDictionary forKey:@"irDeviceGroupToBrandDictionary"];
    [[NSUserDefaults standardUserDefaults] setObject:newCodeSetBrandDictionary forKey:@"irDeviceGroupToCodeSetDictionary"];
    [[NSUserDefaults standardUserDefaults] setObject:newIRDeviceDictionary forKey:@"irDeviceGroupToDeviceDictionary"];
}
- (NSString *) getIRBrandForDeviceGroup:(NSString *)deviceGroup {
    NSDictionary *irBrandDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"irDeviceGroupToBrandDictionary"];
    if(!irBrandDictionary)
        return nil;
    return [irBrandDictionary objectForKey:deviceGroup];
}

- (NSString *) getIRCodeSetForDeviceGroup:(NSString *)deviceGroup{
    NSDictionary *irCodeSetDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"irDeviceGroupToCodeSetDictionary"];
    if(!irCodeSetDictionary)
        return nil;
    return [irCodeSetDictionary objectForKey:deviceGroup];
}

- (NSString *) getIRDeviceForDeviceGroup:(NSString *)deviceGroup{
    NSDictionary *irDeviceDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"irDeviceGroupToDeviceDictionary"];
    if(!irDeviceDictionary)
        return nil;
    return [irDeviceDictionary objectForKey:deviceGroup];
}



// Handle settings initialization
- (NSDictionary *)defaultsFromPlistNamed:(NSString *)plistName {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    NSAssert(settingsBundle, @"Could not find Settings.bundle while loading defaults.");
    
    NSString *plistFullName = [NSString stringWithFormat:@"%@.plist", plistName];
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:plistFullName]];
    NSAssert1(settings, @"Could not load plist '%@' while loading defaults.", plistFullName);
    
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSAssert1(preferences, @"Could not find preferences entry in plist '%@' while loading defaults.", plistFullName);
    
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        id value = [prefSpecification objectForKey:@"DefaultValue"];
        if(key && value) {
            [defaults setObject:value forKey:key];
        } 
        
        NSString *type = [prefSpecification objectForKey:@"Type"];
        if ([type isEqualToString:@"PSChildPaneSpecifier"]) {
            NSString *file = [prefSpecification objectForKey:@"File"];
            NSAssert1(file, @"Unable to get child plist name from plist '%@'", plistFullName);
            [defaults addEntriesFromDictionary:[self defaultsFromPlistNamed:file]];
        }        
    }
    
    return defaults;
}

@end
