//
//  ViewController.h
//  hikaku
//
//  Created by 安達 彰典 on 2012/08/25.
//  Copyright (c) 2012年 安達 彰典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Header.h"

@interface ViewController : UIViewController

#define DEV_SV_HOST  @"192.168.0.5"
#define DEV_SV_PORT  (10000)

@property IBOutlet UIButton *cl_button;
@property IBOutlet UIButton *sv_button;
@property IBOutlet UILabel *label;
@property IBOutlet UITextView *textview;


@property NSMutableData *payload;
@property GCDAsyncSocket *socket;
@property NSMutableString *resultLog;
@property NSTimeInterval sum;

- (NSMutableArray *) decodeDataJSON:(NSData *)data;
- (NSMutableArray *) decodeDataMessagePack:(NSData *)data;
- (NSData *) encodeDataJSON:(NSMutableDictionary *)dict;
- (NSData *) encodeDataMessagePack:(NSMutableArray *)dict;

@end
