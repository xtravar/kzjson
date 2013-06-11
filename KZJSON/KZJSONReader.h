//
//  KZJSONReader.h
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/29/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import <Foundation/Foundation.h>
#import "KZJSON.h"

// JSON supports four data types:
//  objects (dictionaries), arrays, numbers, and strings
@interface KZJSONReader : NSObject
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) id value;
@property (nonatomic, readonly) KZJSONNodeType nodeType;

-(id)initWithStream:(NSInputStream*)stream;
-(void)open;
-(void)close;
-(BOOL)isOpen;

-(BOOL)read;
-(void)skip;
-(BOOL)hasValue;

-(BOOL)readBool;
-(NSNumber*)readNumber;
-(NSString*)readString;

@end

@interface KZJSONReader (Convenience)
-(void)readStartObject;
-(void)readEndObject;

-(void)readStartArray;
-(void)readEndArray;

-(BOOL)readBoolWithKey:(NSString*)key;
-(NSNumber*)readNumberWithKey:(NSString*)key;
-(NSString*)readStringWithKey:(NSString*)key;

-(void)readStartObjectWithKey:(NSString*)key;
-(void)readStartArrayWithKey:(NSString*)key;

-(BOOL)isNull;
-(BOOL)isEndObject;
-(BOOL)isEndArray;
@end
