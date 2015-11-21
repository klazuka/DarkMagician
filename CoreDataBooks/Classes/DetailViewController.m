/*
 File: DetailViewController.m
 Abstract: The table view controller responsible for displaying detailed information about a single book.  It also allows the user to edit information about a book, and supports undo for editing operations.
 
 When editing begins, the controller creates and set an undo manager to track edits. It then registers as an observer of undo manager change notifications, so that if an undo or redo operation is performed, the table view can be reloaded. When editing ends, the controller de-registers from the notification center and removes the undo manager.
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

#import "DetailViewController.h"
#import "MOBook.h"
#import "EditingViewController.h"


@interface DetailViewController ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *authorLabel;
@property (nonatomic, weak) IBOutlet UILabel *copyrightLabel;

@end


#pragma mark -

@implementation DetailViewController

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  if ([self class] == [DetailViewController class]) {
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
  }
  
  self.tableView.allowsSelectionDuringEditing = YES;
  
  // if the local changes behind our back, we need to be notified so we can update the date
  // format in the table view cells
  //
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(localeChanged:)
                                               name:NSCurrentLocaleDidChangeNotification
                                             object:nil];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSCurrentLocaleDidChangeNotification
                                                object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];
  
  // Redisplay the data.
  [self updateInterface];
  [self updateRightBarButtonItemState];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  
  [super setEditing:editing animated:animated];
  
  // Hide the back button when editing starts, and show it again when editing finishes.
  [self.navigationItem setHidesBackButton:editing animated:animated];
  
  if (editing) {
    // nop
  }
  else {
    // Save the changes.
    NSError *error;
    if (![self.book.managedObjectContext save:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
}

- (void)updateInterface {
  
  self.authorLabel.text = self.book.author;
  self.titleLabel.text = self.book.title;
  self.copyrightLabel.text = [self.dateFormatter stringFromDate:self.book.copyright];
}

- (void)updateRightBarButtonItemState {
  
  // Conditionally enable the right bar button item -- it should only be enabled if the book is in a valid state for saving.
  self.navigationItem.rightBarButtonItem.enabled = [self.book validateForUpdate:NULL];
}


#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  // Only allow selection if editing.
  if (self.editing) {
    return indexPath;
  }
  return nil;
}

/*
 Manage row selection: If a row is selected, create a new editing view controller to edit the property associated with the selected row.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (self.editing) {
    [self performSegueWithIdentifier:@"EditSelectedItem" sender:self];
  }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
  
  return NO;
}


#pragma mark - Date Formatter

- (NSDateFormatter *)dateFormatter {
  
  static NSDateFormatter *dateFormatter = nil;
  if (dateFormatter == nil) {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  }
  return dateFormatter;
}


#pragma mark - Segue management

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  
  if ([[segue identifier] isEqualToString:@"EditSelectedItem"]) {
    
    EditingViewController *controller = (EditingViewController *)[segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    controller.editedObject = self.book;
    switch (indexPath.row) {
      case 0: {
        controller.editedFieldKey = @"title";
        controller.editedFieldName = NSLocalizedString(@"title", @"display name for title");
      } break;
      case 1: {
        controller.editedFieldKey = @"author";
        controller.editedFieldName = NSLocalizedString(@"author", @"display name for author");
      } break;
      case 2: {
        controller.editedFieldKey = @"copyright";
        controller.editedFieldName = NSLocalizedString(@"copyright", @"display name for copyright");
      } break;
    }
  }
}


#pragma mark - Locale changes

- (void)localeChanged:(NSNotification *)notif
{
  // the user changed the locale (region format) in Settings, so we are notified here to
  // update the date format in the table view cells
  //
  [self updateInterface];
}

@end

