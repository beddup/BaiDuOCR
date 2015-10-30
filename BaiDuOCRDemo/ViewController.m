//
//  ViewController.m
//  BaiDuOCRDemo
//
//  Created by Amay on 10/29/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "ViewController.h"
#import "BaiDuOCR.h"

NSString* const apiKey = @"074a6c4e8c386b11a8eaa00a04195175";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    BaiDuOCR* freeOCR = [[BaiDuOCR alloc] init];
    [freeOCR registerAPIKey:apiKey];
    NSString* path = [[NSBundle mainBundle]pathForResource:@"42" ofType:@"jpg"];
    NSData* imageData = [NSData dataWithContentsOfFile:path];

    [freeOCR OCRJPGImageData:imageData completionHandler:^(NSDictionary *OCRResult, NSError* error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    NSLog(@"%@",OCRResult);
                    NSArray* array = [OCRResult[@"retData"] valueForKey:@"word"];
                    NSString* words = [array componentsJoinedByString:@";"];
                    self.textview.text = words;
                }
            });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
