//
//  DGCurvedLabel.m
//  DGCurvedLabel
//
//  Created by Daniel Cohen Gindi on 10/27/14.
//  Copyright (c) 2014 DCG. All rights reserved.
//
//  This class is based on Apple's sample code of CoreTextArcCocoa
//
//  The original license disclaimer follows:
//
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Inc. ("Apple") in consideration of your agreement to the following
//  terms, and your use, installation, modification or redistribution of
//  this Apple software constitutes acceptance of these terms.  If you do
//  not agree with these terms, please do not use, install, modify or
//  redistribute this Apple software.
//
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software.
//  Neither the name, trademarks, service marks or logos of Apple Inc. may
//  be used to endorse or promote products derived from the Apple Software
//  without specific prior written permission from Apple.  Except as
//  expressly stated in this notice, no other rights or licenses, express or
//  implied, are granted by Apple herein, including but not limited to any
//  patent rights that may be infringed by your derivative works or by other
//  works in which the Apple Software may be incorporated.
//
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//                            SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//                            INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Copyright (C) 2013 Apple Inc. All Rights Reserved.
//

#import "DGCurvedLabel.h"
#import <CoreText/CoreText.h>

@implementation DGCurvedLabel

typedef struct GlyphArcInfo
{
    CGFloat width;
    CGFloat angle;
} GlyphArcInfo;

static void PrepareGlyphArcInfo(CGFloat radius, CTLineRef line, CFIndex glyphCount, GlyphArcInfo *glyphArcInfo)
{
    NSArray *runArray = (__bridge NSArray *)CTLineGetGlyphRuns(line);
    
    // Examine each run in the line, updating glyphOffset to track how far along the run is in terms of glyphCount.
    CFIndex glyphOffset = 0;
    for (id run in runArray)
    {
        CFIndex runGlyphCount = CTRunGetGlyphCount((__bridge CTRunRef)run);
        
        // Ask for the width of each glyph in turn.
        CFIndex runGlyphIndex = 0;
        for (; runGlyphIndex < runGlyphCount; runGlyphIndex++)
        {
            glyphArcInfo[runGlyphIndex + glyphOffset].width = CTRunGetTypographicBounds((__bridge CTRunRef)run, CFRangeMake(runGlyphIndex, 1), NULL, NULL, NULL);
        }
        
        glyphOffset += runGlyphCount;
    }
    
    CGFloat diameter = radius * 2.f * M_PI;
    CGFloat compensatingSpacingFactor = radius < 50.f ? 1.f + (1.f - radius / 50.f) / 2.f : 1.f;
    
    CGFloat maxAngle;
    
    CGFloat prevHalfWidth = glyphArcInfo[0].width / 2.0;
    // Compute the angle based on the diameter for correct spacing, and multiply by a compensating factor for additional spacing because rotated text tends to be too collapsed
    glyphArcInfo[0].angle = (prevHalfWidth / diameter) * compensatingSpacingFactor * M_PI * 2.f;
    
    maxAngle = glyphArcInfo[0].angle;
    
    // Divide the arc into slices such that each one covers the distance from one glyph's center to the next.
    CFIndex lineGlyphIndex = 1;
    for (; lineGlyphIndex < glyphCount; lineGlyphIndex++)
    {
        CGFloat halfWidth = glyphArcInfo[lineGlyphIndex].width / 2.0;
        CGFloat prevCenterToCenter = prevHalfWidth + halfWidth;
        
        glyphArcInfo[lineGlyphIndex].angle = (prevCenterToCenter / diameter) * compensatingSpacingFactor * M_PI * 2.f;
        maxAngle += glyphArcInfo[lineGlyphIndex].angle;
        
        prevHalfWidth = halfWidth;
    }
    
    glyphArcInfo[0].angle += (M_PI - maxAngle) / 2.f;
}

- (void)drawRect:(CGRect)rect
{
    if (!self.font || !self.text)
    {
        // Nothing to do :-(
        
        return;
    }
    
    CGFloat radius = ABS(self.radius);
    
    if (radius <= 0.f) return; // Or else, CTRunDraw will throw a SIGABRT
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Setup general affine transform
    
    CGAffineTransform t0 = CGContextGetCTM(context);
    
    CGFloat xScaleFactor = t0.a > 0.f ? t0.a : -t0.a;
    CGFloat yScaleFactor = t0.d > 0.f ? t0.d : -t0.d;
    t0 = CGAffineTransformInvert(t0);
    if (xScaleFactor != 1.f || yScaleFactor != 1.f)
    {
        t0 = CGAffineTransformScale(t0, xScaleFactor, yScaleFactor);
    }
    
    CGContextConcatCTM(context, t0);
    
    // Reset affine transform for text
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    CFAttributedStringRef attributedStringRef = (__bridge CFAttributedStringRef)self.attributedText;
    CTLineRef line = CTLineCreateWithAttributedString(attributedStringRef);
    
    CFIndex glyphCount = CTLineGetGlyphCount(line);
    if (glyphCount == 0)
    {
        CFRelease(line);
        return;
    }
    
    GlyphArcInfo *glyphArcInfo = (GlyphArcInfo*)calloc(glyphCount, sizeof(GlyphArcInfo));
    PrepareGlyphArcInfo(radius, line, glyphCount, glyphArcInfo);
    
    // Move the origin to the center of the view so the text can run around.
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    // Rotate the context 90 degrees counterclockwise.
    CGContextRotateCTM(context, (self.rotation + 90.f) * (M_PI / 180.f));
    
    /*
     Now for the actual drawing. The angle offset for each glyph relative to the previous glyph has already been calculated; with that information in hand, draw those glyphs overstruck and centered over one another, making sure to rotate the context after each glyph so the glyphs are spread along a semicircular path.
     */
    CGPoint textPosition = CGPointMake(0.f, self.textInside ? -radius : radius);
    CGContextSetTextPosition(context, textPosition.x, textPosition.y);
    
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    CFIndex runCount = CFArrayGetCount(runArray);
    
    CFIndex glyphOffset = 0;
    CFIndex runIndex = 0;
    for (; runIndex < runCount; runIndex++)
    {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CFIndex runGlyphCount = CTRunGetGlyphCount(run);
        
        CFIndex runGlyphIndex = 0;
        CGFloat glyphAngle;
        for (; runGlyphIndex < runGlyphCount; runGlyphIndex++)
        {
            CFRange glyphRange = CFRangeMake(runGlyphIndex, 1);
            glyphAngle = (glyphArcInfo[runGlyphIndex + glyphOffset].angle);
            if (!self.textInside)
            {
                glyphAngle = -glyphAngle;
            }
            CGContextRotateCTM(context, glyphAngle);
            
            // Center this glyph by moving left by half its width.
            CGFloat glyphWidth = glyphArcInfo[runGlyphIndex + glyphOffset].width;
            CGFloat halfGlyphWidth = glyphWidth / 2.0;
            CGPoint positionForThisGlyph = CGPointMake(textPosition.x - halfGlyphWidth, textPosition.y);
            
            // Glyphs are positioned relative to the text position for the line, so offset text position leftwards by this glyph's width in preparation for the next glyph.
            textPosition.x -= glyphWidth;
            
            CGAffineTransform textMatrix = CTRunGetTextMatrix(run);
            textMatrix.tx = positionForThisGlyph.x;
            textMatrix.ty = positionForThisGlyph.y;
            CGContextSetTextMatrix(context, textMatrix);
            
            CTRunDraw(run, context, glyphRange);
        }
        
        glyphOffset += runGlyphCount;
    }
    
    CGContextRestoreGState(context);
    
    free(glyphArcInfo);
    CFRelease(line);
}

@end
