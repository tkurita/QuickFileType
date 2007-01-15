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
			NSString *a_message = NSLocalizedString(@"%@ is not a file.", @"A message when a package is selected in open panel");
			[alert setMessageText:[NSString stringWithFormat:a_message, [[[urls lastObject] path] lastPathComponent] ]];
			a_message = NSLocalizedString(@"Directory does not have a type code and a creator code", @"Infomative text when a package is selected in open panel");
			[alert setInformativeText:a_message];
			[alert setAlertStyle:NSInformationalAlertStyle];
			[alert runModal];
			[alert release];
			urls = nil;
		}
	}
	return urls;
}

@end
