
## XNU Mach Message IPC
Here I explored some of the methods that are used for Inter-process communication on MacOS XNU kernel as part of an assignment that I had been given. I had no previous experience with Objective -C, so I had to research and learn it from scratch.

Some of the resources that I used which was really helpful: 
- Objective-C Essential Training on linkedin course
- Apple developer website
- IOS - EEZY TUTORIALS - https://eezytutorials.com/ios/nsfilemanager-by-example.php#.Y5ByPS8RqrA
- Damian Malarczyk Mach_msg tutorial - https://dmcyk.xyz


Server Functionalities:
		- Communication through mach messaging
                - Receive messages from client 
		- send the same data back to the client process
		- Visible by other processes
		- Cannot be blocked by a single client
		- Send/receive data up to 1024 bytes

Client:
	  the client should be able to
		- find the server
		- send data to server
		- receive the same data back from server
		- check that the data is the same
    
    
    # To compile the code use: clang -framework Foundation main.m -o Server/Client
    # Or just run it with xcode
