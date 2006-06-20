/* CTDocument */

#import <Cocoa/Cocoa.h>
#import "TypeTableController.h"

@interface CTDocument : NSDocument
{
    IBOutlet id creatorPopup;
    IBOutlet id typePopup;
	IBOutlet id typeTableBox;
	IBOutlet id collapseButton;
	IBOutlet id infoDrawer;
	
	NSString *_creatorCode;
	NSString *_typeCode;
	NSString *_currentKind;
	NSString *_currentUTI;
	NSString *_currentAppPath;
	NSImage *_currentAppIcon;
	
	NSImage *_iconImg;
	NSDictionary *_userLSHandlersForExtensions;
	NSDictionary *_userLSHandler;
	
	NSString *_originalCreatorCode;
	NSString *_originalTypeCode;
	NSString *_originalExtension;
	NSString *_originalKind;
	NSString *_originalUTI;
	NSString *_originalAppPath;
	NSImage *_originalAppIcon;
	BOOL _ignoringCreatorForUTI;
	BOOL _ignoringCreatorForExtension;
	
	TypeTableController *_typeTableController;
	BOOL _isCollapsed;
	NSRect _typeBoxFrame;
	NSString *_frameName;
}
- (IBAction)cancelAction:(id)sender;
- (IBAction)chooseFromFile:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)removeTypes:(id)sender;
- (IBAction)revert:(id)sender;
- (IBAction)collapseTypeTableBox:(id)sender;

- (void)applyTypeTemplate:(id)sender;
- (void)applyTypesFromDict:(NSDictionary *)typeDict;

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

- (void)setUserLSHandlersForExtensions:dict;

@end
