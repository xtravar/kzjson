//
//  KZJSONWriter+Convenience.m
//  KZJSON
//
//  Created by Mike Kasianowicz on 9/11/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import "KZJSONWriter.h"

@implementation KZJSONWriter (Convenience)
-(void)writeBool:(BOOL)b withKey:(NSString *)key {
    [self writeKey:key];
    [self writeBool:b];
}

-(void)writeNumber:(NSNumber*)number withKey:(NSString*)key {
    [self writeKey:key];
    [self writeNumber:number];
}

-(void)writeString:(NSString*)string withKey:(NSString*)key {
    [self writeKey:key];
    [self writeString:string];
}

-(void)writeStartObjectWithKey:(NSString *)key {
    [self writeKey:key];
    [self writeStartObject];
}

-(void)writeStartArrayWithKey:(NSString *)key {
    [self writeKey:key];
    [self writeStartArray];
}


-(void)writeNullWithKey:(NSString*)key {
    [self writeKey:key];
    [self writeNull];
}
@end
