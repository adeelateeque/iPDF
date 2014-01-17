//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPDFGeneratorDataSource.h"
#import "IPDFGeneratorDelegate.h"
#import "IPDFRenderOperation.h"
#import "GRMustache.h"

typedef NS_ENUM(NSInteger, IPDFPageOrientation) {
    IPDFPortraitPage,
    IPDFLandscapePage
};

@interface IPDFGenerator : NSObject<IPDFGeneratorDataSource, IPDFRenderOperationDelegate>
{
    NSString        *documentName;
    NSUInteger currentPage;
    NSUInteger totalPages;
    
    
    NSMutableData          *documentData;
    GRMustacheTemplate * template;
    
    NSMutableDictionary * renderedTags;
    
    UIPrintFormatter    * headerFormatter;
    NSMutableArray    *contentFormatters;
    UIPrintFormatter    * footerFormatter;
}


@property (nonatomic, weak)     id<IPDFGeneratorDataSource> dataSource;
@property (nonatomic, weak)     id<IPDFGeneratorDelegate> delegate;
@property (nonatomic, retain)   enum IPDFPageSize;
@property (nonatomic, retain)   NSOperationQueue * renderingQueue;

// Instance methods
- (void)generateContractWithName:(NSString *)reportName templates:(NSArray *)templatePaths pageOrientation:(IPDFPageOrientation)orientation dataSource:(id <IPDFGeneratorDataSource>)dataSource delegate:(id <IPDFGeneratorDelegate>)delegate error:(NSError *__autoreleasing *)error;

// Static methods
+ (IPDFGenerator *) sharedGenerator;


@end
