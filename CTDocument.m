#import "CTDocument.h"
#import "HFSTypeUtils.h"
#import "BoolToStringTransformer.h"
#import "UtilityFunctions.h"
#import "AltActionButton.h"
#import "NDResourceFork.h"
#import "NSString+NDCarbonUtilities.h"

#include <unistd.h>

#define useLog 0

@implementation CTDocument

#pragma mark init and dealloc

+ (void)initialize
{	
	NSValueTransformer *transformer = [[[BoolToStringTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"BoolToString"];
}

- (void)dealloc {
	[_creatorCode release];
	[_typeCode release];
	[_currentKind release];
	[_currentUTI release];
	[_currentAppPath release];
	[_currentAppIcon release];
	
	[_iconImg release];
	
	[_originalCreatorCode release];
	[_originalTypeCode release];
	[_originalExtension release];
	[_originalKind release];
	[_originalUTI release];
	[_originalAppPath release];
	[_originalAppIcon release];
	
	[super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
		_isCollapsed = NO;
		finderFlags = 0;
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}

- (void)awakeFromNib
{
#if useLog
	NSLog(@"start awakeFromNib in CTDocument");
#endif
	_typeTableController = [[TypeTableController alloc] initWithNibName:@"TypeTableView" owner:self];
	[typeTableBox setContentView:[_typeTableController view]];
	[_typeTableController setApplyTemplate:@selector(applyTypeTemplate:)];
#if useLog
	NSLog(@"end awakeFromNib in CTDocument");
#endif	
}

#pragma mark others
- (void)doDoubleAction:(id)sender
{
	[self applyTypeTemplate:sender];
	[self performSelector:_defaultAction withObject:sender];
}

- (BOOL)hasWritePermission {
	int permission = access([[self fileName] fileSystemRepresentation], W_OK);
	return (permission == 0);
}

- (BOOL)applyTypesReturningError:(NSError **)error
{
	BOOL result = NO;
	if (finderFlags || ![_typeCode isEqualToString:_originalTypeCode] || ![_creatorCode isEqualToString:_originalCreatorCode]) {
		result = [[[self fileURL] path] setFinderInfoFlags:0 mask:finderFlags 
											 type:UTGetOSTypeFromString((CFStringRef)_typeCode)
										  creator:UTGetOSTypeFromString((CFStringRef)_creatorCode)];
	} else {
		goto bail;
	}
	
	if (!result) {
		NSString *reason;
		if ([[originalAttributes objectForKey:NSFileImmutable] boolValue]) { 
			reason = @"The file is locked.";
			
		}else if (![self hasWritePermission] ) {
			reason = @"No permission.";
			
		}else {
			reason = @"Unknown";
		}
		/*
		NSException *exception = [NSException exceptionWithName:@"ApplyTypesException"
							reason:reason userInfo:nil];
		@throw exception;
		*/
		*error = [NSError errorWithDomain:@"QuickFileTypeErrorDomain" code:0 
					 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(reason, @"")
											  forKey:NSLocalizedDescriptionKey]];
	}

bail:
	return result;
}
/*
- (BOOL)applyTypesFromDict:(NSDictionary *)typeDict
{
	[self setCreatorCode:[typeDict objectForKey:@"creatorCode"]];
	[self setTypeCode:[typeDict objectForKey:@"typeCode"]];	
	return [self applyTypes];
}
*/

- (BOOL)setOriginalTypesFromFile:(NSString *)path //obsolute
{
	NSFileManager *file_manager = [NSFileManager defaultManager];
	NSDictionary *attInfo = [file_manager fileAttributesAtPath:path traverseLink:YES];
	if (![[attInfo objectForKey:NSFileType] isEqualTo:NSFileTypeRegular]) return NO;
	
	[self setOriginalCreatorCode: OSTypeToNSString([attInfo objectForKey:NSFileHFSCreatorCode])];
	[self setOriginalTypeCode: OSTypeToNSString([attInfo objectForKey:NSFileHFSTypeCode])];
	return YES;
}

- (BOOL)setTypesFromFile:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *attInfo = [fileManager fileAttributesAtPath:path traverseLink:YES];
	if (![[attInfo objectForKey:NSFileType] isEqualTo:NSFileTypeRegular]) return NO;
		
	[self setCreatorCode: OSTypeToNSString([attInfo objectForKey:NSFileHFSCreatorCode])];
	[self setTypeCode: OSTypeToNSString([attInfo objectForKey:NSFileHFSTypeCode])];
	return YES;
}

- (void)applyTypeTemplate:(id)sender
{
	id selection = [_typeTableController selectedTypes];
	if (selection == nil) return;
	
	[self setCreatorCode:[selection objectForKey:@"creatorCode"]];
	[self setTypeCode:[selection objectForKey:@"typeCode"]];		
}

- (void)updateCurrentKind
{
	NSString *kindString = nil;
	OSStatus err = LSCopyKindStringForTypeInfo(UTGetOSTypeFromString((CFStringRef)_typeCode),
											UTGetOSTypeFromString((CFStringRef)_creatorCode),
											(CFStringRef)_originalExtension,
											   (CFStringRef *)&kindString);

	if (err != noErr) {
		NSLog(@"Error in updateCurrentKind. error : %i", err);
		return;
	}
	
	[_currentKind release];
	_currentKind = kindString;
}

- (void)updateCurrentUTITips
{
	if (!currentUTIColor || [currentUTIColor isEqualTo:[NSColor blackColor]]) {
		[self setCurrentUTITips:NSLocalizedString(@"This UTI is determined by the type code.", @"")];
	} else {
		[self setCurrentUTITips:NSLocalizedString(@"This UTI for the type code conflicts with the UTI for the extension.", @"")];
	}
}

- (void)updateCurrentUTI
{
	if (_ignoringCreatorForExtension || _ignoringCreatorForUTI) return;
	
	NSString *uti;
	if (! (uti = getUTIFromTags(_typeCode, _originalExtension))) return;
	
	if (UTTypeConformsTo((CFStringRef)uti, (CFStringRef)_originalUTI) || UTTypeConformsTo((CFStringRef)_originalUTI, (CFStringRef)uti)) {
		[self setCurrentUTIColor:[NSColor blackColor]];
	} else {
		[self setCurrentUTIColor:[NSColor redColor]];
	}
	
	[self setCurrentUTI:uti];
	
	LSHandlerOptions handlerOption = LSGetHandlerOptionsForContentType((CFStringRef)_currentUTI);
	_ignoringCreatorForUTI = (handlerOption == kLSHandlerOptionsIgnoreCreator);
	[self updateCurrentUTITips];
}

- (void)updateCurrentApp
{
	NSURL *outAppURL = nil;
	OSStatus err = LSGetApplicationForInfo(UTGetOSTypeFromString((CFStringRef)_typeCode),
											 UTGetOSTypeFromString((CFStringRef)_creatorCode),
											 (CFStringRef)_originalExtension,
											 kLSRolesAll,
											 NULL,
											 (CFURLRef *)&outAppURL);
	if (err != noErr) {
		NSLog(@"Error in updateCurrentApp. error : %i", err);
		return;
	}
	
	NSString *appPath = [outAppURL path];
	if (![appPath isEqualToString:_currentAppPath]) {
		[self setCurrentAppPath: [outAppURL path]];
		[self setCurrentAppIcon:convertImageSize([[NSWorkspace sharedWorkspace] iconForFile:appPath], 16)];
	}
}

- (void) saveTypeHistory
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *creatorHistory = [userDefaults objectForKey:@"CreatorHistory"];
	NSMutableArray *typeHistory = [userDefaults objectForKey:@"TypeHistory"];
	
	unsigned int historyMax = [[userDefaults objectForKey:@"HistoryMax"] unsignedIntValue];
	if ((_creatorCode != nil) && (![_creatorCode isEqualToString:@""])) {
		if (![creatorHistory containsObject:_creatorCode]) {
			creatorHistory = [creatorHistory mutableCopy];
			[creatorHistory insertObject:_creatorCode atIndex:0];
			if ([creatorHistory count] > historyMax) {
				[creatorHistory removeLastObject];
			}
			[userDefaults setObject:creatorHistory forKey:@"CreatorHistory"];
		}
	}
	
	if ((_typeCode != nil)  && (![_typeCode isEqualToString:@""])) {
		if (![typeHistory containsObject:_typeCode]) {
			typeHistory = [typeHistory mutableCopy];
			[typeHistory insertObject:_typeCode atIndex:0];
			if ([typeHistory count] > historyMax) {
				[typeHistory removeLastObject];
			}				
			[userDefaults setObject:typeHistory forKey:@"TypeHistory"];
		}
	}
}

- (void)setupNextKeyView:(NSWindow *)aWindow
{
#if useLog
	NSLog(@"start setupNextKeyView");
#endif
	NSView *a_view = [[_typeTableController favoritesTableView] superview];	
	[typePopup setNextKeyView:a_view];
	[a_view setNextKeyView:creatorPopup];
	[aWindow makeFirstResponder:a_view];
}

- (BOOL)shouldRespectCreatorForUTI:(NSString *)uti
{
	return YES;
}

- (void)processApplyTypes;
{	
	NSError *error = nil;
	[self applyTypesReturningError:&error];
	[modalDelegate didEndApplyTypesForDoc:self error:error];
	/*
	 @try {
	 result = [self applyTypesWithError:&error];
	 }
	 @catch (NSException *exception) {
	 if (! [[exception name] isEqualToString:@"ApplyTypesException"] ) {       
	 @throw;
	 }
	 
	 NSBeginAlertSheet(
	 NSLocalizedString(@"Can't change creator and type.",
	 @"Alert when can't apply types of single mode"),	// sheet message
	 @"OK",					// default button label
	 nil,					// no third button
	 nil,					// other button label
	 [self windowForSheet],		// window sheet is attached to
	 self,                   // we’ll be our own delegate
	 nil,					// did-end selector
	 nil,                   // no need for did-dismiss selector
	 nil,					// context info
	 NSLocalizedString([exception reason],
	 @"The reason not to be able to apply types"));		// additional text
	 return;
	 }
	 
	 if (result) {
	 [self saveTypeHistory];
	 if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultButton"] isEqualToString:@"Open"]) {
	 [[NSWorkspace sharedWorkspace] openURL:[self fileURL]];
	 }
	 }
	 [self close];
	 [[NSNotificationCenter defaultCenter] postNotificationName:@"CTDocumentCloseNotification" 
	 object:self userInfo:nil];
	 */
}

- (void)performApplyTypes
{
	NSMutableString* msg = [NSMutableString string];
	if (_ignoringCreatorForExtension && [modalDelegate shouldRespectCreatorForUTI:_originalUTI]) {
		[msg appendFormat: NSLocalizedString(@"The extension \"%@\" will respect creator code.",
											 @""), _originalExtension];
		enableCreator = YES;
	} else {
		enableCreator = NO;
	}
	
	if (hasUsroResource) {
		if (_ignoringCreatorForExtension) [msg appendString:@"\n\n"];
		[msg appendString:NSLocalizedString(@"'usro' resource will be removed.", @"")];
	}
	
	if ([msg length]) {
		NSBeginAlertSheet(
			  [NSString stringWithFormat:
				   NSLocalizedString(@"\"%@\" is ignoring creator code.\n Do you make creator code enable ?", @""),
								 [[[self fileURL] path] lastPathComponent] ],	// sheet message
			  nil,					// default button label
			  nil,					// no third button
			  NSLocalizedString(@"Cancel", "Cancel button label"),	// other button label
			  [modalDelegate windowForSheet],	// window sheet is attached to
			  self,                   // we’ll be our own delegate
			  @selector(sheetDidEnd:returnCode:contextInfo:),	// did-end selector
			  nil,                   // no need for did-dismiss selector
			  nil,					// context info
			  msg);		// additional text
	} else {
	 [self processApplyTypes];
	}
}

- (void)didEndApplyTypesForDoc:(CTDocument *)doc error:(NSError *)error
{
	if (error) {
		[self presentError:error
			modalForWindow:[self windowForSheet]
			delegate:nil didPresentSelector:nil contextInfo:nil];
		return;
	}
	
	[self saveTypeHistory];
	if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultButton"] isEqualToString:@"Open"]) {
		[[NSWorkspace sharedWorkspace] openURL:[self fileURL]];
	}

	[self close];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CTDocumentCloseNotification" 
														object:self userInfo:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		if (enableCreator) {
			OSStatus err = LSSetHandlerOptionsForContentType((CFStringRef)_originalUTI, 
															 kLSHandlerOptionsDefault);
			if (err != noErr) {
				NSLog(@"Error in LSSetHandlerOptionsForContentType. error : %i", err);
			}
		}
		
		if (hasUsroResource) {
			NDResourceFork* resfolk = [[NDResourceFork alloc] initForWritingAtURL:[self fileURL]];
			if (resfolk) {
				if (![resfolk removeType:'usro' Id:0]) {
					NSLog(@"Fail to remove 'usro' resource");
				}
				if (![resfolk removeType:'icns' Id:-16455]) {
					NSLog(@"Fail to remove 'icns' resource");
				}				
			} else {
				NSLog(@"Fail to open resource folk");
			}
			[resfolk release];
			finderFlags = kHasCustomIcon;			
		}
	}
bail:
	[self processApplyTypes];
}

- (void)applyTypesWithModalDelegate:(id<ApplyTypesProtocol>)delegate
{
	modalDelegate = delegate;
	[self performApplyTypes];	
}

- (void)applyTypeDict:(NSDictionary *)typeDict modalDelegate:(id<ApplyTypesProtocol>)delegate
{
	[self setCreatorCode:[typeDict objectForKey:@"creatorCode"]];
	[self setTypeCode:[typeDict objectForKey:@"typeCode"]];	
	[self applyTypesWithModalDelegate:delegate];
}

#pragma mark accessors for current values
- (void)setCurrentUTITips:(NSString *)tips
{
	[tips retain];
	[currentUTITips release];
	currentUTITips = tips;
}

- (NSString *)currentUTITips
{
	return currentUTITips;
}

- (void)setCurrentUTIColor:(NSColor *)color
{
	[color retain];
	[currentUTIColor release];
	currentUTIColor = color;
}

- (NSColor *)currentUTIColor
{
	return currentUTIColor;
}

- (void)setIconImg:(NSImage *)iconImg
{
	[iconImg retain];
	[_iconImg release];
	_iconImg = iconImg;
}

- (NSImage *)iconImg16
{
	return convertImageSize(_iconImg, 16);
}

- (NSImage *)iconImg
{
	return _iconImg;
}

- (NSString *)currentKind
{
	return _currentKind;
}

- (void)setTypeCode:(NSString *)typeCode
{
	[typeCode retain];
	[_typeCode release];
	_typeCode = typeCode;
	[self updateCurrentKind];
	[self updateCurrentUTI];
	[self updateCurrentApp];
}

- (NSString *)typeCode
{
	return _typeCode;
}

- (void)setCreatorCode:(NSString *)creatorCode
{
	[creatorCode retain];
	[_creatorCode release];
	_creatorCode = creatorCode;
	[self updateCurrentKind];
	[self updateCurrentApp];
}

- (NSString *)creatorCode
{
	return _creatorCode;
}

- (void)setCurrentUTI:(NSString *)uti
{
#if useLog
	NSLog(@"start setCurrentUTI : %@", uti);
#endif
	[uti retain];
	[_currentUTI release];
	_currentUTI = uti;
}

- (NSString *)currentUTI
{
	return _currentUTI;
}

- (void)setCurrentAppIcon:(NSImage *)iconImage
{
	[iconImage retain];
	[_currentAppIcon release];
	_currentAppIcon = iconImage;
}

- (NSImage *)currentAppIcon
{
	return _currentAppIcon;
}

- (void)setCurrentAppPath:(NSString *)path
{
	[path retain];
	[_currentAppPath release];
	_currentAppPath = path;
}

- (id) ignoringCreatorForUTI
{
	return [NSNumber numberWithBool:_ignoringCreatorForUTI];
}

- (id)ignoringCreatorForExtension
{
	return [NSNumber numberWithBool:_ignoringCreatorForExtension];
}

#pragma mark accessors for original values
- (BOOL)storeAttributesForFile:(NSString *)path
{
	NSFileManager *file_manager = [NSFileManager defaultManager];
	NSDictionary *att_info = [file_manager fileAttributesAtPath:path traverseLink:YES];
	if (![[att_info objectForKey:NSFileType] isEqualTo:NSFileTypeRegular]) return NO;
	
	[originalAttributes release];
	originalAttributes = [att_info retain];
	
	[self setOriginalCreatorCode: OSTypeToNSString([att_info objectForKey:NSFileHFSCreatorCode])];
	[self setOriginalTypeCode: OSTypeToNSString([att_info objectForKey:NSFileHFSTypeCode])];
	return YES;
}

- (void)setOriginalTypeCode:(NSString *)theType
{
	[theType retain];
	[_originalTypeCode release];
	_originalTypeCode = theType;
}

- (NSString *)originalTypeCode
{
	return _originalTypeCode;
}

- (void)setOriginalCreatorCode:(NSString *)theType
{
	[theType retain];
	[_originalCreatorCode release];
	_originalCreatorCode = theType;
}

- (NSString *)originalCreatorCode
{
	return _originalCreatorCode;
}

- (void)setOriginalKind:(NSString *)kind
{
	[kind retain];
	[_originalKind release];
	_originalKind = kind;
}

- (NSString *)originalKind
{
	return _originalKind;
}

- (void)setOriginalUTI:(NSString *)uti
{
	[uti retain];
	[_originalUTI release];
	_originalUTI = uti;
}

- (NSString *)originalUTI
{
	return _originalUTI;
}

- (NSString *)originalAppPath
{
	return _originalAppPath;
}

- (NSImage *)originalAppIcon
{
	return _originalAppIcon;
}

- (void)setOriginalExtension:(NSString *)extensionString
{
	[extensionString retain];
	[_originalExtension release];
	_originalExtension = extensionString;
}

- (NSString *)originalExtension
{
	return _originalExtension;
}

#pragma mark delegate of NSWindow
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	if (_isCollapsed) {
		NSRect currentRect = [sender frame];
		return currentRect.size;
	}
	else {
		return proposedFrameSize;
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start windowWillClose in CTDocument");
#endif
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:([infoDrawer state] == NSDrawerOpenState) forKey:@"IsOpenInfoDrawer"];
	[userDefaults setInteger:[collapseButton state] forKey:@"TableCollapseState"];
	[[aNotification object] saveFrameUsingName:_frameName];
	if (_isCollapsed) {
		[userDefaults setObject:NSStringFromRect(_typeBoxFrame) forKey:@"TypeBoxFrame"];
	}
	[_typeTableController saveSettings];
	[userDefaults synchronize]; //window を閉じずに終了した時に必要
}

#pragma mark override NSDocument
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"CTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
#if useLog
	NSLog(@"start windowControllerDidLoadNib");
#endif
	[super windowControllerDidLoadNib:aController];

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSWindow *aWindow = [aController window];
	// setup type box status
	[collapseButton setState: [userDefaults integerForKey:@"TableCollapseState"]];
	if ([collapseButton state] == NSOffState) {
		[self collapseTypeTableBox:self];
		_typeBoxFrame = NSRectFromString([userDefaults objectForKey:@"TypeBoxFrame"]);
	}
	else {
		[self setupNextKeyView:[aController window]];
	}

	// setup drawer status
	if ([userDefaults boolForKey:@"IsOpenInfoDrawer"]) {
		[infoDrawer open:self];
	}
	
	// setup window size
	_frameName = @"CTDocumentWindow";
	[aWindow center];
	[aWindow setFrameUsingName:_frameName];

	//setup default button
	NSString *defaultButtonName = [userDefaults stringForKey:@"DefaultButton"];
	if ([defaultButtonName isEqualToString:@"Open"]) {
		[okButton setKeyEquivalent:@""];
		[okButton setAltButton:YES];
		[okButton setKeyEquivalentModifierMask:0];
		[openButton setKeyEquivalent:@"\r"];
		_defaultAction = @selector(openAction:);
	}
	else {
		[openButton setAltButton:YES];
		_defaultAction = @selector(okAction:);
	}
	
	[_typeTableController setDoubleAction:@selector(doDoubleAction:)];
	
#if useLog
	NSLog(@"end windowControllerDidLoadNib");
#endif
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    
    // For applications targeted for Tiger or later systems, you should use the new Tiger API -dataOfType:error:.  In this case you can also choose to override -writeToURL:ofType:error:, -fileWrapperOfType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    return nil;
}

- (BOOL)readFromFile:(NSString *)absolutePath ofType:(NSString *)typeName
{
	NSURL *fURL = [self fileURL];
	OSStatus err;
	
	//setup document icon image
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	[self setIconImg:[workspace iconForFile:absolutePath]];
	
	//setup original fileTypes
	if (![self storeAttributesForFile:absolutePath]) return NO;
	
	//setup original kind
	NSString *kindString = nil;
	err = LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:absolutePath], (CFStringRef *)&kindString);
	[self setOriginalKind:[kindString autorelease]];
	
	//setup original extension;
	[self setOriginalExtension:[absolutePath pathExtension]];
	
	//setup original UTI
	FSRef fileRef;
	CFURLGetFSRef((CFURLRef)fURL, &fileRef);
	NSString *theUTI = nil;
	err = LSCopyItemAttribute(&fileRef, kLSRolesAll, kLSItemContentType, (CFTypeRef *)&theUTI );
	[self setOriginalUTI:theUTI];
	LSHandlerOptions handlerOption = LSGetHandlerOptionsForContentType((CFStringRef)_originalUTI);
	_ignoringCreatorForExtension = (handlerOption == kLSHandlerOptionsIgnoreCreator);
	_ignoringCreatorForUTI = _ignoringCreatorForExtension;
	[self setCurrentUTI:_originalUTI];
	[self setCurrentUTIColor:[NSColor blackColor]];
	[self updateCurrentUTITips];
	
	//setup default application path
	NSURL *appURL = nil;
	err = LSGetApplicationForURL((CFURLRef)fURL, kLSRolesAll, NULL, (CFURLRef *)&appURL);
	_originalAppPath = [[appURL path] retain];
	_originalAppIcon = [convertImageSize([workspace iconForFile:_originalAppPath], 16) retain];
	
	//setup current file type & creator type
	[self setCreatorCode: _originalCreatorCode];
	[self setTypeCode: _originalTypeCode];
	
	//resource fork
	hasUsroResource = NO;
	NDResourceFork* resfork = [NDResourceFork resourceForkForReadingAtPath:absolutePath];	
	if (resfork) {
		if ([resfork nameOfResourceType:'usro' Id:0]) {
			hasUsroResource = YES;
		}
	}
	
    return YES;
}

#pragma mark actions
- (IBAction)collapseTypeTableBox:(id)sender;
{
	NSWindow *window = [[[self windowControllers] objectAtIndex:0] window];
	NSRect windowFrame = [window frame];
	if (! _isCollapsed){
		NSTableView *favorites_table = [_typeTableController favoritesTableView];
		
		if ([[window firstResponder] isEqual:favorites_table]) {
			[window selectNextKeyView:[favorites_table superview]];
		}
		[[favorites_table superview] setNextKeyView:nil];
		[typePopup setNextKeyView:creatorPopup];
		_typeBoxFrame = [typeTableBox frame];
		windowFrame.origin.y = windowFrame.origin.y + NSHeight(_typeBoxFrame);
		windowFrame.size.height = NSHeight(windowFrame) - NSHeight(_typeBoxFrame);
		[typeTableBox setContentView:nil];
		[window setFrame:windowFrame display:YES animate:YES];
		
		_isCollapsed = YES;
	}
	else {
		windowFrame.origin.y = windowFrame.origin.y - NSHeight(_typeBoxFrame);
		windowFrame.size.height = NSHeight(windowFrame) + NSHeight(_typeBoxFrame);
		[window setFrame:windowFrame display:YES animate:YES];
		[typeTableBox setContentView:[_typeTableController view]];
		[self setupNextKeyView:window];
		_isCollapsed = NO;
	}
}

- (IBAction)revert:(id)sender
{
	[self setCreatorCode:_originalCreatorCode];
	[self setTypeCode:_originalTypeCode];
}

- (IBAction)cancelAction:(id)sendcer
{
	[self close];
}


- (IBAction)okAction:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:@"OK" forKey:@"DefaultButton"];
	[self applyTypesWithModalDelegate:self];
}

- (IBAction)openAction:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:@"Open" forKey:@"DefaultButton"];
	modalDelegate = self;
	[self applyTypesWithModalDelegate:self];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *resultPath = [panel filename];
		[self setTypesFromFile:resultPath];
	}
}

- (IBAction)chooseFromFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel beginSheetForDirectory:nil 
								 file:nil
								types:nil
					   modalForWindow:[[[self windowControllers] lastObject] window]
						modalDelegate:self
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (IBAction)removeTypes:(id)sender
{
	[self setCreatorCode:nil];
	[self setTypeCode:nil];	
}
@end
