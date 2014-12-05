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
