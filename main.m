

//  Created by Tom Rosenzweig
// SERVER

#include <bootstrap.h>
#include <mach/message.h>
#include <mach/mach.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSFileHandle.h>
#include <stdio.h>
#include <stdlib.h>
#define RCV_ERROR_INVALID_MESSAGE_ID 0xffffff01c



// Message structure:
typedef struct {
 mach_msg_header_t header;
 char Message_Body[1024];
 int Message_Size;
 }Message;

typedef struct {
  Message message;
  mach_msg_trailer_t trailer;
} ReceiveMessage;


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
// Get access to the file directory that contains the saved data:
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSError *error;
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
  
  
  if ([fileManager createFileAtPath:newFilePath contents:[@"Server Log\n\n\n" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil]){
      NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
      [fileHandle seekToEndOfFile];
      [fileHandle writeData:[result dataUsingEncoding:NSUTF8StringEncoding]];
      [fileHandle closeFile];

  }

}
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
    
    int main(){
        
// Create a receive right
        mach_port_t task = mach_task_self();
    mach_port_name_t recvPort;
    if (mach_port_allocate(task, MACH_PORT_RIGHT_RECEIVE, &recvPort) !=KERN_SUCCESS){
        return EXIT_FAILURE;
        
    }
        
// Add a send right:
        printf ("\n\n - Task allocated successfuly!\n");
    if (mach_port_insert_right(
    task, recvPort, recvPort, MACH_MSG_TYPE_MAKE_SEND) != KERN_SUCCESS){
    return EXIT_FAILURE;
        
    }
        
// Retrieve the bootstrap port:
    printf (" - Task receive right!\n");
    mach_port_t bootstrapPort;
    if (task_get_special_port(task, TASK_BOOTSTRAP_PORT, &bootstrapPort) !=
        KERN_SUCCESS) {
    return EXIT_FAILURE;
    }
        
// Query bootstrap for the service port:
        printf (" - Bootstrap allocated!\n");  if (bootstrap_check_in(
        bootstrapPort, "this.is.the.client.name", &recvPort) !=
        KERN_SUCCESS) {
        return EXIT_FAILURE;
    }
    printf (" - Bootstrap registered!\n\n");
    printf ("  Bootstrap_Port = %d\n", bootstrapPort);
    printf ("  Receive_port = %d\n\n", recvPort);
    printf ("  Server is up, waiting for a message...\n\n\n");

// Create the file to write the data (in the Documents folder):
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory,NSUserDomainMask, YES) firstObject];
    NSString *newFilePath = [documentsDirectory stringByAppendingPathComponent:@"Server"];
        if ([fileManager createFileAtPath:newFilePath contents:[@"Server Log\n\n\n %@" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil]){
        
        }
            else{
                NSLog(@"Server log created !");
            }
    
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
    ret = send_reply(
        receiveMessage.message.header.msgh_remote_port,
        &receiveMessage.message);

    if (ret != MACH_MSG_SUCCESS) {
      printf("Failed to respond: %#x\n", ret);
    }
  }

  return 0;
}
