//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//


#import <Foundation/Foundation.h>
@class IPDFGenerator;

@protocol IPDFGeneratorDataSource <NSObject>

@required
- (id) reportsGenerator: (IPDFGenerator *)generator dataForReport: (NSString *)reportName withTag: (NSString *)tagName forPage: (NSUInteger)pageNumber;



@end
