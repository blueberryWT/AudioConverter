//
// Created by apple on 13-4-18.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SecondViewController.h"
#import "PlayAMR.h"


@interface SecondViewController(Private)
-(void)playRecordAMREvent:(id)sender;
-(void) playLocalAMREvent:(id) sender;
@end

@implementation SecondViewController


-(void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    _labelTip = [[UILabel alloc] init] ;
    [self.labelTip setFont:[UIFont systemFontOfSize:14.0f]];
    [self.labelTip setBackgroundColor:[UIColor clearColor]];
    [self.labelTip setTextColor:[UIColor blackColor]];
    [self.labelTip setText:@"现在点击，就可以播放您刚才录制的AMR音频，这个音频也可以是其他客户端录制的"];
    [self.labelTip setLineBreakMode:NSLineBreakByWordWrapping];
    [self.labelTip setNumberOfLines:0];
    [self.view addSubview:self.labelTip];
    [self.labelTip sizeToFit];
    [self.labelTip setFrame:CGRectMake(0, 0, 320, 100)];



    UIButton *startRecordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [startRecordButton setFrame:CGRectMake(100, 100, 100, 40)];
    [startRecordButton setTitle:@"播放录制文件" forState:UIControlStateNormal];
    [startRecordButton addTarget:self action:@selector(playRecordAMREvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecordButton];

    UIButton *startRecordButton_1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [startRecordButton_1 setFrame:CGRectMake(100, 180, 100, 40)];
    [startRecordButton_1 setTitle:@"播放本地文件" forState:UIControlStateNormal];
    [startRecordButton_1 addTarget:self action:@selector(playLocalAMREvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecordButton_1];
}


- (void)playRecordAMREvent:(id)sender {
    // 获取文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cache objectAtIndex:0];

    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/DPVoice", cachePath] error:nil];
    NSString *playFilePath = [NSString stringWithFormat:@"%@/DPVoice/%@", cachePath, fileList.lastObject];

    NSData *data = [NSData dataWithContentsOfFile:playFilePath];


    if (nil == _player) {
        _player = [[PlayAMR alloc] init];
    }
    [_player finishPlay:^(id block) {
        // 这个工程没用ARC的方式
        // 如果在这里面操作self一类的，一定要在外面声明 __block SecondViewController* bself = self;
        // 然后使用bself 代替self
        NSLog(@"播放完成");
    }];
    [_player playAMR:playFilePath];
    NSLog(@"aa");

}

- (void)playLocalAMREvent:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"healTheWorld" ofType:@"amr"];
    if (nil == _player) {
        _player = [[PlayAMR alloc] init];
    }
    [_player finishPlay:^(id block) {
        // 这个工程没用ARC的方式
        // 如果在这里面操作self一类的，一定要在外面声明 __block SecondViewController* bself = self;
        // 然后使用bself 代替self
        NSLog(@"播放完成");
    }];
    [_player playAMR:path];
}


- (void)dealloc {
    [_labelTip release];
    [_player release];
    [super dealloc];
}
@end