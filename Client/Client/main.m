//
//  main.m
//  Client
//
//  Created by Tom Rosenzweig
//


#include <bootstrap.h>
#include <mach/message.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
#include <mach/port.h>
#include <mach/task.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#define MS_IN_S 1000


// Message structure:
typedef struct {
  mach_msg_header_t header;
  char Message_Body[1024];
  int Message_Size;
} Message;

typedef struct {
  Message message;
 mach_msg_trailer_t trailer;
} ReceiveMessage;


// Receive message routine:
 mach_msg_return_t
 receive_msg(mach_port_name_t recvPort, mach_msg_timeout_t timeout,ReceiveMessage *receiveMessage) {
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
  
  // Print the server response:
    Message *message = &receiveMessage->message;
    printf("\n\n (*) Message successfuly sent!\n\n");
    printf(" Server response :\n %s\n", message->Message_Body);
    printf(" \n (*) Message has been saved!\n");
    return MACH_MSG_SUCCESS;
}

int main(){
    
// Identify the task process ID:
    mach_port_name_t task = mach_task_self();
    NSProcessInfo *processInfo=[NSProcessInfo processInfo];
    int processID=[processInfo processIdentifier];
    mach_port_t bootstrapPort;
    if (task_get_special_port(task, TASK_BOOTSTRAP_PORT, &bootstrapPort) !=
        KERN_SUCCESS) {
        return EXIT_FAILURE;
        
    }
// Retrieve the bootstrap port:
    mach_port_t port;
    if (bootstrap_look_up(bootstrapPort, "this.is.the.client.name", &port) !=
        KERN_SUCCESS) {
        return EXIT_FAILURE;
    }
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
    
    
// Setup message header:
    Message message = {0};
    message.header.msgh_remote_port = port;
    message.header.msgh_local_port = replyPort;
    message.header.msgh_bits = MACH_MSGH_BITS_SET(
              /* remote */ MACH_MSG_TYPE_COPY_SEND,
              /* local */ MACH_MSG_TYPE_MAKE_SEND,
              /* voucher */ 0,
              /* other */ 0);
    message.header.msgh_id = processID;
    message.header.msgh_size = sizeof(message);

// Message body:
    NSString*msg1=@"MACH MESSAGE #1 !";
    
    

    
