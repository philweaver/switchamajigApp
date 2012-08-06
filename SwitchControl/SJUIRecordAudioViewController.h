//
//  SJUIRecordAudioViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 8/1/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol SJUIRecordAudioViewControllerDelegate <NSObject> 
- (void) SJUIRecordAudioViewControllerReadyForDismissal:(id)viewController;
@end

@interface SJUIRecordAudioViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate> {
    
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    UIButton *recordButton;
    UIButton *playButton;
}


@property NSURL *audioURL;
@property id<SJUIRecordAudioViewControllerDelegate>delegate;
- (id) initWithURL:(NSURL *)url andDelegate:(id)theDelegate;
- (void) record:(id)sender;
- (void) play:(id)sender;
- (void) cancel:(id)sender;
- (void) done:(id)sender;
@end
