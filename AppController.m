#import "AppController.h"
#import "CTDocument.h"
#import "MCTWindowController.h"
#import "UtilityFunctions.h"
#import "DonationReminder.h"

#define useLog 1

NSArray *URLsFromPaths(NSArray *filenames)
{
	NSEnumerator *enumerator = [filenames objectEnumerator];
	NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[filenames count]];
	NSString *aFilename;
	while (aFilename = [enumerator nextObject]) {
		[urls addObject:[NSURL fileURLWithPath:aFilename]];
	}
	return urls;
}

@implementation AppController

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	unsigned int nFile = [filenames count];
	NSError *error = nil;
	
	if (nFile > 1) {
		id mctWindow = [[MCTWindowController alloc] initWithWindowNibName:@"MCTWindow"];
		[mctWindow setupFileTable:URLsFromPaths(filenames)];
		[mctWindow showWindow:self];
	}
	else {
		[[NSDocumentController sharedDocumentController]
				openDocumentWithContentsOfURL:[URLsFromPaths(filenames) lastObject] display:YES error:&error];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	//initialize type template icons
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if ([userDefaults boolForKey:@"NeedUpdateIcons"]) {
		NSMutableArray *typeTemplates = [[userDefaults objectForKey:@"FavoriteTypes"] mutableCopy];
		NSMutableDictionary *typeDict;
		NSImage *scaledIcon;
		NSImage *iconImage;
		for (unsigned i = 0; i < [typeTemplates count];  i++) {
			typeDict = [[typeTemplates objectAtIndex:i] mutableCopy];
			iconImage = iconForCreatorAndTypeString([typeDict objectForKey:@"creatorCode"], [typeDict objectForKey:@"typeCode"]);
			scaledIcon = convertImageSize(iconImage, 16);
			[typeDict setObject:[NSArchiver archivedDataWithRootObject:scaledIcon] forKey:@"icon16"];
			scaledIcon = convertImageSize(iconImage, 32);
			[typeDict setObject:[NSArchiver archivedDataWithRootObject:scaledIcon] forKey:@"icon32"];
			[typeTemplates replaceObjectAtIndex:i withObject:typeDict];
		}
		[userDefaults setObject:typeTemplates forKey:@"FavoriteTypes"];
		[userDefaults setBool:NO forKey:@"NeedUpdateIcons"];
	}
	
	//get finder's selection
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
	
	[DonationReminder remindDonation];
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
