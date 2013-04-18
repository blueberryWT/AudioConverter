//
//  ViewController.m
//  AudioConverter
//
//  Created by apple on 04/18/13.
//  Copyright (c) 2013 apple. All rights reserved.
//

#import "ViewController.h"
#import "RecorderManager.h"
#import "SecondViewController.h"

@interface ViewController ()
-(void) startRecordEvent:(id) sender;
-(void) stopRecordEvent:(id) sender;
-(void) next:(id) sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    NSLog(@"home = %@", NSHomeDirectory());
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _labelTip = [[UILabel alloc] init] ;
    [_labelTip setFont:[UIFont systemFontOfSize:14.0f]];
    [_labelTip setBackgroundColor:[UIColor clearColor]];
    [_labelTip setTextColor:[UIColor blackColor]];
    [_labelTip setText:@"请先录制一段语音,您可以随时结束"];
    [_labelTip setLineBreakMode:NSLineBreakByWordWrapping];
    [_labelTip setNumberOfLines:0];
    [self.view addSubview:_labelTip];
    [_labelTip sizeToFit];
    [_labelTip setFrame:CGRectMake(0, 0, 320, 100)];


    UIButton *startRecordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [startRecordButton setFrame:CGRectMake(100, 120, 100, 40)];
    [startRecordButton setTitle:@"开始录音" forState:UIControlStateNormal];
    [startRecordButton addTarget:self action:@selector(startRecordEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecordButton];

    UIButton *stopRecordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [stopRecordButton setFrame:CGRectMake(100, 220, 100, 40)];
    [stopRecordButton setTitle:@"停止录音" forState:UIControlStateNormal];
    [stopRecordButton addTarget:self action:@selector(stopRecordEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopRecordButton];

    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(55, 320, 200, 20)];
    [self.view addSubview:_progressView];
//
//
//    UIButton *playVoice = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [playVoice setFrame:CGRectMake(100, 80, 100, 40)];
//    [playVoice setTitle:@"播放Amr格式音频" forState:UIControlStateNormal];
//    [playVoice addTarget:self action:@selector(stopRecordEvent:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:playVoice];

    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    }

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStyleDone target:self action:@selector(next:)] autorelease];

}

- (void)updateProgress {
    CGFloat progress = [RecorderManager sharedInstance].currentSoundDecibels;
    if (progress >= 0) {
        [_progressView setProgress:progress animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startRecordEvent:(id)sender {
    NSLog(@"开始录音");
    [[RecorderManager sharedInstance] startRecorder:nil];
}

- (void)stopRecordEvent:(id)sender {
    NSLog(@"停止录音");
    [[RecorderManager sharedInstance] stopRecorder:nil];
    [_progressView setProgress:0 animated:NO];

    NSString *allPath = [NSString stringWithFormat:@"%@/%@", @"app目录下的", @"Library/Caches/DPVoice下能找到AMR文件，请点击下一步"];
    [self.labelTip setText:[NSString stringWithFormat:@"恭喜您已经完成了语音录制，并帮您转码完成，在%@", allPath]];
}

- (void)next:(id)sender {
    SecondViewController *secondViewController = [[[SecondViewController alloc] init] autorelease];
    [self.navigationController pushViewController:secondViewController animated:YES];
}


- (void)dealloc {
    [_timer release];
    [_progressView release];
    [_labelTip release];
    [super dealloc];
}


@end