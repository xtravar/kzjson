//
//  KZJSONWriter.h
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/29/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import <Foundation/Foundation.h>

@interface KZJSONWriter : NSObject
@property (nonatomic) BOOL outputWhitespace;

-(id)initWithStream:(NSOutputStream*)stream;

-(void)open;
-(void)close;

-(BOOL)isOpen;


-(void)writeStartObject;
-(void)writeEndObject;

-(void)writeKey:(NSString*)key;

-(void)writeStartArray;
-(void)writeEndArray;

-(void)writeFullEndObjectAndArray;

-(void)writeNull;

-(void)writeBool:(BOOL)b;
-(void)writeNumber:(NSNumber*)number;

-(void)writeString:(NSString*)string;
-(void)writeString:(NSString*)string escaped:(BOOL)escaped;

-(void)writeStringFragment:(NSString*)string;
-(void)writeStringFragment:(NSString*)string escaped:(BOOL)escaped;
@end

@interface KZJSONWriter (Convenience)
-(void)writeStartArrayWithKey:(NSString*)key;
-(void)writeStartObjectWithKey:(NSString*)key;

-(void)writeNullWithKey:(NSString*)key;

-(void)writeBool:(BOOL)b withKey:(NSString*)key;
-(void)writeNumber:(NSNumber*)number withKey:(NSString*)key;
-(void)writeString:(NSString*)string withKey:(NSString*)key;
@end
