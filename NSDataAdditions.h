//
//  NSDataAdditions.h
//  Master
//
//  Created by Alexander Rudenko on 3/12/10.
//  Copyright 2010 r3apps.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (NSDataAdditions)

+ (NSData *) dataWithBase64EncodedString:(NSString *) string;
- (id) initWithBase64EncodedString:(NSString *) string;

- (NSString *) base64Encoding;
- (NSString *) base64EncodingWithLineLength:(NSUInteger) lineLength;

- (BOOL) hasPrefix:(NSData *) prefix;
- (BOOL) hasPrefixBytes:(const void *) prefix length:(NSUInteger) length;

- (BOOL) hasSuffix:(NSData *) suffix;
- (BOOL) hasSuffixBytes:(const void *) suffix length:(NSUInteger) length;

@end

