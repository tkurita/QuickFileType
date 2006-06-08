#import "OSTypeTransformer.h"

#define useLog 0

@implementation OSTypeTransformer

+ (void)initialize
{
	typeCharSet = [NSCharacterSet alphanumericCharacterSet];
}

+ (Class)transformedValueClass
{
	return [NSString class];
}


+ (BOOL)allowsReverseTransformation
{
	return YES;
}


- (id)transformedValue:(id)value
{	
	return value;
}

- (id)reverseTransformedValue:(id)typeString
{
#if useLog
	NSLog(typeString);
#endif
	if ([typeString length] > 4) {
		typeString = [typeString substringWithRange:NSMakeRange(0,4)];
	}
	
	NSScanner *theScanner = [NSScanner scannerWithString:typeString];
	NSString *validType = nil;
	[theScanner scanCharactersFromSet:typeCharSet intoString:&validType];
#if useLog	
	NSLog(validType);
#endif
	return validType;
}

@end
