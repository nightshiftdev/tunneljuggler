//
//  BackgroundUtils.m
//  TunnelJoggler
//
//  Created by pawel on 7/29/12.
//
//

#import "BackgroundUtils.h"

@implementation BackgroundUtils

+ (ccColor4F)randomBrightColor {
    while (true) {
        float requiredBrightness = 192;
        ccColor4B randomColor = 
        ccc4(arc4random() % 255,
             arc4random() % 255, 
             arc4random() % 255, 
             255);
        if (randomColor.r > requiredBrightness || 
            randomColor.g > requiredBrightness ||
            randomColor.b > requiredBrightness) {
            return ccc4FFromccc4B(randomColor);
        }        
    }
}

+(CCSprite *)spriteWithColor:(ccColor4F)bgColor textureSize:(float)textureSize {
    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:bgColor.r g:bgColor.g b:bgColor.b a:bgColor.a];
    
    // 3: Draw into the texture
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    float gradientAlpha = 0.1;    
    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;
    
    float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
        
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ||
        IS_IPHONE_5) {
        noise = [CCSprite spriteWithFile:@"Noise_ipad.png"];
    }
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    noise.position = ccp(textureSize/2, textureSize/2);
    [noise visit];
    
    // 4: Call CCRenderTexture:end
    [rt end];
    
    // 5: Create a new Sprite from the texture
    return [CCSprite spriteWithTexture:rt.sprite.texture];
}

+(CCSprite *)stripedSpriteWithColor1:(ccColor4F)c1 color2:(ccColor4F)c2 textureSize:(float)textureSize  stripes:(int)nStripes {
    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:c1.r g:c1.g b:c1.b a:c1.a];
    
    // 3: Draw into the texture    
    
    // Layer 1: Stripes
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
    CGPoint vertices[nStripes*6];
    
    float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
    
    int nVertices = 0;
    float x1 = -textureSize * screenFactor;
    float x2;
    float y1 = textureSize * screenFactor;
    float y2 = 0;
    float dx = (textureSize / nStripes * 2) * screenFactor;
    float stripeWidth = dx/2;
    
    for (int i=0; i<nStripes; i++) {
        x2 = (x1 + textureSize) * screenFactor;
        vertices[nVertices++] = CGPointMake(x1, y1);
        vertices[nVertices++] = CGPointMake((x1+stripeWidth), y1);
        vertices[nVertices++] = CGPointMake(x2, y2);
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = CGPointMake((x2+stripeWidth), y2);
        x1 += dx;
    }
    
    glColor4f(c2.r, c2.g, c2.b, c2.a);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
    
    // layer 2: gradient
    glEnableClientState(GL_COLOR_ARRAY);
    
    float gradientAlpha = 0.6;    
    ccColor4F colors[4];
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    // layer 3: top highlight
    float borderWidth = textureSize/16;
    float borderAlpha = 0.5f;//screenFactor;
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    
    vertices[nVertices] = CGPointMake(0, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, borderWidth * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
    
    // Layer 2: Noise    
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ||
        IS_IPHONE_5) {
        noise = [CCSprite spriteWithFile:@"Noise_ipad.png"];
    }
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    noise.position = ccp(textureSize/2, textureSize/2);
    [noise visit];        
    
    // 4: Call CCRenderTexture:end
    [rt end];
    
    // 5: Create a new Sprite from the texture
    return [CCSprite spriteWithTexture:rt.sprite.texture];
}

+ (CCSprite *)genBackground {
    static ccColor4F color1;
    static ccColor4F color2;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        color1 = [BackgroundUtils randomBrightColor];
        color2 = [BackgroundUtils randomBrightColor];
    });
    float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
    float textureSize = 512;
    if (IS_IPHONE_5) {
        textureSize = 570;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        textureSize = 1024;
    }
    CCSprite *stripes = [BackgroundUtils stripedSpriteWithColor1:color1 color2:color2 textureSize:textureSize stripes: 12 * screenFactor];
    ccTexParams tp2 = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [stripes.texture setTexParameters:&tp2];
    return stripes;
}

@end
