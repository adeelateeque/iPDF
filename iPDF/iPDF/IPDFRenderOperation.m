//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import "IPDFRenderOperation.h"
#import "IPDFGenerator.h"

@implementation IPDFRenderOperation

- (id)initWithHtmlContent:(NSString *)html andSectionType: (IPDFSectionType)sectionType
{
    self = [super init];
    if (self)
    {        
        htmlSource = html;
        operationSectionType = sectionType;
        
        renderingWebView = [[UIWebView alloc] init];
        renderingWebView.delegate = self;
    }
    
    return self;
}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *appBaseURL = [NSURL fileURLWithPath:path];

    [renderingWebView loadHTMLString:htmlSource baseURL:appBaseURL];
}

- (BOOL)isConcurrent
{
    return NO;
}

- (BOOL)isFinished
{
    @synchronized(self)
    {
        return finished;
    }
}

- (BOOL)isExecuting
{
    @synchronized(self)
    {
        return executing;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    webView.delegate = nil;
    [self.delegate didFinishLoadingSection:operationSectionType withPrintFormatter:renderingWebView.viewPrintFormatter];
    [self willChangeValueForKey:@"isFinished"];
    finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    
    [self willChangeValueForKey:@"isExecuting"];
    
    executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
}

@end
