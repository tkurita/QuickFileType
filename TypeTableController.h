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
	
	id _owner;
	SEL _applySelector;
}
- (IBAction)applyTypeTemplate:(id)sender;
- (IBAction)cancelTemplateEditor:(id)sender;
- (IBAction)chooseFromFileForTemplate:(id)sender;
- (IBAction)editSelectedTemplate:(id)sender;
- (IBAction)insertNewTypeTemplate:(id)sender;
- (IBAction)okTemplateEditor:(id)sender;

- (id)initWithNibName:(NSString *)nibName owner:(id)owner;
- (NSView *)view;
- (void)hideApplyButton;
- (NSDictionary *)getSelection;
- (void)setApplyTemplate:(SEL)selector;
- (id)typeTemplatesController;

@end
