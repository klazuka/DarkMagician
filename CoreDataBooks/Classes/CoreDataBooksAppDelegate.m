/*
 File: CoreDataBooksAppDelegate.m
 Abstract: Application delegate to set up the Core Data stack and configure the first view and navigation controllers.
 Version: 1.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "CoreDataBooksAppDelegate.h"
#import "RootViewController.h"
#import "MOBook.h"
#import "CoreDataBooks-Swift.h"

@interface CoreDataBooksAppDelegate ()

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


#pragma mark -

@implementation CoreDataBooksAppDelegate

@synthesize managedObjectModel=_managedObjectModel, managedObjectContext=_managedObjectContext, persistentStoreCoordinator=_persistentStoreCoordinator;

- (BOOL)dbIsEmpty
{
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MOBook"];
  NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:NULL];
  return count == 0;
}

- (void)dbPopulate
{
  NSManagedObjectContext *moc = self.managedObjectContext;
  
  NSDictionary *cannedData = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CannedData" ofType:@"plist"]];
  
  NSArray *books = cannedData[@"books"];
  
  for (NSDictionary *bookDict in books) {
    MOBook *book = (MOBook *)[NSEntityDescription insertNewObjectForEntityForName:@"MOBook" inManagedObjectContext:moc];
    book.author = bookDict[@"author"];
    book.title = bookDict[@"title"];
    book.copyright = bookDict[@"copyright"];
  }
  
  [self saveContext];
}

#pragma mark - Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
  if ([self dbIsEmpty]) {
    [self dbPopulate];
  }
  
  UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
  
  UINavigationController *leftNav = splitViewController.viewControllers[0];
  UINavigationController *rightNav = splitViewController.viewControllers[1];
  
  RootViewController *rootViewController = (RootViewController *)leftNav.viewControllers[0];
  rootViewController.managedObjectContext = self.managedObjectContext;
  
  BookListVC *bookListVC = (BookListVC *)rightNav.viewControllers[0];
  bookListVC.moc = self.managedObjectContext;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  [self saveContext];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [self saveContext];
}

- (void)saveContext
{
  NSError *error;
  if (_managedObjectContext != nil) {
    if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
}


#pragma mark - Core Data stack

/*
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext
{
  if (_managedObjectContext != nil) {
    return _managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil) {
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator: coordinator];
  }
  return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataBooks" withExtension:@"momd"];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return _managedObjectModel;
}

/*
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
  if (_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
  NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataBooks.CDBStore"];
  
  NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
  
  //  NSString *storeType = NSSQLiteStoreType;
  
  NSString *storeType = @"com.circle38.KStore";
  [NSPersistentStoreCoordinator registerStoreClass:[KStore class] forStoreType:@"com.circle38.KStore"];
  
  NSError *error;
  if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:options error:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
  
  return _persistentStoreCoordinator;
}


#pragma mark - Application's documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
