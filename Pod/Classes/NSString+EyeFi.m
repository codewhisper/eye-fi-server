//
//  NSString+EyeFi.m
//  EyeFiServer
//
//  Created by Michael Litvak on 7/23/14.
//  Copyright (c) 2014 codewhisper. All rights reserved.
//

#import "NSString+EyeFi.h"

@implementation NSString (EyeFi)

NSString *characters = @"abcdefghijklmnopqrstuvwxyz0123456789";

- (NSString*)md5
{
    // Create pointer to the string as UTF8
    const char *ptr = [self UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+ (NSString *)randomStringWithLength:(NSUInteger)length {
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%C", [characters characterAtIndex: arc4random_uniform([characters length]) % [characters length]]];
    }
    
    return randomString;
}

@end
