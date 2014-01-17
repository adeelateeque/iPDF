//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IPDFGenerator;

@protocol IPDFGeneratorDelegate <NSObject>

- (void) iPDFGenerator:(IPDFGenerator *)generator didFinishRenderingWithData: (NSData *)data;

@end
