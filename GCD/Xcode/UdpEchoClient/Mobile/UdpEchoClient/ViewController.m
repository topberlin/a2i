#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "DDLog.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface ViewController ()
{
	long tag;
	GCDAsyncUdpSocket *udpSocket;
	
	NSMutableString *log;
}

@end


@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		log = [[NSMutableString alloc] init];
	}
	return self;
}

- (void)setupSocket
{
	// Setup our socket.
	// The socket will invoke our delegate methods using the usual delegate paradigm.
	// However, it will invoke the delegate methods on a specified GCD delegate dispatch queue.
	// 
	// Now we can configure the delegate dispatch queues however we want.
	// We could simply use the main dispatc queue, so the delegate methods are invoked on the main thread.
	// Or we could use a dedicated dispatch queue, which could be helpful if we were doing a lot of processing.
	// 
	// The best approach for your application will depend upon convenience, requirements and performance.
	// 
	// For this simple example, we're just going to use the main thread.
	
	udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	NSError *error = nil;
	
	if (![udpSocket bindToPort:0 error:&error])
	{
		[self logError:FORMAT(@"Error binding: %@", error)];
		return;
	}
	if (![udpSocket beginReceiving:&error])
	{
		[self logError:FORMAT(@"Error receiving: %@", error)];
		return;
	}
	
	[self logInfo:@"Ready"];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (udpSocket == nil)
	{
		[self setupSocket];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(keyboardWillShow:)
	                                             name:UIKeyboardWillShowNotification 
	                                           object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(keyboardWillHide:)
	                                             name:UIKeyboardWillHideNotification
	                                           object:nil];
    
    
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getKeyboardHeight:(float *)keyboardHeightPtr
        animationDuration:(double *)animationDurationPtr
                     from:(NSNotification *)notification
{
	float keyboardHeight;
	double animationDuration;
	
	// UIKeyboardCenterBeginUserInfoKey:
	// The key for an NSValue object containing a CGRect
	// that identifies the start frame of the keyboard in screen coordinates.
	
	CGRect beginRect = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect endRect   = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		keyboardHeight = ABS(beginRect.origin.x - endRect.origin.x);
	}
	else
	{
		keyboardHeight = ABS(beginRect.origin.y - endRect.origin.y);
	}
	
	// UIKeyboardAnimationDurationUserInfoKey
	// The key for an NSValue object containing a double that identifies the duration of the animation in seconds.
	
	animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	if (keyboardHeightPtr) *keyboardHeightPtr = keyboardHeight;
	if (animationDurationPtr) *animationDurationPtr = animationDuration;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	float keyboardHeight = 0.0F;
	double animationDuration = 0.0;
	
	[self getKeyboardHeight:&keyboardHeight animationDuration:&animationDuration from:notification];
	
	CGRect webViewFrame = webView.frame;
	webViewFrame.size.height -= keyboardHeight;
	
	void (^animationBlock)(void) = ^{
		
		webView.frame = webViewFrame;
	};
	
	UIViewAnimationOptions options = 0;
	
	[UIView animateWithDuration:animationDuration
	                      delay:0.0
	                    options:options
	                 animations:animationBlock
	                 completion:NULL];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	float keyboardHeight = 0.0F;
	double animationDuration = 0.0;
	
	[self getKeyboardHeight:&keyboardHeight animationDuration:&animationDuration from:notification];
	
	CGRect webViewFrame = webView.frame;
	webViewFrame.size.height += keyboardHeight;
	
	void (^animationBlock)(void) = ^{
		
		webView.frame = webViewFrame;
	};
	
	UIViewAnimationOptions options = 0;
	
	[UIView animateWithDuration:animationDuration
	                      delay:0.0
	                    options:options
	                 animations:animationBlock
	                 completion:NULL];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	DDLogError(@"webView:didFailLoadWithError: %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)sender
{
	NSString *scrollToBottom = @"window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);";
	
    [sender stringByEvaluatingJavaScriptFromString:scrollToBottom];
}

- (void)logError:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#B40404\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (void)logInfo:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#6A0888\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>\n%@\n</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (void)logMessage:(NSString *)msg
{
	NSString *prefix = @"<font color=\"#000000\">";
	NSString *suffix = @"</font><br/>";
	
	[log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
	
	NSString *html = [NSString stringWithFormat:@"<html><body>%@</body></html>", log];
	[webView loadHTMLString:html baseURL:nil];
}

- (IBAction)send:(id)sender
{
	NSString *host = @"gl.justus.berlin";
	if ([host length] == 0)
	{
		[self logError:@"Address required"];
		return;
	}
	
	int port = 8555;
	if (port <= 0 || port > 65535)
	{
		[self logError:@"Valid port required"];
		return;
	}
	
	NSString *msg = messageField.text;

    
    NSLog(@"FINE");
    
    struct sdlmsg message;        /* Declare Book1 of type Book */
    
    
    //NSLog(@"MouseX Values: %d\n", sdlmsg_mousekey(&message)->mousex);
    NSData *data;
    
    sdlmsg_mousekey(&message, 3, 0, 100, 100);
	data = [NSData dataWithBytes:&message length:sizeof(message)];
	[udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
    tag++;
    
    sdlmsg_mousekey(&message, 2, 1, 100, 100);
    data = [NSData dataWithBytes:&message length:sizeof(message)];
    [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
    tag++;
    
    sdlmsg_mousekey(&message, 2, 0, 100, 100);
    data = [NSData dataWithBytes:&message length:sizeof(message)];
    [udpSocket sendData:data toHost:host port:port withTimeout:-1 tag:tag];
    tag++;
    
    
    
	
	[self logMessage:FORMAT(@"SENT (%i): %@", (int)tag, msg)];
	

}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	// You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                               fromAddress:(NSData *)address
                                         withFilterContext:(id)filterContext
{
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
		[self logMessage:FORMAT(@"RECV: %@", msg)];
	}
	else
	{
		NSString *host = nil;
		uint16_t port = 0;
		[GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
		
		[self logInfo:FORMAT(@"RECV: Unknown message from: %@:%hu", host, port)];
	}
}

struct sdlmsg *sdlmsg_mousekey(struct sdlmsg *msg, char msgtype, char is_pressed, unsigned short mousex, unsigned short mousey) {
    //ga_error("sdl client: button event btn=%u pressed=%u\n", button, pressed);
    bzero(msg, sizeof(struct sdlmsg));
    msg->msgsize = htons(sizeof(struct sdlmsg));
    msg->msgtype = msgtype;
    msg->is_pressed = is_pressed; //1 heisst pressed
    msg->mousebutton = 1; //1 heisst SDL_BUTTON_LEFT
    msg->mousex = htons(mousex);
    msg->mousey = htons(mousey);
    msg->mouseRelX = htons(mousex);
    msg->mouseRelY = htons(mousey);
    
    return msg;
}

struct sdlmsg {
    unsigned short msgsize;		// size of this data-structure
    // every message MUST start from a
    // unsigned short message size
    // the size includes the 'msgsize'
    unsigned char msgtype;
    unsigned char which;
    unsigned char is_pressed;	// for keyboard/mousekey
    unsigned char mousebutton;	// mouse button
    unsigned char mousestate;	// mouse state - key combinations for motion
    //unsigned char unused1[2];		// padding - 3+1 chars
    //unsigned short scancode;	// keyboard scan code
    //int sdlkey;			// SDLKey value
    //unsigned int unicode;		// unicode or ASCII value
    
    //unsigned short sdlmod;		// SDLMod value
    unsigned char relativeMouseMode;// relative mouse mode?
    unsigned short mousex;		// mouse position (big-endian)
    unsigned short mousey;		// mouse position (big-endian)
    unsigned short mouseRelX;	// mouse relative position (big-endian)
    unsigned short mouseRelY;	// mouse relative position (big-endian)
    
//    unsigned char padding[8];	// reserved padding
};

@end
