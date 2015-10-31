//
//  BaiDuOCR.m
//  BaiDuOCRDemo
//
//  Created by Amay on 10/30/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "BaiDuOCR.h"

@interface NSData (base64)

-(NSString*)base64EncodedString;

@end

@implementation NSData (base64)

- (NSString *)base64EncodedString
{
    if (![self length]) return nil;
    NSString *encoded = nil;
    encoded = [self base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    return encoded;
}

@end

@interface NSString (urlencode)

-(NSString*)urlEncodeString;

@end

NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

@implementation NSString (urlencode)
-(NSString *)urlEncodeString{
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];

    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];

    static NSUInteger const batchSize = 50;

    NSInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;

    while (index < self.length) {
        NSUInteger length = MIN(self.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);

        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [self rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [self substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }
    
    return escaped;

}

@end

NSString* freeOCRURL = @"http://apis.baidu.com/apistore/idlocr/ocr";
NSString* payOCRURL = @"http://apis.baidu.com/idl_baidu/baiduocrpay/idlocrpaid";

@interface BaiDuOCR()

@property(copy, nonatomic)NSString* apiKey;

@end
@implementation BaiDuOCR

-(void)registerAPIKey:(NSString *)apikey{
    self.apiKey = apikey;
}

-(void)OCRJPGImageData:(NSData *)imageData completionHandler:(void (^)(NSDictionary *ocrResult, NSError * error))completionHandler
{


    // generate based64 + urlencode imagedata;
    NSString* imageBase64String = [imageData base64EncodedString];
    NSString* imageBaes64URLEncodeString = [imageBase64String urlEncodeString];

    //configure request, try the free version first, if runover, then try the pay version
    NSMutableURLRequest* freeOCRRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:freeOCRURL]];
    freeOCRRequest.HTTPMethod = @"POST";
    [freeOCRRequest addValue: self.apiKey
          forHTTPHeaderField: @"apikey"];
    [freeOCRRequest addValue: @"application/x-www-form-urlencoded"
          forHTTPHeaderField: @"Content-Type"];
    NSString* requestBody = [NSString stringWithFormat:@"fromdevice=iPhone&clientip=10.10.10.0&detecttype=LocateRecognize&languagetype=CHN_ENG&imagetype=1&image=%@",imageBaes64URLEncodeString];
    NSData* httpBody = [requestBody dataUsingEncoding:NSUTF8StringEncoding];
    freeOCRRequest.HTTPBody = httpBody;

    // create data task
    NSURLSession* session =[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    NSURLSessionDataTask* task = [session dataTaskWithRequest:freeOCRRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable freeOCRError) {
        if (freeOCRError) {
            // connection error
            completionHandler(nil, freeOCRError);
        }else{
            NSDictionary* freeOCRResult = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
            if ([freeOCRResult[@"errNum"] integerValue] == 0) {
                // success
                completionHandler(freeOCRResult, nil);
            }else if ([freeOCRResult[@"errNum"] integerValue] == 300202){
                // free call overrun, try payOCRURL
                NSMutableURLRequest* payOCRRequest = freeOCRRequest;
                payOCRRequest.URL = [NSURL URLWithString:payOCRURL];
                NSURLSessionDataTask* payTask = [session dataTaskWithRequest:payOCRRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable payOCRError) {
                    if (payOCRError) {
                        //connection error;
                        completionHandler(nil,payOCRError);
                    }else{
                        NSDictionary* payOCRResult = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
                        if ([payOCRResult[@"errNum"] integerValue] == 0) {
                            // success
                            completionHandler(payOCRResult, nil);
                        }else{
                            // fail
                            NSError* error = [self  OCRErroeWithResult:payOCRResult];
                            completionHandler(payOCRResult, error);
                        }
                    }
                }];
                [payTask resume];
            }else{
                NSError* error = [self  OCRErroeWithResult:freeOCRResult];
                completionHandler(freeOCRResult, error);
            }
        }
    }];
    [task resume];

}

-(NSError*) OCRErroeWithResult:(NSDictionary*)result{
    NSInteger code = [result[@"errNum"] integerValue];
    if (code == 0) {
        return nil;
    }
    NSString* domin = @"未知错误";
    if (code > 300300) {
        domin = @"代理平台错误";
    }
    if (code > 300200) {
        domin = @"调用方错误";
    }
    if (code > 300100) {
        domin = @"限制类错误";
    }
    NSError* error = [NSError errorWithDomain:domin code:code userInfo:result];
    return error;

}


@end
