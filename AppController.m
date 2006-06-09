#import "AppController.h"
#import "CTDocument.h"
#import "MCTWindowController.h"

#define useLog 1

@implementation AppController

- (NSArray *)URLsFromPaths:(NSArray *)filenames
{
	NSEnumerator *enumerator = [NSArray objectEnumerator];
	NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[filenames length]];
	NSString *aFilename;
	while (aFilename = [enumerator nextObject]) {
		[urls addObject:[NSURL fileURLWithPath:aFilename]];
	}
	return urls;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	unsigned int nFile = [filenames count];
	
	if (nFile > 1) {
		id mctWindow = [[MCTWindowController alloc] initWithWindowNibName:@"MCTWindow"];
		[mctWindow setupFileTable:[self URLsFromPaths:filenames]];
		[mctWindow showWindow:self];
	}
	else {
		[[NSDocumentController sharedDocumentController]
				openDocumentWithContentsOfFile:[filenames lastObject] display:YES];			
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *scriptPath = [bundle pathForResource:@"GetFinderSelection" ofType:@"scpt" inDirectory:@"Scripts"
		];
	//NSLog(scriptPath);
	NSURL *scriptURL = [NSURL fileURLWithPath:scriptPath];
	NSDictionary *errorDict = nil;
	NSAppleScript *getFinderSelection = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errorDict];
	NSAppleEventDescriptor *scriptResult = [getFinderSelection executeAndReturnError:&errorDict];
	if (errorDict != nil) {
#if useLog
		NSLog([errorDict description]);
#endif
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:
			[NSString stringWithFormat:@"AppleScript Error : %@",[errorDict objectForKey:NSAppleScriptErrorNumber]]
			];
		[alert setInformativeText:[errorDict objectForKey:NSAppleScriptErrorMessage]];
		[alert setAlertStyle:NSWarningAlertStyle];
		if ([alert runModal] == NSAlertFirstButtonReturn) {
		} 
		[alert release];
		return;
	}
	
	[getFinderSelection release];
	NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
	
	if ([scriptResult descriptorType] == typeAEList) {
		unsigned int nFile = [scriptResult numberOfItems];

		if (nFile > 1) {
			NSMutableArray *files = [NSMutableArray arrayWithCapacity:nFile];
			for (unsigned int i=1; i <= nFile; i++) {
				[files addObject:[NSURL fileURLWithPath:[[scriptResult descriptorAtIndex:i] stringValue]]];
			}
			id mctWindow = [[MCTWindowController alloc] initWithWindowNibName:@"MCTWindow"];
			[mctWindow setupFileTable:files];
			[mctWindow showWindow:self];
		}
		else {
			NSString *resultString = [[scriptResult descriptorAtIndex:1] stringValue];
			[documentController openDocumentWithContentsOfFile:resultString display:YES];			
		}
		
	}
	else {
		[documentController openDocument:self];
	}
	
	
	return;
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"start awakeFromNib in AppController");
#endif
	
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"FactorySetting" ofType:@"plist"];
	NSDictionary *defautlsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	//format and suffix
	[userDefaults registerDefaults:defautlsDict];	
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	//return YES;
	return NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
