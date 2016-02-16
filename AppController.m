#import "AppController.h"
#import "CTDocument.h"
#import "MCTWindowController.h"
#import "UtilityFunctions.h"
#import "HFSTypeUtils.h"
#import "DonationReminder/DonationReminder.h"

#define useLog 0

static BOOL AUTO_QUIT = YES;
//static BOOL isFirstOpen = YES;

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
@synthesize itemsOpenWithCreator;

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
#if useLog
	NSLog([NSString stringWithFormat:@"start application:openFiles: for :%@",[filenames description]]);
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
	
	//isFirstOpen = NO;
#if useLog
	NSLog(@"end application:openFiles:");
#endif	
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)openFinderSelection
{
#if useLog
	NSLog(@"start openFinderSelection");
#endif	
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
		goto bail;
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
bail:
#if useLog
	NSLog(@"end openFinderSelection");
#endif
	return;
}

/*
- (void)delayedOpenFinderSelection
{
#if useLog
	NSLog(@"start delayedOpenFinderSelection");
#endif	
	if (isFirstOpen) [self openFinderSelection];
}
*/

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
	
	//[self performSelector:@selector(delayedOpenFinderSelection) withObject:nil afterDelay:0.3];
	NSAppleEventDescriptor *ev = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
#if useLog
	NSLog([ev description]);
#endif
	AEEventID evid = [ev eventID];
	BOOL should_process = NO;
	NSAppleEventDescriptor *propData;
	switch (evid) {
		case kAEOpenDocuments:
#if useLog			
			NSLog(@"kAEOpenDocuments");
#endif
			break;
		case kAEOpenApplication:
#if useLog			
			NSLog(@"kAEOpenApplication");
#endif
			propData = [ev paramDescriptorForKeyword: keyAEPropData];
			DescType type = propData ? [propData descriptorType] : typeNull;
			OSType value = 0;
			if(type == typeType) {
				value = [propData typeCodeValue];
				switch (value) {
					case keyAELaunchedAsLogInItem:
						AUTO_QUIT = NO;
						break;
					case keyAELaunchedAsServiceItem:
						break;
				}
			} else {
				should_process = YES;
			}
			break;
	}
	
	[DonationReminder remindDonation];
	
#if useLog
	NSLog(@"end applicationDidFinishLaunching");
#endif	
	return;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if (itemsOpenWithCreator) {
		for (NSDictionary *dict in itemsOpenWithCreator) {
			CFURLRef appurl = NULL;
			OSStatus err = LSGetApplicationForInfo (kLSUnknownType,
													UTGetOSTypeFromString((CFStringRef)[dict objectForKey:@"creator"]),
								NULL, kLSRolesAll, NULL, &appurl);
			if (err != noErr)
				 NSLog(@"Failed to LSGetApplicationForInfo with error :%d", err);
			if (appurl) {
				[[NSWorkspace sharedWorkspace] openFile:[dict objectForKey:@"path"] 
						withApplication:[(NSURL *)appurl path] andDeactivate:YES];
			}
		}
		self.itemsOpenWithCreator = nil;
	}
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
	[NSApp setServicesProvider:self];
#if useLog
	NSLog(@"end awakeFromNib");
#endif	
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
#if useLog
	NSLog(@"applicationOpenUntitledFile");
#endif	
	[self openFinderSelection];
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return AUTO_QUIT;
}

#pragma mark method for service menu
- (void)openWithCreator:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	//isFirstOpen = NO;
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
	NSString *creator = nil;
	self.itemsOpenWithCreator = [NSMutableArray array];
	while (a_path = [enumerator nextObject]) {
		a_dict = [file_manager fileAttributesAtPath:a_path traverseLink:YES];
		if ([[a_dict objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
			creator = OSTypeToNSString([a_dict objectForKey:NSFileHFSCreatorCode]);
			if ([creator length]) {
				NSDictionary *itemdict = [NSDictionary dictionaryWithObjectsAndKeys:
										  a_path, @"path", creator, @"creator", nil];
				[itemsOpenWithCreator addObject:itemdict];
			} else {
				[target_files addObject:[NSURL fileURLWithPath:a_path]];
			}
		} else {
			[[NSWorkspace sharedWorkspace] openFile:a_path];
		}
	}
	
	NSDocumentController *document_controller = [NSDocumentController sharedDocumentController];
	id mctWindow;
	switch ([target_files count]) {
		case 0 :
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
	return;
}

- (void)changeFileTypes:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	//isFirstOpen = NO;
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
}

@end
