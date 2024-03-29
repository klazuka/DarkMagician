/*
 File: EditingViewController.m
 Abstract: The table view controller responsible for editing a field of data -- either text or a date.
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

#import "EditingViewController.h"

@interface EditingViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;

@property (nonatomic, readonly, getter=isEditingDate) BOOL editingDate;

@end


#pragma mark -

@implementation EditingViewController
{
  BOOL _hasDeterminedWhetherEditingDate;
  BOOL _editingDate;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  // Set the title to the user-visible name of the field.
  self.title = self.editedFieldName;
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // Configure the user interface according to state.
  if (self.editingDate) {
    
    self.textField.hidden = YES;
    self.datePicker.hidden = NO;
    NSDate *date = [self.editedObject valueForKey:self.editedFieldKey];
    if (date == nil) {
      date = [NSDate date];
    }
    self.datePicker.date = date;
  }
  else {
    
    self.textField.hidden = NO;
    self.datePicker.hidden = YES;
    self.textField.text = [self.editedObject valueForKey:self.editedFieldKey];
    self.textField.placeholder = self.title;
    [self.textField becomeFirstResponder];
  }
}


#pragma mark - Save and cancel operations

- (IBAction)save:(id)sender
{
  // Pass current value to the edited object, then pop.
  if (self.editingDate) {
    [self.editedObject setValue:self.datePicker.date forKey:self.editedFieldKey];
  }
  else {
    [self.editedObject setValue:self.textField.text forKey:self.editedFieldKey];
  }
  
  [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)cancel:(id)sender
{
  // Don't pass current value to the edited object, just pop.
  [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Manage whether editing a date

- (void)setEditedFieldKey:(NSString *)editedFieldKey
{
  if (![_editedFieldKey isEqualToString:editedFieldKey]) {
    _hasDeterminedWhetherEditingDate = NO;
    _editedFieldKey = editedFieldKey;
  }
}


- (BOOL)isEditingDate
{
  if (_hasDeterminedWhetherEditingDate == YES) {
    return _editingDate;
  }
  
  NSEntityDescription *entity = [self.editedObject entity];
  NSAttributeDescription *attribute = [entity attributesByName][self.editedFieldKey];
  NSString *attributeClassName = [attribute attributeValueClassName];
  
  if ([attributeClassName isEqualToString:@"NSDate"]) {
    _editingDate = YES;
  }
  else {
    _editingDate = NO;
  }
  
  _hasDeterminedWhetherEditingDate = YES;
  return _editingDate;
}


@end

