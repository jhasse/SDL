//
//  EAGLView.m
//  test2
//
//  Created by Holmes Futrell on 7/11/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//



#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "SDL_uikitopenglview.h"

// A class extension to declare private methods
@interface SDL_uikitopenglview (privateMethods)

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation SDL_uikitopenglview

@synthesize context;
// You must implement this
+ (Class)layerClass {
	return [CAEAGLLayer class];
}

/*
	stencilBits ignored.
	Right now iPhone stencil buffer doesn't appear supported.  Maybe it will be in the future ... who knows.
*/
- (id)initWithFrame:(CGRect)frame \
	  retainBacking:(BOOL)retained \
	  rBits:(int)rBits \
	  gBits:(int)gBits \
	  bBits:(int)bBits \
	  aBits:(int)aBits \
	  depthBits:(int)depthBits \
{
	
	NSString *colorFormat=nil;
	GLuint depthBufferFormat;
	BOOL useDepthBuffer;
	
	if (rBits == 8 && gBits == 8 && bBits == 8) {
		/* if user specifically requests rbg888 or some color format higher than 16bpp */
		colorFormat = kEAGLColorFormatRGBA8;
	}
	else {
		/* default case (faster) */
		colorFormat = kEAGLColorFormatRGB565;
	}
	
	if (depthBits == 24) {
		useDepthBuffer = YES;
		depthBufferFormat = GL_DEPTH_COMPONENT24_OES;
	}
	else if (depthBits == 0) {
		useDepthBuffer = NO;
	}
	else {
		/* default case when depth buffer is not disabled */
		/* 
		   strange, even when we use this, we seem to get a 24 bit depth buffer on iPhone.
		   perhaps that's the only depth format iPhone actually supports
		*/
		useDepthBuffer = YES;
		depthBufferFormat = GL_DEPTH_COMPONENT16_OES;
	}
	
	if ((self = [super initWithFrame:frame])) {
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool: retained], kEAGLDrawablePropertyRetainedBacking, colorFormat, kEAGLDrawablePropertyColorFormat, nil];
		
		context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES1];
		
		if (!context || ![EAGLContext setCurrentContext:context]) {
			[self release];
			return nil;
		}
		
		/* create the buffers */
		glGenFramebuffersOES(1, &viewFramebuffer);
		glGenRenderbuffersOES(1, &viewRenderbuffer);
		
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
		[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
		
		glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
		glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
		
		if (useDepthBuffer) {
			glGenRenderbuffersOES(1, &depthRenderbuffer);
			glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
			glRenderbufferStorageOES(GL_RENDERBUFFER_OES, depthBufferFormat, backingWidth, backingHeight);
			glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
		}
			
		if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
			NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
			return NO;
		}
		/* end create buffers */
		
		NSLog(@"Done initializing ...");
		
	}
	return self;
}

- (void)setCurrentContext {
	[EAGLContext setCurrentContext:context];
}


- (void)swapBuffers {
	
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	if (![context presentRenderbuffer:GL_RENDERBUFFER_OES]) {
		NSLog(@"Could not swap buffers");
	}
}


- (void)layoutSubviews {
	[EAGLContext setCurrentContext:context];
}

- (void)destroyFramebuffer {
	
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if (depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}


- (void)dealloc {
		
	[self destroyFramebuffer];
	if ([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	[context release];	
	[super dealloc];
	
}

@end