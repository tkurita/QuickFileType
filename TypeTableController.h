/* TypeTableController */

#import <Cocoa/Cocoa.h>

@interface TypeTableController : NSObject
{
    IBOutlet id typeTable;
    IBOutlet id typeTableView;
	IBOutlet id typeTemplateEditor;
    IBOutlet id typeTemplatesController;
	IBOutlet id applyButton;
	IBOutlet id creatorCodeField;
	IBOutlet id typeCodeField;
	IBOutlet id kindField;
	IBOutlet id iconField;
	
	id _owner;
	SEL _applySelector;
	BOOL _shouldUpdateIcon;	
	NSImage *_updatedIcon;
	
	NSIndexSet *selectedFavoriteIndexes;
}
- (IBAction)applyTypeTemplate:(id)sender;
- (IBAction)cancelTemplateEditor:(id)sender;
- (IBAction)chooseFromFileForTemplate:(id)sender;
- (IBAction)editSelectedTemplate:(id)sender;
- (IBAction)insertNewTypeTemplate:(id)sender;
- (IBAction)okTemplateEditor:(id)sender;
- (IBAction)updateIcon:(id)sender;

- (id)initWithNibName:(NSString *)nibName owner:(id)owner;
- (void)saveSettings;

//accessors
- (NSView *)view;
- (NSTableView *)favoritesTableView;

- (void)hideApplyButton;
- (NSDictionary *)getSelection;
- (void)setApplyTemplate:(SEL)selector;
- (void)setDoubleAction:(SEL)selector;
- (id)typeTemplatesController;
- (void)setSelectedFavoriteIndexes:(NSIndexSet *)indexes;

@end
