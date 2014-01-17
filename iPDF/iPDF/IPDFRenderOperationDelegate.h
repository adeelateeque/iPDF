//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IPDFSectionType) {
    IPDFSectionTypeHeader,
    IPDFSectionTypeContent,
    IPDFSectionTypeFooter
};

@protocol IPDFRenderOperationDelegate <NSObject>

- (void) didFinishLoadingSection: (IPDFSectionType)sectionType withPrintFormatter: (UIPrintFormatter *)formatter;

@end
