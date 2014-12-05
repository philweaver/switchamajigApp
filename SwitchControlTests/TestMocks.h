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

#import <Foundation/Foundation.h>
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigDriver.h"
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigControllerDeviceDriver.h"
#import "SwitchControlAppDelegate.h"
#import "mach/mach.h"

@interface MockNavigationController : UINavigationController {
@public
    UIViewController *lastViewController;
    BOOL didReceivePushViewController;
    BOOL didReceivePopViewController;
    BOOL didReceivePopToRootViewController;
}
@end

@interface MockSwitchControlDelegate : SwitchControlAppDelegate {
@public
    NSMutableArray *commandsReceived;
    NSString *lastIRBrand;
    NSString *lastIRCodeSet;
    NSString *lastIRDevice;
    NSString *lastIRDeviceGroup;
    NSString *irCodeSetToSend;
}
@end

@interface MockSwitchamajigInsteonDriver : SwitchamajigInsteonDeviceDriver {
@public
    NSMutableArray *commandsReceived;
}
@end

@interface MockSwitchamajigIRDriver : SwitchamajigIRDeviceDriver {
@public
    NSMutableArray *commandsReceived;
}
@end

@interface MockSwitchamajigControllerDriver : SwitchamajigControllerDeviceDriver {
@public
    NSMutableArray *commandsReceived;
}
@end

@interface HandyTestStuff : NSObject {
}
+ (id) findEditColorButtonInView:(UIView *)superview withColor:(UIColor *)color;
+ (id) findSubviewOf:(UIView *)view withText:(NSString *)text;
+ (vm_size_t) usedMemory;
+ (vm_size_t) freeMemory;
+ (void) logMemUsage;
@end
