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

#import <UIKit/UIKit.h>
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigDriver.h"

@class rootSwitchViewController;
#define PROTOCOL_SQ (IPPROTO_TCP + IPPROTO_UDP + 1)
#define ROVING_PORTNUM 2000
#define SQ_PORTNUM 80
@interface SwitchControlAppDelegate : NSObject <UIApplicationDelegate, SwitchamajigDeviceListenerDelegate, SwitchamajigIRDeviceDriverDelegate> {
    SwitchamajigControllerDeviceListener *sjigControllerListener;
    SwitchamajigIRDeviceListener *sjigIRListener;
    int friendlyNameDictionaryIndex;
    NSTimer *statusMessageTimer;
    int listenerDevicesToIgnore;
    NSLock *switchamajigIRLock;
    NSString *lastLearnedIRCommand;
    NSError *lastLearnedIRError;
@public
    BOOL panelWasEdited; // Flag for a switch panel being edited and needing re-rendering on root view controller
    SwitchamajigInsteonDeviceListener *sjigInsteonListener;
}
- (void)performActionSequence:(DDXMLNode *)actionSequenceOnDevice;
- (void) addStatusAlertMessage:(NSString *)message withColor:(UIColor*)color displayForSeconds:(float)seconds;
- (void) statusMessageCallback;
- (void) executeActionSequence:(NSArray *)threadInfoArray;
- (SwitchamajigControllerDeviceDriver *) firstSwitchamajigControllerDriver;
- (void)removeDriver:(SwitchamajigDriver *)driver;
- (NSString *) getLastLearnedIRCommand;
- (NSError *) getLastLearnedIRError;
- (void) clearLastLearnedIRInfo;
- (void) setIRBrand:(NSString *)brand andCodeSet:(NSString *)codeSet andDevice:(NSString *)device forDeviceGroup:(NSString *)deviceGroup;
- (NSString *) getIRBrandForDeviceGroup:(NSString *)deviceGroup;
- (NSString *) getIRCodeSetForDeviceGroup:(NSString *)deviceGroup;
- (NSString *) getIRDeviceForDeviceGroup:(NSString *)deviceGroup;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (strong, nonatomic) NSMutableDictionary *friendlyNameSwitchamajigDictionary;
@property (strong, nonatomic) NSMutableDictionary *actionnameActionthreadDictionary;
@property (strong, nonatomic) NSLock *statusInfoLock;
@property (strong, nonatomic) NSMutableArray *statusMessages;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *foregroundColor;
@end
