#import <Cocoa/Cocoa.h>

NSImage *iconForCreatorAndTypeString(NSString *creatorCode, NSString *typeCode);
NSImage *iconForCreatorAndType(OSType creatorCode, OSType typeCode);
NSImage *convertToSize16Image(NSImage *iconImage);
NSImage *convertImageSize(NSImage *iconImage, int imgSize);

NSString *getUTIFromTags(NSString *typeString, NSString *extensionString);
BOOL isValidType(NSString *typeString);
