#define	STRICT_OPENSTEP	1
#include	<Foundation/Foundation.h>

id	myServer;

@interface	Tester : NSObject
{
}
+ (void) connectWithPorts: (NSArray*)portArray;
+ (void) setServer: (id)anObject;
+ (void) startup;
- (int) doIt;
@end

@implementation	Tester
+ (void) connectWithPorts: (NSArray*)portArray
{
  NSAutoreleasePool	*pool;
  NSConnection		*serverConnection;
  Tester		*serverObject;
      
  pool = [[NSAutoreleasePool alloc] init];
      
  serverConnection = [NSConnection
	  connectionWithReceivePort: [portArray objectAtIndex: 0]
			   sendPort: [portArray objectAtIndex: 1]];
      
  serverObject = [[self alloc] init];
  [(id)[serverConnection rootProxy] setServer: serverObject];
  [serverObject release];
      
  [[NSRunLoop currentRunLoop] run];
  [pool release];
  [NSThread exit];
      
  return;
}

+ (void) setServer: (id)anObject
{
  myServer = [anObject retain];
  NSLog(@"Got %d", [myServer doIt]);  
  exit(0);
}

+ (void) startup
{
  NSPort	*port1;
  NSPort	*port2;
  NSArray	*portArray;
  NSConnection	*conn;

  port1 = [NSPort port];
  port2 = [NSPort port];
            
  conn = [[NSConnection alloc] initWithReceivePort: port1 sendPort: port2];
  [conn setRootObject: self];

  /* Ports switched here. */
  portArray = [NSArray arrayWithObjects: port2, port1, nil];

  [NSThread detachNewThreadSelector: @selector(connectWithPorts:)
			   toTarget: self
			 withObject: portArray];

  return;
}

- (int) doIt
{
  return 42;
}
@end

int
main(int argc, char *argv[], char **env)
{
  NSAutoreleasePool	*pool;

#if LIB_FOUNDATION_LIBRARY || defined(GS_PASS_ARGUMENTS)
   [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  pool = [[NSAutoreleasePool alloc] init];


  [Tester startup];
  [[NSRunLoop currentRunLoop] run];
  [pool release];
  return 0;
}
