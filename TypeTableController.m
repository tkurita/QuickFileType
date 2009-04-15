#import "TypeTableController.h"
#import "HFSTypeUtils.h"
#import "UtilityFunctions.h"

#define useLog 0

NSString *removeHatenaType(NSString *typeString)
{
	if ([typeString isEqualToString:@"????"]) {
		return @"";
	}
	else {
		return typeString;
	}
}

void setupIcon(id targetObj, NSImage *iconImage)
{
	[targetObj setObject:[NSArchiver archivedDataWithRootObject:convertImageSize(iconImage, 16)] forKey:@"icon16"];
	[targetObj setObject:[NSArchiver archivedDataWithRootObject:convertImageSize(iconImage, 32)] forKey:@"icon32"];
}

@implementation TypeTableController
//static NSString *CopiedRowsType = @"COPIED_ROWS_TYPE";
static NSString *MovedRowsType = @"MOVED_ROWS_TYPE";

- (id)initWithNibName:(NSString *)nibName owner:(id)owner
{
	self = [self init];
	[NSBundle loadNibNamed:@"TypeTableView" owner:self];
	_owner = owner;
	int findex = [[NSUserDefaults standardUserDefaults] integerForKey:@"favoriteIndex"];
	if (findex != NSNotFound) {
		NSIndexSet *indexset = [NSIndexSet indexSetWithIndex:findex];
		[self setSelectedFavoriteIndexes:indexset];
	}
	return self;
}

- (void)awakeFromNib
{
	[typeTable registerForDraggedTypes: [NSArray arrayWithObjects:MovedRowsType, NSFilenamesPboardType, nil]];
}

- (void)dealloc
{
	[selectedFavoriteIndexes release];
	[super dealloc];
}

- (void)saveSettings
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults setObject:[NSNumber numberWithInt:[selectedFavoriteIndexes firstIndex]]
					  forKey:@"favoriteIndex"];
}


#pragma mark accessors
- (NSIndexSet *)selectedFavoriteIndexes
{
	return selectedFavoriteIndexes;
}

- (void)setSelectedFavoriteIndexes:(NSIndexSet *)indexes
{
	[indexes retain];
	[selectedFavoriteIndexes release];
	selectedFavoriteIndexes = indexes;
}
- (id)typeTemplatesController
{
	return typeTemplatesController;
}

- (NSTableView *)favoritesTableView
{
	return typeTable;
}

- (NSView *)view
{
	return typeTableView;
}

- (void)hideApplyButton
{
	[typeTable setDelegate:self];
	[applyButton setHidden:YES];
}

- (NSDictionary *)selectedTypes
{
	int selectedInd = [typeTable selectedRow];
	
	if (selectedInd < 0) return nil;
	
	NSArray *selectedItems = [typeTemplatesController selectedObjects];
	NSDictionary *selectedDict = [selectedItems objectAtIndex:0];
	return selectedDict;
}

- (void)setDoubleAction:(SEL)selector
{
	[typeTable setDoubleAction:selector];
}


- (void)setApplyTemplate:(SEL)selector
{
	_applySelector = selector;
}

-(void)setUpdatedIcon:(NSImage *)iconImage
{
	[iconImage retain];
	[_updatedIcon release];
	_updatedIcon = iconImage;
}

#pragma mark methods for actions

- (void)setupTemplateEditorFor:(NSDictionary *)typeDict
{
	[creatorCodeField setStringValue: [typeDict objectForKey:@"creatorCode"]];
	[typeCodeField setStringValue: [typeDict objectForKey:@"typeCode"]];
	[kindField setStringValue: [typeDict objectForKey:@"kind"]];
	NSData *iconData;
	if (iconData = [typeDict objectForKey:@"icon32"]) {
		[iconField setImage: [NSUnarchiver unarchiveObjectWithData:iconData]];
	}
	else {
		[iconField setImage: nil];
	}
	
}

- (void)didEndEditFavorite:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(NSDictionary *)selected_dict
{
	if (returnCode != NSOKButton) goto bail;
	
	NSString *type_code = removeHatenaType([typeCodeField stringValue]);
	NSString *creator_code = removeHatenaType([creatorCodeField stringValue]);
	NSString *new_kind = [kindField stringValue];

	NSString *preCreator = [selected_dict objectForKey:@"creatorCode"];
	NSString *preType = [selected_dict objectForKey:@"typeCode"];
	NSString *pre_kind = [selected_dict objectForKey:@"kind"];
	
	BOOL is_type_upedated = NO;
	if (![preCreator isEqualToString:creator_code]) {
		[typeTemplatesController setValue:creator_code forKeyPath:@"selection.creatorCode"];
		is_type_upedated = YES;
		_shouldUpdateIcon =  YES;
	}
	if (![preType isEqualToString:type_code]) {
		[typeTemplatesController setValue:type_code forKeyPath:@"selection.typeCode"];
		_shouldUpdateIcon =  YES;
		is_type_upedated = YES;
	}
	
	if (_shouldUpdateIcon) {
		if (_updatedIcon == nil) {
			[self setUpdatedIcon:iconForCreatorAndTypeString(creator_code, type_code)];
		}
		
		[typeTemplatesController setValue:[NSArchiver archivedDataWithRootObject:convertImageSize(_updatedIcon, 16)]
			forKeyPath:@"selection.icon16"];
		[typeTemplatesController setValue:[NSArchiver archivedDataWithRootObject:convertImageSize(_updatedIcon, 32)]
			forKeyPath:@"selection.icon32"];
		
		if (is_type_upedated) {
			if ([new_kind isEqualToString:pre_kind]) {
				OSStatus err = LSCopyKindStringForTypeInfo(UTGetOSTypeFromString((CFStringRef)type_code),
									UTGetOSTypeFromString((CFStringRef)creator_code), 
									NULL,
									(CFStringRef *)&new_kind);
				if (err != noErr) {
					NSLog(@"Error to get kind string. error : %i", err);
				}
			}
		}
	}
	
	if (![new_kind isEqualToString:pre_kind]) {
		[typeTemplatesController setValue:new_kind forKeyPath:@"selection.kind"];
	}

bail:
	[sheet orderOut:self];
}

- (void)didEndNewFavorite:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if (returnCode != NSOKButton) goto bail;
	
	NSString *typeCode = removeHatenaType([typeCodeField stringValue]);
	NSString *creatorCode = removeHatenaType([creatorCodeField stringValue]);
	NSString *new_kind = [kindField stringValue];
	
	id dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		creatorCode, @"creatorCode",
		typeCode, @"typeCode",
		new_kind, @"kind", nil];
	if (_updatedIcon == nil) {
		[self setUpdatedIcon:iconForCreatorAndTypeString(creatorCode, typeCode)];
	}
	setupIcon(dict, _updatedIcon);
	[typeTemplatesController addObject:dict];

bail:
	[sheet orderOut:self];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *resultPath = [panel filename];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSDictionary *attInfo = [fileManager fileAttributesAtPath:resultPath traverseLink:YES];
		NSString *creator_code = OSTypeToNSString([attInfo objectForKey:NSFileHFSCreatorCode]);
		NSString *type_code = OSTypeToNSString([attInfo objectForKey:NSFileHFSTypeCode]);
		[creatorCodeField setStringValue: creator_code];
		[typeCodeField setStringValue: type_code];
		
		NSString *kind_string;
		OSStatus err = LSCopyKindStringForTypeInfo(UTGetOSTypeFromString((CFStringRef)type_code),
											UTGetOSTypeFromString((CFStringRef)creator_code), 
											NULL,
											(CFStringRef *)&kind_string);
		if (err == noErr) {
			[kindField setStringValue:kind_string];
		}
		else {
			NSLog(@"Error in updateCurrentKind. error : %i", err);
		}

		[self updateIcon:self];
	}
}

#pragma mark actions
- (IBAction)updateIcon:(id)sender
{
	NSImage *iconImage = iconForCreatorAndTypeString([creatorCodeField stringValue], [typeCodeField stringValue]);
	[self setUpdatedIcon:iconImage];
	[iconField setImage:convertImageSize(iconImage, 32)];
	_shouldUpdateIcon = YES;
}

- (IBAction)insertNewTypeTemplate:(id)sender
{
	[self setupTemplateEditorFor:
		[NSDictionary dictionaryWithObjectsAndKeys:@"????",@"creatorCode",@"????",@"typeCode",@"Untitled", @"kind",nil]];
	[NSApp beginSheet: typeTemplateEditor
	   modalForWindow: [sender window]
		modalDelegate: self
	   didEndSelector: @selector(didEndNewFavorite:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (IBAction)chooseFromFileForTemplate:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel beginSheetForDirectory:nil 
								 file:nil
								types:nil
					   modalForWindow:[sender window]
						modalDelegate:self
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (IBAction)applyTypeTemplate:(id)sender
{
	[_owner performSelector:_applySelector withObject:self];
}

- (IBAction)okTemplateEditor:(id)sender
{
	[NSApp endSheet:typeTemplateEditor returnCode:NSOKButton];
}

- (IBAction)cancelTemplateEditor: (id)sender
{
    [NSApp endSheet:typeTemplateEditor returnCode:NSCancelButton];
}

- (IBAction)editSelectedTemplate:(id)sender
{
	_shouldUpdateIcon = NO;
	[self setUpdatedIcon:nil];
	
	NSArray *selectedItems = [typeTemplatesController selectedObjects];
	NSDictionary *selectedDict = [selectedItems objectAtIndex:0];
	
	[self setupTemplateEditorFor:selectedDict];
	[NSApp beginSheet: typeTemplateEditor
	   modalForWindow: [sender window]
		modalDelegate: self
	   didEndSelector: @selector(didEndEditFavorite:returnCode:contextInfo:)
	  contextInfo: selectedDict
		];
}


#pragma mark datasource for TableView
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
#if useLog
	NSLog(@"start writeRowsWithIndexes");
#endif
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:MovedRowsType] owner:self];
	[pboard setData:data forType:MovedRowsType];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op 
{
#if useLog
    NSLog(@"validate Drop: %i",op);
#endif
	NSDragOperation result = NSDragOperationEvery;
	switch(op) {
		case NSTableViewDropOn:
			result = NSDragOperationNone;
			break;
		case NSTableViewDropAbove:
			result = NSDragOperationEvery;
			break;
		default:
			break;
	}
	
	return result;
}

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet
										toIndex:(unsigned int)insertIndex
{
	unsigned int	index = [indexSet lastIndex];
	
    unsigned int	aboveInsertIndexCount = 0;
    id object;
    unsigned int	removeIndex;
	NSMutableArray *objects = [[typeTemplatesController arrangedObjects] mutableCopy];
	NSMutableArray *selectedObj = [NSMutableArray arrayWithCapacity:[indexSet count]];
	while (NSNotFound != index) {
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else {
			removeIndex = index;
			insertIndex -= 1;
		}
		
		object = [objects objectAtIndex:removeIndex];
		[objects removeObjectAtIndex:removeIndex];
		[objects insertObject:object atIndex:insertIndex];
		[selectedObj addObject:object];
		index = [indexSet indexLessThanIndex:index];
    }
	[typeTemplatesController setSortDescriptors:nil];
	[typeTemplatesController removeObjects:objects];
	[typeTemplatesController addObjects:objects];
	[typeTemplatesController setSelectedObjects:selectedObj];
}

- (void)insertTypesFromPathes:(NSArray *)pathes row:(int)row
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSMutableArray *typeList = [NSMutableArray arrayWithCapacity:[pathes count]];
	NSEnumerator *arrayEnum = [pathes objectEnumerator];
	
	NSString *path;
	NSDictionary *attInfo;
	NSDictionary *typeDict;
	NSString *kindString=nil;
	while (path = [arrayEnum nextObject]) {
		(NSString *)LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:path], (CFStringRef *)&kindString);
		[kindString autorelease];
		attInfo = [fileManager fileAttributesAtPath:path traverseLink:YES];
		NSNumber *creatorCode = [attInfo objectForKey:NSFileHFSCreatorCode];
		NSNumber *typeCode = [attInfo objectForKey:NSFileHFSTypeCode];
		NSImage *iconImage = iconForCreatorAndType([creatorCode intValue], [typeCode intValue]);
		
		typeDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			OSTypeToNSString(creatorCode), @"creatorCode",
			OSTypeToNSString(typeCode), @"typeCode", 
			kindString, @"kind", nil];		
		setupIcon(typeDict, iconImage);
		
		[typeList addObject:typeDict];
	}
	NSIndexSet *insertIdxes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row,[typeList count])];
	[typeTemplatesController insertObjects:typeList atArrangedObjectIndexes:insertIdxes];
}


- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info 
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    BOOL success = NO;
	if ([info draggingSource] == typeTable) { //move in same table
		
		NSData* rowData = [pboard dataForType:MovedRowsType];
		NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
		[self moveObjectsInArrangedObjectsFromIndexes:rowIndexes toIndex:row];
		
		success = YES;
    } 
	else {
		NSString *error = nil;
		NSPropertyListFormat format;
		NSData* rowData = [pboard dataForType:NSFilenamesPboardType];
		id plist = [NSPropertyListSerialization propertyListFromData:rowData
													mutabilityOption:NSPropertyListImmutable
															  format:&format
													errorDescription:&error];		
		[self insertTypesFromPathes:plist row:row];
		success = YES;
	}
	
	return success;
}

@end
