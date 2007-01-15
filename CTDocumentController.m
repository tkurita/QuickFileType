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
	else {
		NSFileManager *file_manager = [NSFileManager defaultManager];
		NSDictionary *file_info = [file_manager fileAttributesAtPath:[[urls lastObject] path] traverseLink:YES];
		if (![[file_info objectForKey:NSFileType] isEqualTo:NSFileTypeRegular]) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:[NSString stringWithFormat:@"Can't open %@", [[urls lastObject] path]]];
			[alert setInformativeText:@"Directory does not have a type code and a creator code"];
			[alert setAlertStyle:NSInformationalAlertStyle];
			[alert runModal];
			[alert release];
			urls = nil;
		}
	}
	return urls;
}

@end
