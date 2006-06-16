#import "BoolToStringTransformer.h"


@implementation BoolToStringTransformer


+ (Class)transformedValueClass
{
	return [NSString class];
}


+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	if ([value boolValue]) {
		return @"YES";
	}
	else {
		return @"NO";
	}
}
		
- (BOOL)reverseTransformedValue:(id)value
{
	if ([value isEqualToString:@"YES"]) {
		return YES;
	}
	else {
		return NO;
	}
}

@end
