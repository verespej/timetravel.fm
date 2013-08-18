//
//  Guess_The_IntroViewController.m
//  Guess The Intro
//
//  Created by Daniel Kennett on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Guess_The_IntroViewController.h"
#import "SPArrayExtensions.h"
#import <QuartzCore/QuartzCore.h>

@interface Guess_The_IntroViewController ()
@property (weak, nonatomic) IBOutlet UILabel *prevYearLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextYearLabel;
@property (nonatomic, readwrite, strong) NSMutableDictionary * availablePlaylists;
@property int trackNumber;
@property (nonatomic, readwrite, strong) NSDate *lastDataArrivalTime;
@property bool attemptingBleConnection;
@end

@implementation Guess_The_IntroViewController

@synthesize currentYearLabel;
@synthesize isLoadingView;
@synthesize track1Button;

@synthesize playbackManager;

@synthesize firstSuggestion;
@synthesize canPushOne;

@synthesize year;

@synthesize ble;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.track1Button.layer.borderColor = [UIColor darkGrayColor].CGColor;
	self.track1Button.layer.borderWidth = 1.0;
			
	[self addObserver:self forKeyPath:@"firstSuggestion.name" options:NSKeyValueObservingOptionInitial context:nil];
	[self addObserver:self forKeyPath:@"firstSuggestion.artists" options:NSKeyValueObservingOptionInitial context:nil];
	[self addObserver:self forKeyPath:@"firstSuggestion.album.cover.image" options:NSKeyValueObservingOptionInitial context:nil];
	
	[self addObserver:self forKeyPath:@"canPushOne" options:NSKeyValueObservingOptionInitial context:nil];
	
	[self addObserver:self forKeyPath:@"year" options:NSKeyValueObservingOptionInitial context:nil];
    
    [self.playbackManager addObserver:self forKeyPath:@"currentTrack" options:NSKeyValueObservingOptionNew context:NULL];
    self.trackNumber = 0;
    
    UITapGestureRecognizer* gesturePrev = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(movePrevYear:)];
    [[self prevYearLabel] setUserInteractionEnabled:YES];
    [[self prevYearLabel] addGestureRecognizer:gesturePrev];
    
    UITapGestureRecognizer* gestureNext = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveNextYear:)];
    [[self nextYearLabel] setUserInteractionEnabled:YES];
    [[self nextYearLabel] addGestureRecognizer:gestureNext];
    
    UITapGestureRecognizer* gestureTogglePlay = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlay:)];
    [[self currentYearLabel] setUserInteractionEnabled:YES];
    [[self currentYearLabel] addGestureRecognizer:gestureTogglePlay];
    
    self.ble = [[BLE alloc] init];
    [self.ble controlSetup:1];
    self.ble.delegate = self;
    
    self.attemptingBleConnection = false;
    self.lastDataArrivalTime = [NSDate date];
}

- (void)viewDidUnload
{
    [self setCurrentYearLabel:nil];
    [self setTrack1Button:nil];
	[self setIsLoadingView:nil];
    [self setNextYearLabel:nil];
    [self setPrevYearLabel:nil];
	
	[self removeObserver:self forKeyPath:@"firstSuggestion.name"];
	[self removeObserver:self forKeyPath:@"firstSuggestion.artists"];
	[self removeObserver:self forKeyPath:@"firstSuggestion.album.cover.image"];
	[self removeObserver:self forKeyPath:@"canPushOne"];
	[self removeObserver:self forKeyPath:@"year"];
    [self removeObserver:self forKeyPath:@"currentTrack"];

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath hasPrefix:@"firstSuggestion"]) {
		[self.track1Button setImage:self.firstSuggestion.album.cover.image 
						   forState:UIControlStateNormal];
	} else if ([keyPath hasPrefix:@"canPush"]) {
		self.track1Button.enabled = self.canPushOne;
    } else if ([keyPath isEqualToString:@"year"]) {
        NSLog(@"Year: %@", keyPath);
    } else if ([keyPath isEqualToString:@"currentTrack"]) {
        SPPlaybackManager *sppm = (SPPlaybackManager *)object;
        if (!sppm.currentTrack) {
            [self startNewYear];
        }
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void) connectionMonitor:(NSTimer *)timer {
    double secondsSinceLastDataArrival = [self.lastDataArrivalTime timeIntervalSinceNow] * -1.0;
    if (!self.attemptingBleConnection) {
        if (!self.ble.activePeripheral || !self.ble.activePeripheral.isConnected) {
            // Not connected to a device, so try to connect to one
            if (self.ble.peripherals) {
                self.ble.peripherals = nil;
            }
            
            // Give 10 seconds until data is expected to arrive
            self.lastDataArrivalTime = [[NSDate date] dateByAddingTimeInterval:10];
            
            self.attemptingBleConnection = true;
            [self.ble findBLEPeripherals:3];
            [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(bleConnectionTimer:) userInfo:nil repeats:NO];
        } else if (secondsSinceLastDataArrival > 4.0) {
            if (self.ble.activePeripheral.isConnected)
            {
                [[self.ble CM] cancelPeripheralConnection:[ble activePeripheral]];
            }
        }
    }
}

-(void) bleConnectionTimer:(NSTimer *)timer
{
    if (self.ble.peripherals.count > 0)
    {
        // Connect to first peripheral found
        // TODO: Identify device
        [self.ble connectPeripheral:[ble.peripherals objectAtIndex:0]];
    }
    
    self.attemptingBleConnection = false;
}


#pragma mark - BLE delegate

- (void)bleDidDisconnect {
    NSLog(@"Disconnected");
}

-(void) bleDidUpdateRSSI:(NSNumber *) rssi {
}

-(void) bleDidConnect {
    NSLog(@"Connected");
}

// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    //NSLog(@"Received data of length %d", length);
    self.lastDataArrivalTime = [NSDate date];
    
    for (int i = 0; i < length; i+=5)
    {
        if (data[i] == 0x0A) {
            int low = (int)data[i+1];
            int high = (int)data[i+2];
            int val1 = (high << 8) + low;
            
            low = (int)data[i+3];
            high = (int)data[i+4];
            int val2 = (high << 8) + low;
            
            NSLog(@"Received %d, %d", val1, val2);
            
            int temp = self.year;
            double range = (double)(2013 - 1950);
            double percent = (double)val1 / 1023.0;
            self.year = 1950 + (int)(range * percent);
            if (temp != self.year) {
                NSLog(@"Adjusting to year %d", self.year);
                [self startNewYear];
            }
            
            int volume = (double)val2 / 1023.0;
            [self.playbackManager setVolume:volume];
            
        } else if (data[i] == 0x0B) {
            NSLog(@"Received keep-alive");
        }
    }
}

#pragma mark -
#pragma mark SPLoginViewController Delegate

-(void)loginViewController:(SPLoginViewController *)controller didCompleteSuccessfully:(BOOL)didLogin {
	
	[self dismissModalViewControllerAnimated:YES];

	self.isLoadingView.hidden = NO;
    [self.isLoadingView startAnimating];

    self.year = 2013;
	
	[self waitAndFillTrackPool];
}

#pragma mark -
#pragma mark SPSession Delegates

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {
	// Invoked by SPSession after a successful login.
    NSLog(@"Logged in");
    
    // Start the BLE connection
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionMonitor:) userInfo:nil repeats:YES];
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
    
	// Invoked by SPSession after a failed login.
	// Forward to login view
    if ([self.modalViewController respondsToSelector:@selector(session:didFailToLoginWithError:)])
		[self.modalViewController performSelector:@selector(session:didFailToLoginWithError:) withObject:aSession withObject:error];
}

-(void)sessionDidLogOut:(SPSession *)aSession; {}
-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
													message:aMessage
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

#pragma mark -
#pragma mark UI Actions

- (IBAction)moveNextYear:(id)sender {
    NSInteger temp = self.year;
    self.year++;
    while (self.year <= 2013 && ![self.availablePlaylists objectForKey:[NSString stringWithFormat:@"%d", self.year]] ) {
        self.year++;
    }
    if (self.year > 2013) {
        self.year = temp;
    }
	self.canPushOne = NO;
    [self startNewYear];
}

- (IBAction)movePrevYear:(id)sender {
    NSInteger temp = self.year;
    self.year--;
    while (self.year >= 1950 && ![self.availablePlaylists objectForKey:[NSString stringWithFormat:@"%d", self.year]] ) {
        self.year--;
    }
    if (self.year < 1950) {
        self.year = temp;
    }
	self.canPushOne = NO;
    [self startNewYear];
}

-(IBAction) togglePlay:(id)sender {
    if (!self.playbackManager.currentTrack) {
        [self startNewYear];
    } else {
        self.playbackManager.isPlaying = !self.playbackManager.isPlaying;
    }
}

- (IBAction)changeVolumeSlider:(UISlider *)sender {
    [self.playbackManager setVolume:[sender value]];
}

#pragma mark -
#pragma mark Finding Tracks

-(void)waitAndFillTrackPool {
	if (self.isLoadingView.isHidden) {
        self.isLoadingView.hidden = NO;
        [self.isLoadingView startAnimating];
    }
    
	[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedession, NSArray *notLoadedSession) {
		
		// The session is logged in and loaded — now wait for the userPlaylists to load.
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Session loaded.");
		
		[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession].userPlaylists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedContainers, NSArray *notLoadedContainers) {
			
			// User playlists are loaded — wait for playlists to load their metadata.
			NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Container loaded.");
			
			NSMutableArray *playlists = [NSMutableArray array];
			[playlists addObjectsFromArray:[SPSession sharedSession].userPlaylists.flattenedPlaylists];
			
			[SPAsyncLoading waitUntilLoaded:playlists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedPlaylists, NSArray *notLoadedPlaylists) {
				
				// All of our playlists have loaded their metadata — wait for all tracks to load their metadata.
				NSLog(@"[%@ %@]: %@ of %@ playlists loaded.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), 
					  [NSNumber numberWithInteger:loadedPlaylists.count], [NSNumber numberWithInteger:loadedPlaylists.count + notLoadedPlaylists.count]);
                
                if (!self.availablePlaylists) {
                    self.availablePlaylists = [[NSMutableDictionary alloc] init];
                }
                
                for (SPPlaylist *playlistEntry in loadedPlaylists) {
                    [self.availablePlaylists setObject:playlistEntry forKey:playlistEntry.name];
                }
				
				NSArray *playlistItems = [loadedPlaylists valueForKeyPath:@"@unionOfArrays.items"];
				NSArray *tracks = [self tracksFromPlaylistItems:playlistItems];
				
				[SPAsyncLoading waitUntilLoaded:tracks timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedTracks, NSArray *notLoadedTracks) {
					
					// All of our tracks have loaded their metadata. Hooray!
					NSLog(@"[%@ %@]: %@ of %@ tracks loaded.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), 
						  [NSNumber numberWithInteger:loadedTracks.count], [NSNumber numberWithInteger:loadedTracks.count + notLoadedTracks.count]);
					
					/*for (SPTrack *aTrack in loadedTracks) {
						if (aTrack.availability == SP_TRACK_AVAILABILITY_AVAILABLE && [aTrack.name length] > 0) {
                        }
					}*/
					
                    
					//[self startNewYear];
                    
                    [self.isLoadingView stopAnimating];
					self.isLoadingView.hidden = YES;
				}];
			}];
		}];
	}];
}

-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder {
	
	NSMutableArray *playlists = [NSMutableArray arrayWithCapacity:[[aFolder playlists] count]];
	
	for (id playlistOrFolder in aFolder.playlists) {
		if ([playlistOrFolder isKindOfClass:[SPPlaylist class]]) {
			[playlists addObject:playlistOrFolder];
		} else {
			[playlists addObjectsFromArray:[self playlistsInFolder:playlistOrFolder]];
		}
	}
	return [NSArray arrayWithArray:playlists];
}

-(NSArray *)tracksFromPlaylistItems:(NSArray *)items {
	
	NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:items.count];
	
	for (SPPlaylistItem *anItem in items) {
		if (anItem.itemClass == [SPTrack class]) {
			[tracks addObject:anItem.item];
		}
	}
	
	return [NSArray arrayWithArray:tracks];
}



#pragma mark -
#pragma mark Game Logic

-(void)startNewYear {

    if (self.availablePlaylists.count < 1) {
        NSLog(@"Tried to play before ready");
        return;
    }
	
	// Starting a new year means resetting, selecting tracks then starting the timer again 
	// when the audio starts playing.
	
    if (self.playbackManager.isPlaying) {
        self.playbackManager.isPlaying = NO;
    }
    
	self.firstSuggestion = nil;
    
    NSString *yearAsString = [NSString stringWithFormat:@"%d", self.year];

    SPPlaylist *pl = (SPPlaylist *)[self.availablePlaylists objectForKey:yearAsString];
    if (!pl) {
        NSString *key = [[self.availablePlaylists keyEnumerator] nextObject];
        
        self.year = [key integerValue];
        yearAsString = [NSString stringWithFormat:@"%d", self.year];
        
        pl = (SPPlaylist *)[self.availablePlaylists objectForKey:yearAsString];
    }
    [[self currentYearLabel] setText:yearAsString];
    
    NSArray *tracks = [self tracksFromPlaylistItems:pl.items];
    self.trackNumber = (self.trackNumber + 1) % tracks.count;
    SPTrack *theOne = [self tracksFromPlaylistItems:pl.items][self.trackNumber];
    
    // TODO: Handle advancing playlist on song finish
    
    self.firstSuggestion = theOne;
    
    //Disable buttons until playback starts
    self.canPushOne = NO;
    
    [self startPlaybackOfTrack:theOne];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[self waitAndFillTrackPool];
}

#pragma mark -
#pragma mark Playback

- (void)startPlaybackOfTrack:(SPTrack *)aTrack {
	
	[SPAsyncLoading waitUntilLoaded:aTrack timeout:5.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
		[self.playbackManager playTrack:aTrack callback:^(NSError *error) {
			
			if (!error) return;
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't Play"
															message:error.localizedDescription
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}];
	}];
}

-(void)playbackManagerWillStartPlayingAudio:(SPPlaybackManager *)aPlaybackManager {
	self.canPushOne = YES;	
}


- (void)dealloc {
}

@end
