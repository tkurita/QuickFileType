/* MCTWindowController */

#import <Cocoa/Cocoa.h>
#import "TypeTableController.h"
#import "ApplyTypesProtocol.h"

@interface MCTWindowController : NSWindowController <ApplyTypesProtocol>
{
    IBOutlet id fileListController;
    IBOutlet id splitSubview;
    IBOutlet id fileTable;
    IBOutlet id typeTableBox;
	IBOutlet id okButton;

	TypeTableController *_typeTableController;
	NSMutableArray *_documentArray;
	
	NSString *_frameName;
	NSEnumerator *docEnumerator;
	NSMutableArray *processedUTIs;
	NSMutableArray *processedDocuments;
	NSMutableString *errorMessage;
}
- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
- (void)setupFileTable:(NSArray *)files;

@end
