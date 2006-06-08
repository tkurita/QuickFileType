/* CTDocument */

#import <Cocoa/Cocoa.h>
#import "TypeTableController.h"

@interface CTDocument : NSDocument
{
    IBOutlet id creatorPopup;
    IBOutlet id typePopup;
	IBOutlet id typeTableBox;
	IBOutlet id collapseButton;
		
	NSString *_creatorCode;
	NSString *_typeCode;
	NSString *_kind;
	NSImage *_iconImg;
	NSString *_originalCreatorCode;
	NSString *_originalTypeCode;
	TypeTableController *_typeTableController;
	BOOL _isCollapsed;
	NSRect _typeBoxFrame;
}
- (IBAction)cancelAction:(id)sender;
- (IBAction)chooseFromFile:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)removeTypes:(id)sender;
- (IBAction)revert:(id)sender;
- (IBAction)collapseTypeTableBox:(id)sender;

- (void)setTypeCode:(NSString *)typeCode;
- (void)setCreatorCode:(NSString *)creatorCode;
- (void)applyTypeTemplate:(id)sender;
- (void)applyTypesFromDict:(NSDictionary *)typeDict;
@end
