
## XNU Mach Message IPC
Here I explored some of the methods that are used for Inter-process communication on MacOS XNU kernel as part of an assignment that I had been given. I had no previous experience with Objective -C, so I had to research and learn it from scratch. feel free to leave any comments and feedback below, throw ideas on how to make it better.

Mach IPC is part of the XNU OS developed by apple and it used to exchange messages between two end-points. Mach message is the core building block of Mach’s IPC, and is designed to be suitable for passing between any two ports whether local to the same machine, or on some remote host. Tasks send messages to ports. Messages sent to a port are delivered and received in the order in which they were sent. Messages contain a fixed-size header and a variable amount of typed data following the header. The header describes the destination and size of the message. 

Tasks operate on a port to send and receive messages by getting rights for the port. 
Multiple tasks can hold send rights, for a port. which grant the ability to send a single message. 
Only one task can hold the receive capability, or receive right, for a port. 
Port rights can be transferred between tasks via messages. 
The sender of a message can specify in the message body that the message contains a port right.
If a message contains a receive right for a port, then the receive right is removed from the sender of the message and the right is transferred to the receiver of the message. While the receive right is in transit, tasks holding send rights can still send messages to the port, and they stand in line until a task acquires the receive right and uses it to receive the messages. 


Some of the resources that I used which was really helpful: 
- Objective-C Essential Training on linkedin course
- Apple developer website
- IOS - EEZY TUTORIALS - https://eezytutorials.com/ios/nsfilemanager-by-example.php#.Y5ByPS8RqrA
- Damian Malarczyk Mach_msg tutorial - https://dmcyk.xyz


Server Functionalities:
		- Communication through mach messaging.
                - Receive messages from client.
		- Send the same data back to the client process.
		- The server will create a file in the documents folder whenever a message received
		- Save the messgae content to the file.
		- The file will be saved under the process ID name which is represent the Client ID.
		- If the server will get the same data, the file will be deleted automatically.
		- Visible by other processes.
		- Cannot be blocked by a single client.
		- Send/receive data up to 1024 bytes.

Client:
	  the client should be able to
		- find the server.
		- send data to server.
		- receive the same data back from server.
		- check that the data is the same.
    
    
    # To compile the code use: clang -framework Foundation main.m  
    # Or just run it with xcode
