eye-fi-server
=============

Provides an Eye-Fi server for objective-c applications

## Usage
1. To add the library to your project with Cocoapods, add this line to your Podfile:
    ```
    pod 'CWEyeFiServer', :git => 'https://github.com/codewhisper/eye-fi-server.git'
    ```

2. Import CWEyeFiServer.h, create server object and start. Make sure to add your
own upload key, usually you can find it in _~/Library/Eye-Fi/Settings.xml_
    ```objc
    #import "CWEyeFiServer.h"
    [...]
    CWEyeFiServer *_eyeFiServer = [[CWEyeFiServer alloc] initWithUploadKey:@"112233"];
    NSError *error;
    [_eyeFiServer start:&error];
    ```

3. Add observer for file updates notifications
    ```objc
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileStatusNotification:) name:CWNotificationFileStatus object:nil];
    ```

* Check the Example directory for a working example
