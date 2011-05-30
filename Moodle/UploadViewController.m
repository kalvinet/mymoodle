//
//  UploadViewController.m
//  Moodle
//
//  Created by Dongsheng Cai on 17/04/11.
//  Copyright 2011 Moodle. All rights reserved.
//

#import "UploadViewController.h"
#import "Constants.h"
#import "PreviewViewController.h"
#import "RecorderViewController.h"
#import "MoodleImagePickerController.h"
#import "MoodleMedia.h"


@implementation UploadViewController

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
    self.title = NSLocalizedString(@"Upload", "Upload");
    self.view.backgroundColor = UIColorFromRGB(ColorBackground);
    int x = 40;
    int y = 60;
    int width = 240;
    int height = 60;
    TTButton *button = [TTButton buttonWithStyle:@"toolbarButton:" title: NSLocalizedString(@"Browse photo albums", "Browse photo albums")];
    [button addTarget:self 
               action:@selector(loadGallery:)
                forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Browse photo albums" forState:UIControlStateNormal];
    button.frame = CGRectMake(x, y, width, height);
    [self.view addSubview:button];
    

    button = [TTButton buttonWithStyle:@"toolbarButton:" title: NSLocalizedString(@"Take a picture or video", "Take a picture or video")];
    [button addTarget:self 
               action:@selector(loadCamera:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Take a picture or video" forState:UIControlStateNormal];
    button.frame = CGRectMake(x, (2*y) + height, width, height);
    [self.view addSubview:button];
    
    
    button = [TTButton buttonWithStyle:@"toolbarButton:" title: NSLocalizedString(@"Record audio", "Record audio")];
    [button addTarget:self 
               action:@selector(loadRecorder:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Record audio" forState:UIControlStateNormal];
    button.frame = CGRectMake(x, (3*y) + (2*height), width, height);
    [self.view addSubview:button];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//- (void)viewDidLoad
//{
//   [super viewDidLoad];
//}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


-(void)loadPreview: (NSString *)filepath withFilename: (NSString *)filename {
    PreviewViewController *previewViewController = [[PreviewViewController alloc] init];
    //set the dashboard back button just before to push the settings view
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"upload", "upload") style: UIBarButtonItemStyleBordered target: nil action: nil];
    [[self navigationItem] setBackBarButtonItem: newBackButton];
    [newBackButton release];
    previewViewController.fileName = filename;
    previewViewController.filePath = filepath;
    [self.navigationController pushViewController:previewViewController animated:YES];
    [previewViewController release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    NSString *strtimestamp = [now description];
    //NSURL *mediaUrl;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    NSLog(@"%@", info);
    if ([mediaType isEqualToString: @"public.image"]) {
        UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        fileName = [NSString stringWithFormat:@"%@.jpg", strtimestamp];
        filePath = [NSString stringWithFormat:@"%@/%@", DOCUMENTS_FOLDER, fileName];
        [UIImageJPEGRepresentation(image, 1.0f) writeToFile: filePath atomically:YES];
        if ([info objectForKey:@"UIImagePickerControllerMediaMetadata"]) {
            // upload now!
            [self uploadAction];
        } else {
            [self loadPreview: filePath withFilename: fileName];
        }
    } else if ([mediaType isEqualToString:@"public.movie"]) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *filename = [NSString stringWithFormat:@"%@.mov", strtimestamp];
        NSData *data = [NSData dataWithContentsOfURL:videoURL];
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", DOCUMENTS_FOLDER, filename];
        [data writeToFile:filepath atomically:YES];
        // upload now!
        [self uploadAction];
    }
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)loadGallery:(id)sender {
    MoodleImagePickerController *imagePicker = [[MoodleImagePickerController alloc] init];
    [[[UIApplication sharedApplication] keyWindow] setRootViewController: imagePicker];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentModalViewController:imagePicker animated:YES]; 
    [imagePicker release];
    
}

- (void)loadCamera:(id)sender {
    if ([MoodleImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        MoodleImagePickerController *imagePicker = [[MoodleImagePickerController alloc] init];
        [[[UIApplication sharedApplication] keyWindow] setRootViewController: imagePicker];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: imagePicker.sourceType];
        [self presentModalViewController:imagePicker animated:YES];
        [imagePicker release];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error accessing camera" message:@"Device does not support a camera" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
}

- (void)loadRecorder:(id)sender {
    [[TTNavigator navigator] openURLAction:[[TTURLAction actionWithURLPath:@"tt://recorder/"] applyAnimated:YES]]; 
}

- (void)uploadAction {
    NSLog(@"ready to upload");
    // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
    HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];
	
    // Regiser for HUD callbacks so we can remove it from the window at the right time
    HUD.delegate = self;
    // Show the HUD while the provided method executes in a new thread
    [HUD showWhileExecuting:@selector(upload:) onTarget:[MoodleMedia class] withObject:nil animated:YES];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    [HUD release];
	HUD = nil;
}
@end