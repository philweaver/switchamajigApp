//
//  SJUIRecordAudioViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 8/1/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJUIRecordAudioViewController.h"
@interface SJUIRecordAudioViewController ()

@end

@implementation SJUIRecordAudioViewController
@synthesize audioURL;
@synthesize delegate;

- (id) initWithURL:(NSURL *)url andDelegate:(id)theDelegate {
    self = [super init];
    if(self != nil) {
        [self setAudioURL:url];
        NSError *sessionError;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        if(sessionError)
            NSLog(@"SJUIRecordAudioViewController: Audio session error: %@", sessionError);
        [self setDelegate:theDelegate];
        [self setContentSizeForViewInPopover:CGSizeMake(320, 250)];

    }
    return self;
}

- (void)loadView {
    CGRect cgRct = CGRectMake(0, 0, 320, 225);
    UIView *myView = [[UIView alloc] initWithFrame:cgRct];
    [self setView:myView];
    [myView setBackgroundColor:[UIColor blackColor]];
    recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [recordButton setFrame:CGRectMake(50, 25, 220, 44)];
    [recordButton addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [myView addSubview:recordButton];
    
    playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [playButton setFrame:CGRectMake(50, 75, 220, 44)];
    [playButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [myView addSubview:playButton];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(50, 125, 220, 44)];
    [button addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Cancel" forState:UIControlStateNormal];
    [myView addSubview:button];
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(50, 175, 220, 44)];
    [button addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Done" forState:UIControlStateNormal];
    [myView addSubview:button];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return NO;
}

- (void) record:(id)sender {
    if(recorder) {
        [recorder stop];
        recorder = nil;
        [sender setTitle:@"Record" forState:UIControlStateNormal];
    } else {
        NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
        [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatAppleIMA4] forKey: AVFormatIDKey];
        [recordSettings setObject:[NSNumber numberWithFloat:16000.0] forKey: AVSampleRateKey];
        [recordSettings setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        NSError *recordError;
        recorder = [[AVAudioRecorder alloc] initWithURL:audioURL settings:recordSettings error:&recordError];
        if(recordError) {
            NSLog(@"Record error: %@", recordError);
            return;
        }
        [recorder setDelegate:self];
        [recorder recordForDuration:(NSTimeInterval)10.0];
        [sender setTitle:@"Stop Recording" forState:UIControlStateNormal];
    }
}
- (void) play:(id)sender {
    if(player) {
        [player stop];
        player = nil;
        [sender setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        NSError *playError;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&playError];
        if(playError) {
            NSLog(@"Play error: %@", playError);
            return;
        }
        [player setDelegate:self];
        player.numberOfLoops = 0;
        [player play];
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
    }
}
- (void) cancel:(id)sender {
    // Remove the image
    NSError *fileError;
    [[NSFileManager defaultManager] removeItemAtPath:[audioURL path] error:&fileError];
    [delegate SJUIRecordAudioViewControllerReadyForDismissal:self];
}
- (void) done:(id)sender {
    [delegate SJUIRecordAudioViewControllerReadyForDismissal:self];
    
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)theRecorder successfully:(BOOL)flag {
    [recorder stop];
    recorder = nil;
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)thePlayer successfully:(BOOL)flag {
    [player stop];
    player = nil;
    [playButton setTitle:@"Play" forState:UIControlStateNormal];    
}
@end
