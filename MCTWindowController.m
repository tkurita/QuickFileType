#import "MCTWindowController.h"
#import "HFSTypeUtils.h"
#import "CTDocument.h"
#import "RBSplitView/RBSplitView.h"
#import "RBSplitView/RBSplitSubview.h"

@implementation MCTWindowController

#pragma mark ApplyTypesProtocol

- (NSWindow *)windowForSheet
{
	return [self window];
}

- (BOOL)shouldRespectCreatorForUTI:(NSString *)uti
{
	return ![processedUTIs containsObject:uti];
}

- (void)didEndApplyTypesForDoc:(CTDocument *)doc error:(NSError *)error
{
	if (error) {
		[errorMessage appendString:[error localizedDescription]];
		[errorMessage appendString:@"\n"];
		[errorMessage appendString:[[doc fileURL] path]];
		[errorMessage appendString:@"\n"];
	} else {
		[processedDocuments addObject:doc];
	}
	
	doc = [docEnumerator nextObject];
	if (doc) {
		NSDictionary *typeDict = [_typeTableController selectedTypes];
		if (!typeDict) return;
		[doc applyTypeDict:typeDict modalDelegate:self];
	} else {
		if ([errorMessage length]) {
			[fileListController removeObjects:processedDocuments];
			NSBeginAlertSheet(
				  NSLocalizedString(@"Can't change creator and type.",
									@"Alert when can't apply types of single mode"),	// sheet message
				  @"OK",					// default button label
				  nil,					// no third button
				  nil,					// other button label
				  [self window],		// window sheet is attached to
				  self,                   // we’ll be our own delegate
				  nil,					// did-end selector
				  nil,                   // no need for did-dismiss selector
				  nil,					// context info
				  errorMessage);				// additional text
			
		} else {
			[self close];
		}
	}
}

#pragma mark accessors
- (void)setDocEnumerator:(NSEnumerator *)enumerator
{
	[enumerator retain];
	[docEnumerator release];
	docEnumerator = enumerator;
}

- (void)setProcessedUTIs:(NSMutableArray *)array
{
	[array retain];
	[processedUTIs release];
	processedUTIs = array;
}

- (void)setProcessedDocuments:(NSMutableArray *)array
{
	[array retain];
	[processedDocuments release];
	processedDocuments = array;
}

- (void)setErrorMessage:(NSMutableString *)string
{
	[string retain];
	[errorMessage release];
	errorMessage = string;
}

#pragma mark actions
- (IBAction)cancelAction:(id)sender
{
	[self close];
}

- (IBAction)okAction:(id)sender
{
	[self setDocEnumerator:[_documentArray objectEnumerator]];
	[self setProcessedUTIs:[NSMutableArray array]];
	[self setProcessedDocuments:[NSMutableArray array]];
	[self setErrorMessage:[NSMutableString string]];
	NSDictionary *typeDict = [_typeTableController selectedTypes];
	if (!typeDict) return;
	CTDocument *doc = [docEnumerator nextObject];
	if (doc) {
		[doc applyTypeDict:typeDict modalDelegate:self];
	} 
}


/*
- (IBAction)okAction:(id)sender
{
	NSDictionary *typeDict = [_typeTableController selectedTypes];
	if (! typeDict) return;
	
	NSEnumerator *doc_enum = [_documentArray objectEnumerator];
	CTDocument *doc;
	BOOL exists_error = NO;
	NSMutableArray *doc_success = [NSMutableArray array];
	NSMutableString *error_msg = [NSMutableString string];
	while (doc = [doc_enum nextObject]) {
		@try {
			[doc applyTypesFromDict:typeDict];
			[doc_success addObject:doc];
		}
		@catch (NSException *exception) {
			if (! [[exception name] isEqualToString:@"ApplyTypesException"] ) {       
				@throw;
			}
			[error_msg appendString:NSLocalizedString([exception reason],@"")];
			[error_msg appendString:@"\n"];
			[error_msg appendString:[doc fileName]];
			[error_msg appendString:@"\n"];
			exists_error = YES;
		}
	}
	
	if (exists_error) {
		[fileListController removeObjects:doc_success];
		NSBeginAlertSheet(
		NSLocalizedString(@"Can't change creator and type.",
			@"Alert when can't apply types of single mode"),	// sheet message
		@"OK",					// default button label
		nil,					// no third button
		nil,					// other button label
		[sender window],		// window sheet is attached to
		self,                   // we’ll be our own delegate
		nil,					// did-end selector
		nil,                   // no need for did-dismiss selector
		nil,					// context info
		error_msg);				// additional text
	}
	else {
		[self close];
	}
}
*/

- (void) dealloc {
	[_typeTableController release];
	[docEnumerator release];
	[_documentArray release];
	[processedDocuments release];
	[processedUTIs release];
	[errorMessage release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[aNotification object] saveFrameUsingName:_frameName];
	[[NSUserDefaults standardUserDefaults] synchronize]; //window を閉じずに終了した時に必要
	[self release];
}

- (void)setDocumentArray:(NSMutableArray *)array
{
	[array retain];
	[_documentArray release];
	_documentArray = array;
}

- (NSMutableArray *)documentArray
{
	return _documentArray;
}

- (void)openCTDocument:(id)sender
{
	NSArray *fileDicts = [fileListController selectedObjects];
	NSEnumerator *dictEnum = [fileDicts objectEnumerator];
	id fileDict;
	while(fileDict = [dictEnum nextObject]) {
		if (![[fileDict windowControllers] count]) {
			[fileDict makeWindowControllers];
		}
		[fileDict showWindows];
	}
}

- (void)removeCTDocument:(NSNotification *)aNotification
{
	NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
	[fileListController removeObject:[aNotification object]];
	[notiCenter removeObserver:self name:@"CTDocumentCloseNotification" object:[aNotification object]];
	if (![_documentArray count]) {
		[self close];
	}
}

- (void)setupFileTable:(NSArray *)files
{
	NSMutableArray *docArray = [NSMutableArray arrayWithCapacity:[files count]];
	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
	NSEnumerator *fileEnum = [files objectEnumerator];
	NSURL *fileURL;
	NSDocument *theDoc;
	NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
	
	while (fileURL = [fileEnum nextObject]) {
		theDoc = [docController openDocumentWithContentsOfURL:fileURL display:NO error:nil];
		if (theDoc) {
			if (![docArray containsObject:theDoc]) {
				[docArray addObject:theDoc];
				[notiCenter addObserver:self selector:@selector(removeCTDocument:) name:@"CTDocumentCloseNotification" object:theDoc];
			}
		}
	}

	[self setDocumentArray:docArray];
}

- (void)setupTypeTable
{
	_typeTableController = [[TypeTableController alloc] initWithNibName:@"TypeTableView" owner:self];
	[typeTableBox setContentView:[_typeTableController view]];
	[_typeTableController hideApplyButton];
	[okButton bind:@"enabled" toObject:[_typeTableController typeTemplatesController] withKeyPath:@"selectedObjects.@count" options:nil];
	[_typeTableController setDoubleAction:@selector(okAction:)];

}

- (void)windowDidLoad
{
	[self setupTypeTable];
	[fileTable setDoubleAction:@selector(openCTDocument:)];
	_frameName = @"MCTWindow";
	NSWindow *aWindow = [self window];
	NSTableView *favorites_table = [_typeTableController favoritesTableView];
	[aWindow setInitialFirstResponder:favorites_table];
	[favorites_table setNextKeyView:fileTable];
	[fileTable setNextKeyView:favorites_table];
	[aWindow center];
	[aWindow setFrameUsingName:_frameName];
	
	float row_height = [fileTable rowHeight];
	int nrows = [fileTable numberOfRows];
	NSSize spacing = [fileTable intercellSpacing];
	NSRect hframe =	[[fileTable headerView] frame];
	float table_height = hframe.size.height + ((row_height + spacing.height)*(nrows)) +5;

	float current_dimension = [splitSubview dimension];
	if (table_height > current_dimension) table_height = current_dimension;
	[splitSubview setDimension:table_height ];
}

@end
