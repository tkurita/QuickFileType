#import "UtilityFunctions.h"

#define useLog 0

NSImage *convertToSize16Image(NSImage *iconImage)
{
	NSArray * repArray = [iconImage representations];
	NSEnumerator *repEnum = [repArray objectEnumerator];
	NSImageRep *imageRep;
	NSSize Size16 = NSMakeSize(16, 16);
	BOOL hasSize16 = NO;
	while (imageRep = [repEnum nextObject]) {
		if (NSEqualSizes([imageRep size],Size16)) {
			hasSize16 = YES;
			break;
		}
	}
	if (hasSize16) {
		[iconImage setScalesWhenResized:NO];
		[iconImage setSize:NSMakeSize(16, 16)];
#if useLog
		NSLog(@"have size 16");
#endif
	}
	else {
		//[iconImage setScalesWhenResized:NO];
		[iconImage setSize:NSMakeSize(16, 16)];
#if useLog
		NSLog(@"not have size 16");
#endif
	}
	return iconImage;
}

NSString *getUTIFromTags(NSString *typeString, NSString *extensionString)
{
	CFStringRef tagClass;
	NSString *tag;
	
	if (!([typeString isEqualTo:@""] || (typeString == nil))) {
		tagClass = kUTTagClassOSType;
		tag = typeString;
	}
	else {
		NSLog(@"no originalType Code");
		tagClass = kUTTagClassFilenameExtension;
		tag = extensionString;
		NSLog(tag);
	}
	
	NSString *theUTI = (NSString *)UTTypeCreatePreferredIdentifierForTag(tagClass, (CFStringRef)tag, CFSTR("public.data"));
	return [theUTI autorelease];
}