//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import "IPDFGenerator.h"
#import "IPDFPageRenderer.h"
#import "IPDFBlankRender.h"

@implementation IPDFGenerator

// Static fields
static IPDFGenerator *instance = nil;
static NSArray *reportDefaultTags = nil;
IPDFPageRenderer *pageRenderer;

+ (IPDFGenerator *)sharedGenerator {
    @synchronized (self) {
        if (instance == nil) {
            instance = [[IPDFGenerator alloc] init];


            reportDefaultTags = @[@"documentHeader", @"pageHeader", @"pageContent", @"pageFooter", @"pageNumber", @"pageBreak"];
        }

        return instance;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialize rendering queue
        self.renderingQueue = [NSOperationQueue mainQueue];
        self.renderingQueue.name = @"Rendering Queue";
        self.renderingQueue.maxConcurrentOperationCount = 1;

        renderedTags = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)generatePDFWithName:(NSString *)reportName templates:(NSArray *)templates pageOrientation:(IPDFPageOrientation)orientation dataSource:(id <IPDFGeneratorDataSource>)dataSource delegate:(id <IPDFGeneratorDelegate>)delegate error:(NSError * __autoreleasing *)error {
    
    // TODO: replace and add report processing to queue
    if (self.renderingQueue.operationCount > 0)
        return;

    self.dataSource = dataSource;
    self.delegate = delegate;
    documentName = reportName;
    documentData = [NSMutableData data];

    template = [GRMustacheTemplate templateFromString:[self assembleTemplates:templates] error:error];

    if (*error)
        return;

    if (orientation == IPDFPortraitPage)
        UIGraphicsBeginPDFContextToData(documentData, CGRectMake(0, 0, 880, 1140), nil);
    else
        UIGraphicsBeginPDFContextToData(documentData, CGRectMake(0, 0, 1140, 880), nil);

    contentFormatters = [[NSMutableArray alloc] init];

    NSInvocationOperation *createPageOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(createPage:) object:[NSNumber numberWithInteger:0]];
    [self.renderingQueue addOperation:createPageOperation];
}

- (void)createPage:(NSNumber *)page {
    int i = [page intValue];
    [renderedTags removeAllObjects];
    currentPage = i;
    if (currentPage == 0) {
        NSError *error;
        // IPDFGenerator is key-value "get" compliant (as GRMustache needs), so we could use self
        NSString *renderedHtml = [template renderObject:self error:&error];

        NSMutableString *wellFormedHeader = [NSMutableString stringWithString:renderedHtml];
        NSMutableString *wellFormedContent = [NSMutableString stringWithString:renderedHtml];
        NSMutableString *wellFormedFooter = [NSMutableString stringWithString:renderedHtml];

        // Trim content and footer to get header
        [wellFormedHeader replaceOccurrencesOfString:[renderedTags objectForKey:@"pageContent"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedHeader.length)];
        [wellFormedHeader replaceOccurrencesOfString:[renderedTags objectForKey:@"pageFooter"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedHeader.length)];

        // Trim header and footer to get content
        [wellFormedContent replaceOccurrencesOfString:[renderedTags objectForKey:@"documentHeader"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedContent.length)];
        [wellFormedContent replaceOccurrencesOfString:[renderedTags objectForKey:@"pageHeader"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedContent.length)];
        [wellFormedContent replaceOccurrencesOfString:[renderedTags objectForKey:@"pageFooter"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedContent.length)];

        // Trim content and header to get footer
        [wellFormedFooter replaceOccurrencesOfString:[renderedTags objectForKey:@"documentHeader"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedFooter.length)];
        [wellFormedFooter replaceOccurrencesOfString:[renderedTags objectForKey:@"pageHeader"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedFooter.length)];
        [wellFormedFooter replaceOccurrencesOfString:[renderedTags objectForKey:@"pageContent"] withString:@"" options:NSLiteralSearch range:NSMakeRange(0, wellFormedFooter.length)];

        IPDFRenderOperation *headerOperation = [[IPDFRenderOperation alloc] initWithHtmlContent:wellFormedHeader andSectionType:IPDFSectionTypeHeader];
        headerOperation.delegate = self;

        IPDFRenderOperation *footerOperation = [[IPDFRenderOperation alloc] initWithHtmlContent:wellFormedFooter andSectionType:IPDFSectionTypeFooter];
        footerOperation.delegate = self;

        NSMutableArray *operations = [[NSMutableArray alloc] init];
        [operations addObject:headerOperation];
        [operations addObjectsFromArray:[self findAndInsertPageBreaks:wellFormedContent]];
        [operations addObject:footerOperation];


        [self.renderingQueue addOperations:operations waitUntilFinished:NO];
    }
    else if (contentFormatters.count > 0) {
        for (int i = 0; i < contentFormatters.count; i++) {
            currentPage += ((UIPrintFormatter *) contentFormatters[i]).pageCount;
            NSInvocationOperation *renderToPdf = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(internalRenderPage:) object:contentFormatters[i]];
            [self.renderingQueue addOperation:renderToPdf];
        }

        [self.renderingQueue addOperationWithBlock:^{
            // Invoke on main thread, otherwise it won't work!
            [self closePdfContext];
        }];

    }
}

//Assembles multiple templates/parts into one template
- (NSString *) assembleTemplates:(NSArray *)templates {
    NSMutableString *masterTemplate = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"container" ofType:@"mustache"] encoding:NSUTF8StringEncoding error:nil];
    //The range of content between {{#pageContent}}{{/pageContent}}  tags
    NSRange pageContentRange;

    NSUInteger contentLength = [masterTemplate length];
    NSRange range = NSMakeRange(0, contentLength);

    while (range.location != NSNotFound) {
        range = [masterTemplate rangeOfString:@"{{#pageContent}}" options:0 range:range];
        if (range.location != NSNotFound) {
            //range of characters from end of {{/pageContent}} tag to the end of content
            range = NSMakeRange(range.location + range.length, contentLength - (range.location + range.length));
            NSRange bodyEndRange = [masterTemplate rangeOfString:@"{{/pageContent}}" options:0 range:range];
            if (bodyEndRange.location != NSNotFound) {
                pageContentRange = NSMakeRange(range.location, bodyEndRange.location - range.location);
            }

        }
    }

    for (NSString *templateString in templates) {
        [masterTemplate insertString:templateString atIndex:pageContentRange.location];
        pageContentRange.location = pageContentRange.location + templateString.length;
    }

    return masterTemplate;
}


- (NSArray *)findAndInsertPageBreaks:(NSMutableString *)content {
    //The range of content between <body></body> tags
    NSRange bodyRange;

    NSUInteger contentLength = [content length];
    NSRange range = NSMakeRange(0, contentLength);

    //find the range of <body>
    while (range.location != NSNotFound) {
        range = [content rangeOfString:@"<body>" options:0 range:range];
        if (range.location != NSNotFound) {
            //range of characters from end of </body> tag to the end of content
            range = NSMakeRange(range.location + range.length, contentLength - (range.location + range.length));
            NSRange bodyEndRange = [content rangeOfString:@"</body>" options:0 range:range];
            if (bodyEndRange.location != NSNotFound) {
                bodyRange = NSMakeRange(range.location, bodyEndRange.location - range.location);
            }

        }
    }

    NSMutableArray *pageRenderOperations = [[NSMutableArray alloc] init];
    NSRange searchRange = bodyRange;
    NSUInteger previousPageBreakLocation = searchRange.location;
    do {
        NSRange markerRange = [content rangeOfString:@"{{pageBreak}}" options:0 range:searchRange];
        if (markerRange.location != NSNotFound) {
            NSRange contentRange = NSMakeRange(previousPageBreakLocation, markerRange.location - previousPageBreakLocation);

            NSMutableString *html = [[NSMutableString alloc] init];
            [html appendString:[content substringWithRange:NSMakeRange(0, bodyRange.location)]];
            [html appendString:[content substringWithRange:contentRange]];
            [html appendString:[content substringWithRange:NSMakeRange(bodyRange.location + bodyRange.length, contentLength - (bodyRange.location + bodyRange.length))]];

            IPDFRenderOperation *pageOperation = [[IPDFRenderOperation alloc] initWithHtmlContent:html andSectionType:IPDFSectionTypeContent];
            pageOperation.delegate = self;
            [pageRenderOperations addObject:pageOperation];
            // Reset search range for next attempt to start after the current found range
            searchRange.location = markerRange.location + markerRange.length;
            searchRange.length = bodyRange.location + bodyRange.length - searchRange.location;
            previousPageBreakLocation = searchRange.location;
        } else {
            // If we didn't find it, we have no more occurrences
            break;
        }
    } while (1);
    return pageRenderOperations;
}

- (id)valueForKey:(NSString *)key {
    id <IPDFGeneratorDataSource> source = [reportDefaultTags containsObject:key] ? self : self.dataSource;
    id data = [source reportsGenerator:self dataForReport:documentName withTag:key forPage:currentPage];


    return data;
}

- (id)reportsGenerator:(IPDFGenerator *)generator dataForReport:(NSString *)reportName withTag:(NSString *)tagName forPage:(NSUInteger)pageNumber {

    return [GRMustache renderingObjectWithBlock:^NSString *(GRMustacheTag *tag, GRMustacheContext *context, BOOL *HTMLSafe, NSError *__autoreleasing *error) {
        NSString *renderedTag;
        if (pageNumber > 1 && [tagName isEqualToString:@"documentHeader"]) {
            renderedTag = @"";
        }
        else if ([tagName isEqualToString:@"pageNumber"]) {
            renderedTag = [NSString stringWithFormat:@"%lu", (unsigned long)pageNumber];
        }
        else if ([tagName isEqualToString:@"pageBreak"]) {
            renderedTag = @"{{pageBreak}}";
        }
        else
            renderedTag = [tag renderContentWithContext:context HTMLSafe:HTMLSafe error:error];

        [renderedTags setObject:renderedTag forKey:tagName];

        return renderedTag;
    }];
}

- (void)didFinishLoadingSection:(IPDFSectionType)sectionType withPrintFormatter:(UIPrintFormatter *)formatter {
    if (sectionType == IPDFSectionTypeHeader)
        headerFormatter = formatter;
    else if (sectionType == IPDFSectionTypeContent) {
        [contentFormatters addObject:formatter];
        totalPages += formatter.pageCount;

        if (currentPage == 0) {
            currentPage = 1;
            NSInvocationOperation *createNextPage = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(createPage:) object:[NSNumber numberWithInteger:currentPage]];
            [self.renderingQueue addOperation:createNextPage];
        }
    }
    else if (sectionType == IPDFSectionTypeFooter)
        footerFormatter = formatter;
    else
        [NSException raise:@"Invalid Section Type" format:@"Section Type: %d is invalid", (int) sectionType];
}

- (void)internalRenderPage:(UIPrintFormatter *)contentFormatter {
    IPDFBlankRender *headerFakeRenderer = [[IPDFBlankRender alloc] init];
    headerFakeRenderer.contentHeight = 150;
    [headerFakeRenderer addPrintFormatter:headerFormatter startingAtPageAtIndex:0];
    IPDFBlankRender *footerFakeRenderer = [[IPDFBlankRender alloc] init];
    footerFakeRenderer.contentHeight = 50;
    [footerFakeRenderer addPrintFormatter:footerFormatter startingAtPageAtIndex:0];

    NSUInteger headerHeight = [headerFakeRenderer contentHeight];
    NSUInteger footerHeight = [footerFakeRenderer contentHeight];

    pageRenderer = [[IPDFPageRenderer alloc] initWithHeaderFormatter:headerFormatter headerHeight:headerHeight andContentFormatter:contentFormatter andFooterFormatter:footerFormatter footerHeight:footerHeight];
    [pageRenderer addPagesToPdfContext];
    currentPage += pageRenderer.numberOfPages;
}

- (void)closePdfContext {
    UIGraphicsEndPDFContext();
    [self.delegate iPDFGenerator:self didFinishRenderingWithData:documentData];
    documentData = nil;
}

@end
