//
//  KZMSJSONDateFormatter.h
//  KZJSON
//
//  Created by Mike Kasianowicz on 7/29/12.
//  Copyright (c) 2012 Mike Kasianowicz. All rights reserved.
//
//  This file is part of KZJSON.  KZJSON is licenced under the MIT License.
//  See README.md or http://opensource.org/licenses/MIT for detailed information.
//

#import <Foundation/Foundation.h>

@interface KZMSJSONDateFormatter : NSFormatter
@property (nonatomic) BOOL shouldEscapeOutput;
@property (nonatomic) BOOL shouldEnforceEscapedInput;
@property (nonatomic) BOOL shouldEnforceUTC;
@end

