//
//  KZJSON.h
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/20/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import <Foundation/Foundation.h>
typedef enum : char {
    KZJSONNodeTypeInvalid,
    KZJSONNodeTypeArray = '[',
    KZJSONNodeTypeEndArray = ']',
    KZJSONNodeTypeObject = '{',
    KZJSONNodeTypeEndObject = '}',
    KZJSONNodeTypeNull = '0',
    KZJSONNodeTypeString = 'S',
    KZJSONNodeTypeNumber = '#',
    KZJSONNodeTypeBool = 'b'
} KZJSONNodeType;

#import "KZJSONReader.h"
#import "KZJSONWriter.h"
#import "KZMSJSONDateFormatter.h"
