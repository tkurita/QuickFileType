/* MCTWindowController */

#import <Cocoa/Cocoa.h>
#import "TypeTableController.h"

@interface MCTWindowController : NSWindowController
{
    IBOutlet id fileListController;
    IBOutlet id splitSubview;
    IBOutlet id fileTable;
    IBOutlet id typeTableBox;
	IBOutlet id okButton;

	TypeTableController *_typeTableController;
	NSMutableArray *_documentArray;
	
	NSString *_frameName;
}
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
- (void)setupFileTable:(NSArray *)files;

@end
