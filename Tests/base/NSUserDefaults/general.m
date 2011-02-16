#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSUserDefaults.h>
#import "ObjectTesting.h"

@interface      Observer : NSObject
{
  unsigned count;
}
- (NSString*) count;
- (void) notified: (NSNotification*)n;
@end

@implementation Observer
- (NSString*) count
{
  return [NSString stringWithFormat: @"%u", count];
}
- (void) notified: (NSNotification*)n
{
  count++;
}
@end

int main()
{
  NSAutoreleasePool   *arp = [NSAutoreleasePool new];
  Observer *obs = [[Observer new] autorelease];
  NSUserDefaults *defs;

  defs = [NSUserDefaults standardUserDefaults];
  PASS(defs != nil && [defs isKindOfClass: [NSUserDefaults class]],
       "NSUserDefaults understands +standardUserDefaults");

#if	defined(GNUSTEP_BASE_LIBRARY)
{
  id lang;

  lang = [NSUserDefaults userLanguages];
  PASS(lang != nil && [lang isKindOfClass: [NSArray class]],
       "NSUserDefaults understands +userLanguages");

  [NSUserDefaults setUserLanguages:
    [NSArray arrayWithObject: @"Bogus language"]];
  PASS([lang isEqual: [NSUserDefaults userLanguages]] == NO,
       "NSUserDefaults understands +setUserLanguages");

  [NSUserDefaults setUserLanguages: lang];
  PASS([lang isEqual: [NSUserDefaults userLanguages]],
       "NSUserDefaults can set user languages");
}
#endif

  [[NSNotificationCenter defaultCenter] addObserver: obs
    selector: @selector(notified:)
    name: NSUserDefaultsDidChangeNotification
    object: nil];

  [defs setBool: YES forKey: @"Test Suite Bool"];
  PASS([defs boolForKey: @"Test Suite Bool"],
       "NSUserDefaults can set/get a BOOL");

  PASS_EQUAL([obs count], @"1", "setting a boolean causes notification");

  [defs setInteger: 34 forKey: @"Test Suite Int"];
  PASS([defs integerForKey: @"Test Suite Int"] == 34,
       "NSUserDefaults can set/get an int");

  PASS_EQUAL([obs count], @"2", "setting an integer causes notification");

  [defs setObject: @"SetString" forKey: @"Test Suite Str"];
  PASS([[defs stringForKey: @"Test Suite Str"] isEqual: @"SetString"],
       "NSUserDefaults can set/get a string");
  
  [arp release]; arp = nil;
  return 0;
}
