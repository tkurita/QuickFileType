#import "HFSTypeUtils.h"

NSString *OSTypeToNSString(NSNumber *number)
{
	return (NSString *)UTCreateStringForOSType([number longValue]);
}

NSNumber *StringToOSType(NSString *string)
{
	return [NSNumber numberWithUnsignedLong:UTGetOSTypeFromString((CFStringRef) string)];
}

@implementation HFSTypeUtils

@end
