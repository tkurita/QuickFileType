@class CTDocument;

@protocol ApplyTypesProtocol
- (void)didEndApplyTypesForDoc:(CTDocument *)doc error:(NSError *)error;
- (BOOL)shouldRespectCreatorForUTI:(NSString *)uti;
- (NSWindow *)windowForSheet;
@end