
---
title: "machmsg IPC programming (Objective C)"
description: 
excerpt: "Objective C server/client IPC by Tom Rosenzweig"
---


## XNU Mach Message IPC

As part of an assigned task, I delved into several methods utilized for inter-process communication on XNU kernel. Despite lacking prior familiarity with Objective-C, I dedicated myself to researching and mastering it from scratch. I welcome any constructive feedback or suggestions to enhance my findings.

#### The assignment:

[!] Design the following Server/Client IPC.

Server:
	
	This server has two functionalities
		- save data sent by another process
		- send data back to process

	Other requirements:

		- Visible by other processes
			[h] bootstrap_check_in
		- Cannot be blocked by a single client
		- Communication through mach messaging
			[h] ports, RECV, SEND
		- Send/receive data up to 1024 bytes
Client:
	
	the client should be able to

		- find the server
		- send data to server
		- receive data back from server
		- check that the data is the same

------------------------------------------------------------

## XNU Kernel
The XNU kernel is the core operating system component used in macOS, iOS, tvOS, and watchOS. XNU is an acronym that stands for "X is Not Unix," and it is the result of the merger between the Mach microkernel and elements of the BSD operating system. XNU provides essential system services such as memory management, process management, security, and hardware abstraction.

## Mach IPC
Mach IPC (Inter-Process Communication) is a messaging system used to exchange data between different processes within the operating system. It is an integral part of the XNU kernel and is implemented using Mach message passing. Mach IPC is designed to be flexible and adaptable for passing messages between any two ports, whether local or remote.

## machmsg
machmsg is the core building block of Mach's IPC, designed to pass between any two ports, whether local or remote. Tasks send messages to ports, and the messages are delivered and received in the order they were sent.

----------------------------------

# SERVER:

## Message Structure:
A message consists of a header and a variable amount of typed data. The header contains the destination and size of the message.

	typedef struct {
	mach_msg_header_t header;
	char Message_Body[1024];
	int Message_Size;
	}Message;

	typedef struct {
	Message message;
	mach_msg_trailer_t trailer;
	} ReceiveMessage;

## Port Rights:
Tasks operate on a port to send and receive messages by getting rights for the port. A task can hold send rights for a port, allowing them to send a single message. Only one task can hold the receive capability, also known as the receive right, for a port. Port rights can be transferred between tasks via messages.


The **`send_reply`()** routine takes two arguments: a **`mach_port_name_t`** which is a name of a Mach port to send the response to, and a pointer to a Message structure containing the original message. The routine creates a new Message structure called response to hold the response to the original message. It sets several fields in the header of the response message, including the remote port to which the message should be sent, the message ID, and the size of the message. It also sets the **`Message_Size`** field and copies the message body from the original message to the response message. Finally, it sends the response message using the **`mach_msg()`** function and returns the result of the function.

	// Server response routine:
	mach_msg_return_t send_reply(mach_port_name_t port, const Message *Message1) {
	Message response = {0};
	response.header.msgh_bits =
	Message1->header.msgh_bits & MACH_MSGH_BITS_REMOTE_MASK;
	response.header.msgh_remote_port = port;
	response.header.msgh_id = Message1->header.msgh_id;
	response.header.msgh_size = sizeof(response);
	response.Message_Size = Message1->Message_Size << 1;
	strcpy(response.Message_Body, Message1->Message_Body);
		
	return mach_msg(
		/* msg */ (mach_msg_header_t *)&response,
		/* option */ MACH_SEND_MSG,
		/* send size */ sizeof(response),
		/* recv size */ 0,
		/* recv_name */ MACH_PORT_NULL,
		/* timeout */ MACH_MSG_TIMEOUT_NONE,
		/* notify port */ MACH_PORT_NULL);
	}

## Receive Right Transfer:
If a message contains a receive right for a port, then the receive right is removed from the sender and transferred to the receiver of the message. During the transfer, tasks holding send rights can still send messages to the port, and the messages form a queue until a task acquires the receive right and uses it to receive the messages.


The **`receive_msg()`** routine takes two arguments: a **`mach_port_name_t`** which is the name of the port to receive messages on, and a pointer to a ReceiveMessage structure to hold the received message. The routine calls **`mach_msg()`** to receive a message on the specified port. It sets the option to **`MACH_RCV_MSG`**, indicating that it wants to receive a message. It also specifies the size of the receive buffer and sets the timeout to **`MACH_MSG_TIMEOUT_NONE`**, indicating that the routine should wait indefinitely for a message. If **`mach_msg()`** returns a result other than **`MACH_MSG_SUCCESS`**, the routine returns the result code. Otherwise, it returns **`MACH_MSG_SUCCESS`**.


	// Message retrieval routine:
	mach_msg_return_t
		receive_msg(mach_port_name_t recvPort, ReceiveMessage *buffer) {
		mach_msg_return_t ret = mach_msg(
		/* msg */ (mach_msg_header_t *)buffer,
		/* option */ MACH_RCV_MSG,
		/* send size */ 0,
		/* recv size */ sizeof(*buffer),
		/* recv_name */ recvPort,
		/* timeout */ MACH_MSG_TIMEOUT_NONE,
		/* notify port */ MACH_PORT_NULL);
	if (ret != MACH_MSG_SUCCESS) {
		return ret;
	}

### This is a part of the handling that saves incoming messages to a file on the server's disk:

The first section of the code gets access to the file directory that contains the saved data. It creates an instance of the NSFileManager class and uses the NSSearchPathForDirectoriesInDomains method to get an array of directory paths. Then, it saves the first element of the array, which is the path to the documents directory, in the documentsDirectoryPath variable.

	// Get access to the file directory that contains the saved data:
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains
		(NSDocumentDirectory, NSUserDomainMask, YES);
		NSError *error;

The second section of the code prints the content of the received message. It extracts the message's content from the buffer parameter using the Message structure, and then prints the message's ID and body to the console.

	// Print the message content that received by the client:
		Message *message = &buffer->message;
		printf("\n  (*)  New message received!\n\n\n");
		printf("  Client_ID (PID): %d\n", message->header.msgh_id);
		printf("  Message_Body:\n\n %s\n", message->Message_Body);
		printf("\n\n\n  (*)  Messages saved successfuly!\n\n\n\n\n");

	// Get access to the file:
		NSString *documentsDirectoryPath = [directoryPaths objectAtIndex:0];
		NSString *result = [NSString stringWithUTF8String: message->Message_Body];
		NSString *result2 = [NSString stringWithFormat: @"%d", message->header.msgh_id];
		NSString *aPath = [documentsDirectoryPath stringByAppendingPathComponent:result2];
		if ([fileManager fileExistsAtPath:aPath] == YES) {
		
The third section of the code gets access to the file on the server's disk. It creates a NSString variable result from the Message_Body field of the message, and another NSString variable result2 from the **`msgh_id`** field of the message. Then, it creates a file path by appending the result2 variable to the documentsDirectoryPath variable, and saves the resulting path in the aPath variable.

	// Write the message content to the file:
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:aPath];
		[fileHandle seekToEndOfFile];
		[fileHandle writeData:[result dataUsingEncoding:NSUTF8StringEncoding]];
		[fileHandle closeFile];
		}
		else {
	// If the file's not exist, create it and then write the data:
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains
		(NSDocumentDirectory, NSUserDomainMask,YES) firstObject];
		NSString *newFilePath = [documentsDirectory stringByAppendingPathComponent:result2];
	
If the file already exists, the code opens the file in append mode, writes the message content to the file, and then closes the file. If the file doesn't exist, the code creates a new file at the specified path and writes the message content to the file.
	
	if ([fileManager createFileAtPath:newFilePath contents:[@"Server Log\n\n\n" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil]){
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
		[fileHandle seekToEndOfFile];
		[fileHandle writeData:[result dataUsingEncoding:NSUTF8StringEncoding]];
		[fileHandle closeFile];

	}
	

This is the function that compares a newly created file with all the existing files ithe specified directory. If the content of the new file is identical to any of thexisting files, the new file will be deleted.

The function first uses an array to store all the URLs of the files in the directory. It then loops through each file and compares their content with the new file. If the content of any file is identical to the new file, the function removes the new file. If the deletion is successful, it prints a message indicating that the identical file has been removed successfully. If the deletion fails, it prints an error message. Finally, the function returns **`MACH_MSG_SUCCESS`** to indicate that the process is complete.

	// Comapre the new file to all existing files, delete it if it's identical to one of them:
		NSArray *urls = [fileManager contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
		int i = 0;
		NSString *actualfilePath =  [documentsDirectoryPath stringByAppendingPathComponent:result2];
		for (i = 0; i < urls.count; i++){
		NSString *secondFilePath = [documentsDirectoryPath stringByAppendingPathComponent:urls[i]];
		
	// Compare content of files while avoid comparing the file to it self:
		if (![actualfilePath isEqualToString:secondFilePath] && [fileManager contentsEqualAtPath:actualfilePath andPath:secondFilePath]){
			if ([fileManager removeItemAtPath:actualfilePath error:&error]){
			NSLog(@"\n\n -- Same data already exist, Removed successfuly! \n\n\n\n\n");}
		else{
			NSLog(@" Remove failed: %@", result);}
		}
	}
		return MACH_MSG_SUCCESS;
	}


Now we sets up a Mach IPC server to receive messages from clients!
the code creates a new receive port using **`mach_port_allocate()`** function and assigns it to the recvPort variable. A send right is added to this port using **`mach_port_insert_right()`** function. This allows the program to send messages using this port to other programs.

	// Create a receive right
	mach_port_t task = mach_task_self();
	mach_port_name_t recvPort;
	if (mach_port_allocate(task, MACH_PORT_RIGHT_RECEIVE, &recvPort) != KERN_SUCCESS) {
		return EXIT_FAILURE;
	}

	// Add a send right:
	if (mach_port_insert_right(task, recvPort, recvPort, MACH_MSG_TYPE_MAKE_SEND) != KERN_SUCCESS) {
		return EXIT_FAILURE;
	}

The code retrieves the bootstrap port using **`task_get_special_port()`** function and stores it in bootstrapPort variable. The bootstrap port is a special port maintained by the kernel and is used to locate system services. Then, **`bootstrap_check_in()`** function is used to query the bootstrap port for a service with the name "this.is.the.client.name" and assign the receive port to recvPort variable.

	// Retrieve the bootstrap port:
	mach_port_t bootstrapPort;
	if (task_get_special_port(task, TASK_BOOTSTRAP_PORT, &bootstrapPort) != KERN_SUCCESS) {
		return EXIT_FAILURE;
	}

	// Query bootstrap for the service port:
	if (bootstrap_check_in(bootstrapPort, "this.is.the.client.name", &recvPort) != KERN_SUCCESS) {
		return EXIT_FAILURE;
	}

This section creates a log file named "Server" in the user's Documents folder. NSFileManager class is used to manage file operations in macOS and iOS platforms.

	// Create the file to write the data (in the Documents folder):
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
	NSString *newFilePath = [documentsDirectory stringByAppendingPathComponent:@"Server"];
	if ([fileManager createFileAtPath:newFilePath contents:[@"Server Log\n\n\n %@" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil]) {
	} else {
		NSLog(@"Server log created !");
	}

This sets up an infinite loop to receive and respond to incoming messages. **`receive_msg()`** function is used to receive the messages on the **`recvPort`** and stores the message in receiveMessage structure. If the message is not received successfully, it prints an error message and continues to the next iteration. If the message has a null remote port, it also continues to the next iteration. Then, **`send_reply()`** function is called to respond to the message by sending a message to the remote port specified in the received message. If the response is not sent successfully, it prints an error message.

	// Receive loop:
	while (true) {
		ReceiveMessage receiveMessage = {0};
		mach_msg_return_t ret = receive_msg(recvPort, &receiveMessage);
		if (ret != MACH_MSG_SUCCESS) {
			printf("Failed to receive a message: %#x\n", ret);
			continue;
		}
		if (receiveMessage.message.header.msgh_remote_port == MACH_PORT_NULL) {
			continue;
		}

		// Reply loop:
		ret = send_reply(receiveMessage.message.header.msgh_remote_port, &receiveMessage.message);
		if (ret != MACH_MSG_SUCCESS) {
			printf("Failed to respond: %#x\n", ret);
		}
	}

-----------------------------------

# Client:

First, there is a message structure defined, which contains a message header, a message body, and the size of the message:

	typedef struct {
	mach_msg_header_t header;
	char Message_Body[1024];
	int Message_Size;
	} Message;

This structure will be used to send messages between the client and server.
Next, there is a structure that combines the message structure with a message trailer:

	typedef struct {
	Message message;
	mach_msg_trailer_t trailer;
	} ReceiveMessage;

This structure will be used to receive messages from the server.
The **`receive_msg`** function is then defined, which takes in the receive port, a timeout value, and a pointer to a ReceiveMessage structure. This function will receive a message from the server and store it in the ReceiveMessage structure.

	mach_msg_return_t receive_msg(mach_port_name_t recvPort, mach_msg_timeout_t timeout, ReceiveMessage *receiveMessage) {
	mach_msg_return_t ret = mach_msg(
		/* msg */ (mach_msg_header_t *)receiveMessage,
		/* option */ MACH_RCV_MSG | MACH_RCV_TIMEOUT,
		/* send size */ 0,
		/* recv size */ sizeof(*receiveMessage),
		/* recv_name */ recvPort,
		/* timeout */ timeout,
		/* notify port */ MACH_PORT_NULL);
	if (ret != MACH_MSG_SUCCESS) {
		return ret;
	}

	Message *message = &receiveMessage->message;
	printf("\n\n (*) Message successfuly sent!\n\n");
	printf("\n\n Server response :\n\n %s\n", message->Message_Body);
	printf(" \n (*) Message has been saved!\n");
	return MACH_MSG_SUCCESS;
	}

The mach_msg function is used to receive the message. It takes in several arguments:

msg: A pointer to the message structure that will receive the message.
option: Flags that specify how to receive the message.
send size: The size of the message being sent (in this case, 0 since we are not sending a message).
recv size: The size of the receive buffer.
recv_name: The receive port to use.
timeout: The maximum amount of time to wait for a message.
notify port: A notification port to use (not used in this case).
If the mach_msg function succeeds, the message is stored in the ReceiveMessage structure, and the function returns **`MACH_MSG_SUCCESS`**. The message body is then printed to the console using printf.



	int main(){
	
	// Identify the task process ID:
		mach_port_name_t task = mach_task_self();
		NSProcessInfo *processInfo=[NSProcessInfo processInfo];
		int processID=[processInfo processIdentifier];

This section of code identifies the current process and retrieves its process ID.

    mach_port_t bootstrapPort;
    if (task_get_special_port(task, TASK_BOOTSTRAP_PORT, &bootstrapPort) !=
        KERN_SUCCESS) {
        return EXIT_FAILURE;
        
    }
Here, the bootstrap port is retrieved from the current task. The bootstrap port is a special port that is used by the system to coordinate access to system services.

	// Retrieve the bootstrap port:
		mach_port_t port;
		if (bootstrap_look_up(bootstrapPort, "this.is.the.client.name", &port) !=
			KERN_SUCCESS) {
			return EXIT_FAILURE;
		}
This code retrieves the service port from the bootstrap port. The service port is registered with the bootstrap server by the server process and can be looked up by the client process using a registered name.


	// Query bootstrap for the service port
		mach_port_t replyPort;
		if (mach_port_allocate(task, MACH_PORT_RIGHT_RECEIVE, &replyPort) !=
			KERN_SUCCESS) {
			return EXIT_FAILURE;
		}
		
		if (mach_port_insert_right(
			task, replyPort, replyPort, MACH_MSG_TYPE_MAKE_SEND) !=
			KERN_SUCCESS) {
			return EXIT_FAILURE;
		}

Finally, the client process allocates a receive right and inserts a send right into that receive right. This is used to create a port for the server process to reply to.


	// Setup message header:
	Message message = {0};
	message.header.msgh_remote_port = port;
	message.header.msgh_local_port = replyPort;
	message.header.msgh_id = processID;
	message.header.msgh_size = sizeof(message);
	message.header.msgh_bits =MACH_MSGH_BITS_SET(
	/* remote */ MACH_MSG_TYPE_COPY_SEND,
	/* local */ MACH_MSG_TYPE_MAKE_SEND,
	/* voucher */ 0,
	/* other */ 0);

This code block sets up the message header for the Mach message. It creates a Message struct, initializes it to zero, and sets the **`msgh_remote_port`**, **`msgh_local_port`**, **`msgh_id, msgh_size`**, and msgh_bits fields of the **`mach_msg_header_t`** struct contained within the Message struct.

**`msgh_remote_port`** is the destination port for the message, set to the port variable that was previously retrieved from the server process.
**`msgh_local_port`** is the receive right port that the server should use to reply, set to the replyPort variable that was created earlier in the client process.
**`msgh_id`** is a unique identifier for the message, set to the processID variable which contains the client's process ID.
**`msgh_size`** is the size of the message, set to the size of the Message struct.
**`msgh_bits`** contains flags that specify how the message should be sent. The **`MACH_MSGH_BITS_SET`** macro sets the flags to indicate that the message body should be copied to the remote port (**`MACH_MSG_TYPE_COPY_SEND`**) and that the local port should become a send right (**`MACH_MSG_TYPE_MAKE_SEND`**).


	// Message body:
	NSString*msg1=@"MACH MESSAGE #1 ";
	const char *msg1char=[msg1 cStringUsingEncoding:NSUTF8StringEncoding];
	strcpy(message.Message_Body,msg1char);
	message.Message_Size = 0xff;

This code block sets the message body for the Mach message. It creates an NSString object, msg1, containing the message text "MACH MESSAGE #1 ". It then converts this string to a C string using the cStringUsingEncoding method and stores the result in the msg1char variable.

The strcpy function is used to copy the C string msg1char into the Message_Body field of the Message struct. The **`Message_Size`** field is also set to 0xff, indicating the size of the message body.

	// Send message:
	mach_msg_return_t ret = mach_msg(
	/* msg */ (mach_msg_header_t *)&message,
	/* option */ MACH_SEND_MSG,
	/* send size */ sizeof(message),
	/* recv size */ 0,
	/* recv_name */ MACH_PORT_NULL,
	/* timeout */ MACH_MSG_TIMEOUT_NONE,
	/* notify port */ MACH_PORT_NULL);
	printf("\n\n Client message :\n\n %s", msg1char);

This code block sends the Mach message. It calls the mach_msg function to send the message.

---------------------------------------------------

# Summery

That's it! I learned a lot Through this process. I hope you also found this useful. Please feel free to leave any feedback or comments. If you're interested in checking out the full program, you can find it on my GitHub repository [here](https://github.com/xT0mR0x/mach_msg-server-client-IPC).


Some of the resources that I used which was really helpful: 

- Objective-C Essential Training on linkedin course

- Apple developer website

- IOS - EEZY TUTORIALS - https://eezytutorials.com/ios/nsfilemanager-by-example.php#.Y5ByPS8RqrA

- Damian Malarczyk Mach_msg tutorial - https://dmcyk.xyz
