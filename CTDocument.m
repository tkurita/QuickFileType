#import "CTDocument.h"
#import "HFSTypeUtils.h"
#import "BoolToStringTransformer.h"
#import "UtilityFunctions.h"

#define useLog 1

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
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}

- (void)awakeFromNib
{
	_typeTableController = [[TypeTableController alloc] initWithNibName:@"TypeTableView" owner:self];
	[typeTableBox setContentView:[_typeTableController view]];
	[_typeTableController setApplyTemplate:@selector(applyTypeTemplate:)];
}

#pragma mark others
- (void)checkUserLaunchServiceSetting
{
	NSArray *userLSHandlers = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.LaunchServices"] objectForKey:@"LSHandlers"];
	if (userLSHandlers == nil) return;
	
	NSEnumerator *enumerator = [userLSHandlers objectEnumerator];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	id handlerEntry;
	while (handlerEntry = [enumerator nextObject]) {
		if ([[handlerEntry objectForKey:@"LSHandlerContentTagClass"] isEqualToString:@"public.filename-extension"]) {
			[dict setValue:handlerEntry forKey:[handlerEntry objectForKey:@"LSHandlerContentTag"]];
		}
	}
	
	[self setUserLSHandlersForExtensions:dict];
}

- (void)applyTypes
{
	NSMutableDictionary *attDict = [NSMutableDictionary dictionary];
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	if (![_typeCode isEqualToString:_originalTypeCode]) {
		[attDict setObject:StringToOSType(_typeCode) forKey:NSFileHFSTypeCode];
	}
	if (![_creatorCode isEqualToString:_originalCreatorCode]) {
		[attDict setObject:StringToOSType(_creatorCode) forKey:NSFileHFSCreatorCode];
	}
	if ([attDict count] > 0)
		[fileManager changeFileAttributes:attDict atPath:[self fileName]];	
}

- (void)applyTypesFromDict:(NSDictionary *)typeDict
{
	[self setCreatorCode:[typeDict objectForKey:@"creatorCode"]];
	[self setTypeCode:[typeDict objectForKey:@"typeCode"]];	
	[self applyTypes];
}

- (BOOL)setOriginalTypesFromFile:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *attInfo = [fileManager fileAttributesAtPath:path traverseLink:YES];
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
	id selection = [_typeTableController getSelection];
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
//	OSStatus err = LSCopyKindStringForTypeInfo(UTGetOSTypeFromString((CFStringRef)_typeCode),
//											   UTGetOSTypeFromString((CFStringRef)_creatorCode),
//											   NULL,
//											   (CFStringRef *)&kindString);
	if (err != noErr) {
		NSLog(@"Error in updateCurrentKind. error : %i", err);
		return;
	}
	
	[_currentKind release];
	_currentKind = kindString;
}

- (void)updateCurrentUTI
{
	if (_ignoringCreatorForUTI) return;
	
	NSString *typeCode;
	if (_userLSHandler == nil) {
		typeCode = _typeCode;
	}
	else {
		typeCode = nil;
	}
		
	[self setCurrentUTI:getUTIFromTags(typeCode, _originalExtension)];
	
	LSHandlerOptions handlerOption = LSGetHandlerOptionsForContentType((CFStringRef)_currentUTI);
	_ignoringCreatorForUTI = (handlerOption == kLSHandlerOptionsIgnoreCreator);
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

#pragma mark accessors for current values
- (void)setUserLSHandlersForExtensions:dict
{
	[dict retain];
	[_userLSHandlersForExtensions release];
	_userLSHandlersForExtensions = dict;
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
	NSLog(@"start setCurrentUTI : %@", uti);
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
	return [NSNumber numberWithBool:(_userLSHandler != nil)];
}

#pragma mark accessors for original values
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
	[[aNotification object] saveFrameUsingName:_frameName];
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
	_frameName = @"CTDocumentWindow";
	NSWindow *aWindow = [aController window];
	[aWindow center];
	[aWindow setFrameUsingName:_frameName];
	if (![collapseButton state]) {
		[self collapseTypeTableBox:self];
	}

	[super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
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
	//read user's Launch services setting
	[self checkUserLaunchServiceSetting];
	
	//setup document icon image
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	[self setIconImg:[workspace iconForFile:absolutePath]];
	
	//setup original fileTypes
	if (![self setOriginalTypesFromFile:absolutePath]) return NO;
	
	//setup original kind
	NSString *kindString = nil;
	err = LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:absolutePath], (CFStringRef *)&kindString);
	[self setOriginalKind:[kindString autorelease]];
	
	//setup original extension;
	[self setOriginalExtension:[[fURL path] pathExtension]];
	
	//setup original UTI
//	CFStringRef tagClass;
//	NSString *tag;
//	NSDictionary *userHandler;
//	if (userHandler = [_userLSHandlersForExtensions objectForKey:_originalExtension]) {
//		_userLSHandler = userHandler;
//		tagClass = kUTTagClassFilenameExtension;
//		tag = _originalExtension;
//	}
//	else if (isValidType(_originalTypeCode)) {
//		tagClass = kUTTagClassOSType;
//		tag = _originalTypeCode;
//	}
//	else {
//		NSLog(@"no originalType Code");
//		tagClass = kUTTagClassFilenameExtension;
//		tag = _originalExtension;
//		NSLog(tag);
//	}
//	_originalUTI = (NSString *)UTTypeCreatePreferredIdentifierForTag(tagClass, (CFStringRef)tag, CFSTR("public.data"));
	
	FSRef fileRef;
	CFURLGetFSRef((CFURLRef)fURL, &fileRef);
	NSString *theUTI = nil;
	err = LSCopyItemAttribute(&fileRef, kLSRolesAll, kLSItemContentType, (CFTypeRef *)&theUTI );
	_originalUTI = theUTI;
	
	//setup default application path
	NSURL *appURL = nil;
	err = LSGetApplicationForURL((CFURLRef)fURL, kLSRolesAll, NULL, (CFURLRef *)&appURL);
	_originalAppPath = [[appURL path] retain];
	_originalAppIcon = [convertImageSize([workspace iconForFile:_originalAppPath], 16) retain];
	
	//setup current file type & creator type
	[self setCreatorCode: _originalCreatorCode];
	[self setTypeCode: _originalTypeCode];

    return YES;
}

#pragma mark actions
- (IBAction)collapseTypeTableBox:(id)sender;
{
	NSWindow *window = [[[self windowControllers] objectAtIndex:0] window];
	NSRect windowFrame = [window frame];

	if (! _isCollapsed){
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
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *creatorHistory = [userDefaults objectForKey:@"CreatorHistory"];
	NSMutableArray *typeHistory = [userDefaults objectForKey:@"TypeHistory"];
	
	unsigned int historyMax = [[userDefaults objectForKey:@"HistoryMax"] unsignedIntValue];
	NSLog(_creatorCode);
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
	
	[self applyTypes];
	[self close];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CTDocumentCloseNotification" object:self userInfo:nil];
	
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
