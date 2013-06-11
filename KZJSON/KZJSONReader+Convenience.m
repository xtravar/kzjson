//
//  KZJSONReader+Convenience.m
//  JSONTEST
//
//  Created by Mike Kasianowicz on 5/24/13.
//  Copyright (c) 2013 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import "KZJSONReader.h"

@implementation KZJSONReader (Convenience)
-(void)readOnly:(KZJSONNodeType)type {
    if(self.nodeType == type) {
        [self read];
        return;
    }
    
    switch(self.nodeType) {
        case KZJSONNodeTypeInvalid:
            [NSException raise:@"KZJSONException" format:@"Unexpected end of file"];
            
        default:
            [NSException raise:@"KZJSONException" format:@"Unexpected token"];
    }
}

-(void)readStartObject {
    [self readOnly:KZJSONNodeTypeObject];
}

-(void)readEndObject {
    [self readOnly:KZJSONNodeTypeEndObject];
}

-(void)readStartArray {
    [self readOnly:KZJSONNodeTypeArray];
}

-(void)readEndArray {
    [self readOnly:KZJSONNodeTypeEndArray];
}


-(BOOL)readBoolWithKey:(NSString*)key {
    if(![key isEqualToString:self.key]) {
        [NSException raise:@"KZJSONException" format:@"unexpected key"];
    }
    return [self readBool];
}

-(NSNumber*)readNumberWithKey:(NSString*)key {
    if(![key isEqualToString:self.key]) {
        [NSException raise:@"KZJSONException" format:@"unexpected key"];
    }
    return [self readNumber];
}

-(NSString*)readStringWithKey:(NSString*)key {
    if(![key isEqualToString:self.key]) {
        [NSException raise:@"KZJSONException" format:@"unexpected key"];
    }
    return [self readString];
}

-(void)readStartObjectWithKey:(NSString*)key {
    if(![key isEqualToString:self.key]) {
        [NSException raise:@"KZJSONException" format:@"unexpected key"];
    }
    [self readStartObject];
}

-(void)readStartArrayWithKey:(NSString*)key {
    if(![key isEqualToString:self.key]) {
        [NSException raise:@"KZJSONException" format:@"unexpected key"];
    }
    [self readStartArray];
}


-(BOOL)isNull {
    return self.nodeType == KZJSONNodeTypeNull;
}

-(BOOL)isEndObject {
    return self.nodeType == KZJSONNodeTypeEndObject;
}

-(BOOL)isEndArray {
    return self.nodeType == KZJSONNodeTypeEndArray;
}

@end
