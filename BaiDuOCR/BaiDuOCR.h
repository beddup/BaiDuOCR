//
//  BaiDuOCR.h
//  BaiDuOCRDemo
//
//  Created by Amay on 10/30/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaiDuOCR : NSObject

-(void)registerAPIKey:(NSString*) apikey;

-(void)OCRJPGImageData:(NSData*) imageData completionHandler:(void(^)(NSDictionary* OCRResult,  NSError * error))completionHandler;

@end
