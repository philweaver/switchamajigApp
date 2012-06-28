//
//  SJUIStatusMessageLabel.m
//  SwitchControl
//
//  Created by Phil Weaver on 6/16/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJUIStatusMessageLabel.h"

@implementation SJUIStatusMessageLabel

- (id) initWithFrame:(CGRect)frame {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTextInMainThread:) name:@"switchamajigMessagesSetText" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setColorInMainThread:) name:@"switchamajigMessagesSetColor" object:nil];
    return [super initWithFrame:frame];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self]; 
}

- (void) setColorInMainThread:(NSNotification *)notification {
    [self performSelectorOnMainThread:@selector(setTextColor:) withObject:[notification object] waitUntilDone:NO];
}

- (void) setTextInMainThread:(NSNotification *)notification {
    [self performSelectorOnMainThread:@selector(setText:) withObject:[notification object] waitUntilDone:NO];
}

@end
