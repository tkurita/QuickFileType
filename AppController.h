/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
	NSMutableArray *itemsOpenWithCreator;
}

@property (retain) NSMutableArray *itemsOpenWithCreator;

- (IBAction)makeDonation:(id)sender;

@end
