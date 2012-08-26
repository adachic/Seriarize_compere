//
//  ViewController.m
//  hikaku
//
//  Created by 安達 彰典 on 2012/08/25.
//  Copyright (c) 2012年 安達 彰典. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController


//#define TEST_JSON 1
#define TEST_MESSAGEPACK 1


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.resultLog = [NSMutableString string];
    
    [self.cl_button addTarget:self
            action:@selector(exec_cl:) forControlEvents:UIControlEventTouchUpInside];
    [self.sv_button addTarget:self
            action:@selector(exec_sv:) forControlEvents:UIControlEventTouchUpInside];

    self.sum = 0;
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
/*
    self.socket = [[GCDAsyncSocket alloc] init];
    self.socket.delegate = self;
    self.socket.delegateQueue = dispatch_get_main_queue();
*/
}

#define TAG_WRITE          1<<0
#define TAG_READ_LENGTH    1<<8
#define TAG_READ_DONE      1<<9

static int times = 0;

- (void)exec_cl:(UIButton*)button
{
    [self.sv_button setEnabled:NO];
    self.label.text = @"running in Client mode";
    NSError *err;
    
    if(![self.socket connectToHost:DEV_SV_HOST onPort:DEV_SV_PORT error:&err] && !times){
        NSLog(@"connection error : %@",err);
    }

    /*テストデータの生成*/
    NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
    [mdic setObject:[self makeStringAZ:300000] forKey:@"key1"];
    [mdic setObject:[self makeStringAZ:300000] forKey:@"key2"];
    [mdic setObject:[self makeStringAZ:400000] forKey:@"key3"];
    
    NSDate *startDate = [NSDate date];
    
    //do something
#ifdef TEST_MESSAGEPACK
    NSData *packed = [self encodeDataMessagePack:mdic];
#elif TEST_JSON
    NSData *packed = [self encodeDataJSON:mdic];
#endif
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];
    self.sum += interval;
    self.label.text = [NSString stringWithFormat:@"ave:%lf",self.sum/(times+1)];
    NSLog(@"%02d:encode time is %lf ",times, interval);
    [self.resultLog appendString:[NSString stringWithFormat:@"%02d:encode time:%lf\n",times, interval]];
    self.textview.text = self.resultLog;
    
    NSInteger datalen = [packed length];
    NSMutableData *d = [NSMutableData dataWithLength:0];
    [d appendBytes:&datalen length:4];
    [d appendData:packed];
    [self.socket writeData:d withTimeout:-1 tag:TAG_WRITE];
    times++;

}

/* aからzまでを繰り返す文字列を作る */
- (NSString *)makeStringAZ:(NSInteger)length
{
    NSMutableString *str = [NSMutableString string];
    unichar a = 0;
    for (int i=0; i<length; i++) {
        a = 'a'+i%26;
        [str appendString:[NSString stringWithCharacters:&a length:1]];
    }
    return str;
}

- (void)exec_sv:(UIButton*)button
{
    [self.cl_button setEnabled:NO];
    self.label.text = @"running in Server mode: ready";

    NSError *error;
    if (![self.socket acceptOnPort:DEV_SV_PORT error:&error])
    {
        NSLog(@"I goofed: %@", error);
    }
}

- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [newSocket readDataToLength:4 withTimeout:-1 buffer:self.payload bufferOffset:0 tag:TAG_READ_LENGTH];

}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    int size = 0;

    if (tag == TAG_READ_LENGTH){
        [data getBytes:&size length: sizeof(size)];
        NSLog(@"recvd size=%d",size);
        [sender readDataToLength:size withTimeout:-1 buffer:self.payload bufferOffset:0 tag:TAG_READ_DONE];
        return;
    }
    
    if (tag == TAG_READ_DONE){
        NSDate *startDate = [NSDate date];

#ifdef TEST_MESSAGEPACK
        NSLog(@"recv MessagePack");
        NSMutableDictionary *dict = [self decodeDataMessagePack:data];
#elif TEST_JSON
        NSLog(@"recv Json");
        NSMutableDictionary *dict = [self decodeDataJSON:data];
#endif
        
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];
        self.sum += interval;
        self.label.text = [NSString stringWithFormat:@"ave:%lf",self.sum/(times+1)];
        NSLog(@"%02d:decode time is %lf ",times, interval);
        [self.resultLog appendString:[NSString stringWithFormat:@"%02d:encode time:%lf\n",times, interval]];
        self.textview.text = self.resultLog;

        times++;
        [sender readDataToLength:4 withTimeout:-1 buffer:self.payload bufferOffset:0 tag:TAG_READ_LENGTH];
 
        return;
    }
}

- (NSMutableArray *) decodeDataJSON:(NSData *)data
{
    return  [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

- (NSMutableArray *) decodeDataMessagePack:(NSData *)data
{
    return [data messagePackParse];
}

- (NSData *) encodeDataJSON:(NSMutableDictionary *)dict
{
    return [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
}

- (NSData *) encodeDataMessagePack:(NSMutableArray *)dict
{
    return [dict messagePack];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end