#import "OSTypeFormatter.h"

#define useLog 0
static NSCharacterSet *typeCharSet;

@implementation OSTypeFormatter

+ (void)initialize
{
	typeCharSet = [NSCharacterSet alphanumericCharacterSet];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
#if useLog
	NSLog(@"getObjectValue:%@",string);
#endif	
	*anObject = string;
	return YES;
}

- (NSString *)stringForObjectValue:(id)anObject
{
#if useLog
	NSLog(@"stringForObjectValue:%@",anObject);
#endif
	return anObject;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error
{
#if useLog
	NSLog(@"stat isPartialStringValid:%@",partialString);
#endif
	if ([partialString length] > 4) {
		return NO;
	}
	
	NSScanner *theScanner = [NSScanner scannerWithString:partialString];
	[theScanner scanCharactersFromSet:typeCharSet intoString:nil];
	if (![theScanner isAtEnd]) {
		return NO;
	}
	return YES;
}
@end
