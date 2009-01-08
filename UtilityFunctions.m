#import "UtilityFunctions.h"

#define useLog 0

// related icon image
NSImage *iconForCreatorAndTypeString(NSString *creatorCode, NSString *typeCode)
{	
    return iconForCreatorAndType(UTGetOSTypeFromString((CFStringRef)creatorCode), UTGetOSTypeFromString((CFStringRef)typeCode));
}

NSImage *iconForCreatorAndType(OSType creatorCode, OSType typeCode)
{
    OSStatus err;
    IconRef icon;
    IconFamilyHandle fam;
    NSData *imageData;
	
    err = GetIconRef(kOnSystemDisk, creatorCode, typeCode, &icon);
    NSCAssert(err == noErr, @"can't get icon ref");
	
    err = IconRefToIconFamily(icon, kSelectorAllAvailableData, &fam);
    NSCAssert(err == noErr, @"can't get icon family from icon ref");
	
    err = ReleaseIconRef(icon);
    NSCAssert(err == noErr, @"can't release icon ref");
	
    imageData = [NSData dataWithBytes: *fam length: fam[0]->resourceSize];
    NSCAssert(imageData != nil, @"can't make NSData from icon data");
	
    return [[[NSImage alloc] initWithData:imageData] autorelease];
}

NSImage *convertImageSize(NSImage *iconImage, int imgSize)
{
	NSArray * repArray = [iconImage representations];
	NSEnumerator *repEnum = [repArray objectEnumerator];
	NSImageRep *imageRep;
	NSSize targetSize = NSMakeSize(imgSize, imgSize);
	NSImage *new_image;
	BOOL hasTargetSize = NO;
	while (imageRep = [repEnum nextObject]) {
		if (NSEqualSizes([imageRep size],targetSize)) {
			hasTargetSize = YES;
			break;
		}
	}
	
	if (hasTargetSize) {
		[iconImage setScalesWhenResized:NO];
		new_image = [iconImage copy];
		[new_image setSize:targetSize];
		#if useLog
		NSLog(@"have target size %i", imgSize);
		#endif
	}
	else {
		[iconImage setScalesWhenResized:YES];
		new_image = [iconImage copy];
		[new_image setSize:targetSize];
		#if useLog
		NSLog(@"not have target size %i", imgSize);
		#endif
	}
	
	return [new_image autorelease];
	//return new_image;
}

// related type infomation
BOOL isValidType(NSString *typeString)
{
	return ( (typeString != nil) && (![typeString isEqualTo:@""]) );
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
#if useLog		
		NSLog(@"no originalType Code");
#endif	
		if ([extensionString isEqualToString:@""] || (! extensionString)) {
			return nil;
		}
		tagClass = kUTTagClassFilenameExtension;
		tag = extensionString;
	}
	
	NSString *theUTI = (NSString *)UTTypeCreatePreferredIdentifierForTag(tagClass, (CFStringRef)tag, CFSTR("public.data"));
	return [theUTI autorelease];
}