//
//  iPDF.m
//  iPDF
//
//  Created by Adeel on 17/1/14.
//  Copyright (c) 2014 Adeel. All rights reserved.
//

#import "IPDFBlankRender.h"

@implementation IPDFBlankRender

- (CGRect)paperRect
{
    CGRect r = UIGraphicsGetPDFContextBounds();    
    return CGRectMake(0, 0, r.size.width, 1);
}

- (CGRect)printableRect
{
    return CGRectMake(0, 0, self.paperRect.size.width, 1);
}
@end
