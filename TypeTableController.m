#import "TypeTableController.h"
#import "HFSTypeUtils.h"

#define useLog 1

@implementation TypeTableController
//static NSString *CopiedRowsType = @"COPIED_ROWS_TYPE";
static NSString *MovedRowsType = @"MOVED_ROWS_TYPE";

- (id)initWithNibName:(NSString *)nibName owner:(id)owner
{
	self = [self init];
	[NSBundle loadNibNamed:@"TypeTableView" owner:self];
	_owner = owner;
	return self;
}

- (void)awakeFromNib
{
	[typeTable registerForDraggedTypes: [NSArray arrayWithObjects:MovedRowsType, NSFilenamesPboardType, nil]];
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark private


#pragma mark accessors
- (id)typeTemplatesController
{
	return typeTemplatesController;
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

- (NSDictionary *)getSelection
{
	int selectedInd = [typeTable selectedRow];
	
	if (selectedInd < 0) return nil;
	
	NSArray *selectedItems = [typeTemplatesController selectedObjects];
	NSDictionary *selectedDict = [selectedItems objectAtIndex:0];
	return selectedDict;
}

- (void)setApplyTemplate:(SEL)selector
{
	_applySelector = selector;
	[typeTable setDoubleAction:selector];
}

#pragma mark methods for actions
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo
{
	if (returnCode == NSOKButton) {
		if (contextInfo == nil) {
			id dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[creatorCodeField stringValue], @"creatorCode",
				[typeCodeField stringValue], @"typeCode",
				[kindField stringValue], @"kind", nil];
			[typeTemplatesController addObject:dict];
		}
		else {
			[contextInfo setObject:[creatorCodeField stringValue] forKey:@"creatorCode"];
			[contextInfo setObject:[typeCodeField stringValue] forKey:@"typeCode"];
			[contextInfo setObject:[kindField stringValue] forKey:@"kind"];
		}
	}	
	[sheet orderOut:self];
}

- (void)setupTemplateEditorFor:(NSDictionary *)typeDict
{
	[creatorCodeField setStringValue: [typeDict objectForKey:@"creatorCode"]];
	[typeCodeField setStringValue: [typeDict objectForKey:@"typeCode"]];
	[kindField setStringValue: [typeDict objectForKey:@"kind"]];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *resultPath = [panel filename];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSDictionary *attInfo = [fileManager fileAttributesAtPath:resultPath traverseLink:YES];
		[creatorCodeField setStringValue: OSTypeToNSString([attInfo objectForKey:NSFileHFSCreatorCode])];
		[typeCodeField setStringValue: OSTypeToNSString([attInfo objectForKey:NSFileHFSTypeCode])];
	}
}

#pragma mark actions
- (IBAction)insertNewTypeTemplate:(id)sender
{
	[self setupTemplateEditorFor:
		[NSDictionary dictionaryWithObjectsAndKeys:@"????",@"creatorCode",@"????",@"typeCode",@"Untitled", @"kind",nil]];
	[NSApp beginSheet: typeTemplateEditor
	   modalForWindow: [sender window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
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
	NSArray *selectedItems = [typeTemplatesController selectedObjects];
	NSDictionary *selectedDict = [selectedItems objectAtIndex:0];
	[self setupTemplateEditorFor:selectedDict];
	
	[NSApp beginSheet: typeTemplateEditor
	   modalForWindow: [sender window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: selectedDict];	
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
	
/*	NSArray	*objects = [[typeTemplatesController arrangedObjects] objectsAtIndexes:indexSet];
	[typeTemplatesController removeObjectsAtArrangedObjectIndexes:indexSet];
	[typeTemplatesController insertObjects:objects atArrangedObjectIndexes:
		[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertIndex,1)] ];
*/	
    
	unsigned int	index = [indexSet lastIndex];
	
    unsigned int	aboveInsertIndexCount = 0;
    id object;
    unsigned int	removeIndex;
	//[typeTable setHighlightedTableColumn:nil];
	//[typeTable setSortDescriptors:nil];
	//[typeTemplatesController setSortDescriptors:nil];
    //[typeTemplatesController rearrangeObjects];
	NSArray	*objects = [typeTemplatesController arrangedObjects];
	
	while (NSNotFound != index) {
		printf("index %i\n", index);
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else {
			removeIndex = index;
			insertIndex -= 1;
		}
		
		object = [objects objectAtIndex:removeIndex];
		NSLog([object description]);
		NSLog(@"before remove");
		printf("removeIndex %d\n",removeIndex);
		[typeTemplatesController removeObjectAtArrangedObjectIndex:removeIndex];
		NSLog(@"after remove");
		[typeTemplatesController insertObject:object atArrangedObjectIndex:insertIndex];
		
		index = [indexSet indexLessThanIndex:index];
    }
	//[typeTemplatesController rearrangeObjects];
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
		typeDict = [NSDictionary dictionaryWithObjectsAndKeys:
			OSTypeToNSString([attInfo objectForKey:NSFileHFSCreatorCode]), @"creatorCode",
			OSTypeToNSString([attInfo objectForKey:NSFileHFSTypeCode]), @"typeCode", 
			kindString, @"kind", nil];
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
		NSLog([rowIndexes description]);
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
		//NSLog([plist description]);
		success = YES;
	}
	
	return success;
}

@end
