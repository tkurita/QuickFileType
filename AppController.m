#import "AppController.h"
#import "CTDocument.h"
#import "MCTWindowController.h"
#import "UtilityFunctions.h"
#import <DonationReminder/DonationReminder.h>

#define useLog 0

static BOOL isFirstOpen = YES;

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
#if useLog
	NSLog([NSString stringWithFormat:@"start openFiles for :%@",[filenames description]]);
#endif	
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
	
	isFirstOpen = NO;
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)openFinderSelection
{
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *scriptPath = [bundle pathForResource:@"GetFinderSelection" ofType:@"scpt" inDirectory:@"Scripts"
		];

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
	
	if (isFirstOpen) [self openFinderSelection];
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

	[userDefaults registerDefaults:defautlsDict];	
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

/* method for service menu */
- (void)openForServices:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	NSArray *types = [pboard types];
	NSArray *file_names;
	if (![types containsObject:NSFilenamesPboardType] 
			|| !(file_names = [pboard propertyListForType:NSFilenamesPboardType])) {
        *error = NSLocalizedString(@"Error: Pasteboard doesn't contain file paths.",
                   @"Pasteboard couldn't give string.");
        return;
    }
	
	NSMutableArray *target_files = [NSMutableArray array];
	NSFileManager *file_manager = [NSFileManager defaultManager];
	NSEnumerator *enumerator = [file_names objectEnumerator];
	NSString *a_path;
	NSDictionary *a_dict;
	while (a_path = [enumerator nextObject]) {
		a_dict = [file_manager fileAttributesAtPath:a_path traverseLink:YES];
		if ([[a_dict objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
			[target_files addObject:[NSURL fileURLWithPath:a_path]];
		}
	}
	
	NSDocumentController *document_controller = [NSDocumentController sharedDocumentController];
	id mctWindow;
	switch ([target_files count]) {
		case 0 :
			[document_controller openDocument:self];
			break;
		case 1 :
			[document_controller openDocumentWithContentsOfURL:[target_files lastObject] display:YES error:nil];
			break;
		default:
			mctWindow = [[MCTWindowController alloc] initWithWindowNibName:@"MCTWindow"];
			[mctWindow setupFileTable:target_files];
			[mctWindow showWindow:self];
			break;			
	}
	//[NSApp activateIgnoringOtherApps:YES];
}

@end
