#import "CTDocument.h"
#import "HFSTypeUtils.h"

#define useLog 1

@implementation CTDocument

#pragma mark init and dealloc

- (void)dealloc {
	[_creatorCode release];
	[_typeCode release];
	[_originalCreatorCode release];
	[_originalTypeCode release];
	
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

#pragma mark accessor methods
- (void)setIconImg:(NSImage *)iconImg
{
	[iconImg retain];
	[_iconImg release];
	_iconImg = iconImg;
}

- (NSImage *)iconImg
{
	return _iconImg;
}

- (void)setKind:(NSString *)kind
{
	[kind retain];
	[_kind release];
	_kind = kind;
}

- (NSString *)kind
{
	return _kind;
}

- (void)setOriginalTypeCode:(NSString *)theType
{
	[theType retain];
	[_originalTypeCode release];
	_originalTypeCode = theType;
}

- (void)setTypeCode:(NSString *)typeCode
{
	[typeCode retain];
	[_typeCode release];
	_typeCode = typeCode;
}

- (NSString *)typeCode
{
	return _typeCode;
}

- (void)setOriginalCreatorCode:(NSString *)theType
{
	[theType retain];
	[_originalCreatorCode release];
	_originalCreatorCode = theType;
}

- (void)setCreatorCode:(NSString *)creatorCode
{
	NSLog(@"setCreatorCode:%@", creatorCode);
	[creatorCode retain];
	[_creatorCode release];
	_creatorCode = creatorCode;
}

- (NSString *)creatorCode
{
	return _creatorCode;
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
	[[aController window] center];
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
	if (![self setTypesFromFile:absolutePath]) return NO;
	
	[self setOriginalCreatorCode: _creatorCode];
	[self setOriginalTypeCode: _typeCode];
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	[self setIconImg:[workspace iconForFile:absolutePath]];
	
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
