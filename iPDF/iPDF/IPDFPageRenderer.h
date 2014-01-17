//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPDFPageRenderer : UIPrintPageRenderer
{    
    UIPrintFormatter * headerPrintFormatter;
    UIPrintFormatter * footerPrintFormatter;
}

@property (nonatomic, assign) CGRect pageRect;

- (id)initWithHeaderFormatter:(UIPrintFormatter *)headerFormatter headerHeight:(CGFloat)headerHeight andContentFormatter:(UIPrintFormatter *) contentFormatter andFooterFormatter:(UIPrintFormatter *)footerFormatter footerHeight:(CGFloat)footerHeight;

- (void) addPagesToPdfContext;

@end
