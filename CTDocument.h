/* CTDocument */

#import <Cocoa/Cocoa.h>
#import "TypeTableController.h"
#import "ApplyTypesProtocol.h"

@interface CTDocument : NSDocument <ApplyTypesProtocol>
{
    IBOutlet id creatorPopup;
    IBOutlet id typePopup;
	IBOutlet id typeTableBox;
	IBOutlet id collapseButton;
	IBOutlet id infoDrawer;
	IBOutlet id okButton;
	IBOutlet id openButton;
	
	NSString *_creatorCode;
	NSString *_typeCode;
	NSString *_currentKind;
	NSString *_currentUTI;
	NSString *_currentAppPath;
	NSImage *_currentAppIcon;
	NSColor *currentUTIColor;
	NSString *currentUTITips;
	
	NSImage *_iconImg;
	
	NSString *_originalCreatorCode;
	NSString *_originalTypeCode;
	NSString *_originalExtension;
	NSString *_originalKind;
	NSString *_originalUTI;
	NSString *_originalAppPath;
	NSImage *_originalAppIcon;
	NSDictionary *originalAttributes;
	BOOL _ignoringCreatorForUTI;
	BOOL _ignoringCreatorForExtension;
	BOOL hasUsroResource;
	UInt16 finderFlags;
	
	TypeTableController *_typeTableController;
	BOOL _isCollapsed;
	NSRect _typeBoxFrame;
	NSString *_frameName;
	SEL _defaultAction;
	id<ApplyTypesProtocol> modalDelegate;
	BOOL enableCreator;
}
- (IBAction)openAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)chooseFromFile:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)removeTypes:(id)sender;
- (IBAction)revert:(id)sender;
- (IBAction)collapseTypeTableBox:(id)sender;

- (void)applyTypeTemplate:(id)sender;

- (void)setTypeCode:(NSString *)typeCode;
- (void)setCreatorCode:(NSString *)creatorCode;
- (void)setCurrentUTI:(NSString *)uti;
- (void)setCurrentAppPath:(NSString *)path;
- (void)setCurrentAppIcon:(NSImage *)iconImage;

- (void)setOriginalCreatorCode:(NSString *)theType;
- (void)setOriginalTypeCode:(NSString *)theType;

- (NSString *)originalCreatorCode;
- (NSString *)originalTypeCode;
- (NSString *)originalExtension;
- (NSString *)originalKind;
- (NSString *)originalUTI;
- (NSString *)originalAppPath;

- (void)doDoubleAction:(id)sender;

- (void)setCurrentUTIColor:(NSColor *)color;
- (NSColor *)currentUTIColor;
- (void)setCurrentUTITips:(NSString *)tips;
- (NSString *)currentUTITips;

- (void)applyTypeDict:(NSDictionary *)typeDict modalDelegate:(id<ApplyTypesProtocol>)delegate;
- (void)applyTypesWithModalDelegate:(id<ApplyTypesProtocol>)delegate;
@end
