#import "FlipView.h"

@implementation FlipView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
}

- (BOOL)isFlipped
{
	return YES;
}

@end
