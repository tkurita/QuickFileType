#import "CTDocumentController.h"
#import "MCTWindowController.h"


@implementation CTDocumentController
- (NSArray *)URLsFromRunningOpenPanel
{
	NSArray *urls = [super URLsFromRunningOpenPanel];
	if (! urls) return urls;
	
	if ([urls count] > 1) {
		id mctWindow = [[MCTWindowController alloc] initWithWindowNibName:@"MCTWindow"];
		[mctWindow setupFileTable:urls];
		[mctWindow showWindow:self];
		urls = nil;
	}
	return urls;
}

@end
