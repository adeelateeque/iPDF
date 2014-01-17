//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPDFRenderOperationDelegate.h"


@interface IPDFRenderOperation : NSOperation<UIWebViewDelegate>
{
    IPDFSectionType      operationSectionType;
    NSString            * htmlSource;
    UIWebView           * renderingWebView;
    
    BOOL executing;
    BOOL finished;
}


@property (nonatomic, weak) id<IPDFRenderOperationDelegate> delegate;

- (id) initWithHtmlContent: (NSString *)html andSectionType: (IPDFSectionType)sectionType;

@end
