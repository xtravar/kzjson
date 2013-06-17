//
//  KZMSJSONDateFormatter.m
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/29/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import "KZMSJSONDateFormatter.h"

#define kEscapedPrefix @"\\/Date("
#define kEscapedSuffix @")\\/"
#define kUnescapedPrefix @"/Date("
#define kUnescapedSuffix @")/"

#define kUnescapedFormat @"/Date(%lld)/"
#define kEscapedFormat @"\\/Date(%lld)\\/"

@implementation KZMSJSONDateFormatter {
    NSCalendar *_calendar;
}

-(id)init {
    self = [super init];
    if(self) {
        _shouldEscapeOutput = YES;
        _shouldEnforceEscapedInput = NO;
        _shouldEnforceUTC = NO;
        _calendar = [NSCalendar currentCalendar];
    }
    return self;
}

-(BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error {
    NSString *prefix = nil;
    // NSString *suffix = nil;
    if([string hasPrefix:kEscapedPrefix]) {
        prefix = kEscapedPrefix;
    } else if(!_shouldEnforceEscapedInput && [string hasPrefix:kUnescapedPrefix]) {
        prefix = kUnescapedPrefix;
    } else {
        if(error) {
            *error = @"Unexpected format - prefix does not match";
        }
        return NO;
    }
    
    if([string hasSuffix:kEscapedSuffix]) {
        // suffix = kEscapedSuffix;
    } else if(!_shouldEnforceEscapedInput && [string hasSuffix:kUnescapedSuffix]) {
        // suffix = kUnescapedSuffix;
    } else {
        if(error) {
            *error = @"Unexpected format - suffix does not match";
        }
        return NO;
    }
    
    string = [string substringFromIndex:prefix.length];
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    
    long long milliseconds;
    if(![scanner scanLongLong:&milliseconds]) {
        if(error) {
            *error = @"Unexpected format - no milliseconds found";
        }
        return NO;
    }
    
    if(_shouldEnforceUTC) {
        int timezoneCheck;
        if([scanner scanInt:&timezoneCheck]) {
            if(error) {
                *error = @"Validation failure - date was serialized with unspecified or local kind.";
            }
            return NO;
        }
    }
    
    *obj = [NSDate dateWithTimeIntervalSince1970:milliseconds / 1000];
    return YES;
}

-(NSString*)stringForObjectValue:(NSDate*)obj {
    if(![obj isKindOfClass:[NSDate class]]) {
        return nil;
    }
    
    NSString *format = _shouldEscapeOutput ? kEscapedFormat : kUnescapedFormat;
    return [[NSString alloc] initWithFormat:format, (long long)([obj timeIntervalSince1970] * 1000)];
}

@end
