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
    printf("\n\n Server response :\n\n %s\n", message->Message_Body);
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
    message.header.msgh_id = processID;
    message.header.msgh_size = sizeof(message);
    message.header.msgh_bits =MACH_MSGH_BITS_SET(
   /* remote */ MACH_MSG_TYPE_COPY_SEND,
   /* local */ MACH_MSG_TYPE_MAKE_SEND,
   /* voucher */ 0,
   /* other */ 0);


// Message body:
    NSString*msg1=@"MACH MESSAGE #1 ";
 

    const char *msg1char=[msg1 cStringUsingEncoding:NSUTF8StringEncoding];
    strcpy(message.Message_Body,msg1char);
    message.Message_Size = 0xff;

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
    

// Check that the data is the same:
    ReceiveMessage rcvMessage = {0};
    while (ret == MACH_MSG_SUCCESS) {
    ret = receive_msg(replyPort, /* timeout */ 1 * MS_IN_S, &rcvMessage);
        if (ret == MACH_MSG_SUCCESS){
            if (strcmp(message.Message_Body, rcvMessage.message.Message_Body)==0)
                printf(" (*) Send/Receive is equal!\n\n");
            else printf(" Send/Receive is NOT equal\n\n");
                }

// Set timeout condition:
        if (ret == MACH_RCV_TIMED_OUT) {
        } else if (ret != MACH_MSG_SUCCESS) {
         printf("Failed mach_msg: %d\n", ret);
         return EXIT_FAILURE;}
  else {
    ret = receive_msg(replyPort, /* timeout */ 1 * MS_IN_S, &rcvMessage);
  }

  if (ret == MACH_RCV_TIMED_OUT) {
printf("--------------------------- TIMED OUT ! ----------------------------\n");
  } else if (ret != MACH_MSG_SUCCESS) {
    printf("Failed to receive a message: %#x\n", ret);
    return 1;
  }

// Message body #2:
   NSString *msg2=@"MACH MESSAGE #2 ";
        
        
        
    const char *msg2char=[msg2 cStringUsingEncoding:NSUTF8StringEncoding];
    strcpy(message.Message_Body,msg2char);
    message.Message_Size = 0xff;
    
// Send message #2:
      ret = mach_msg(
      /* msg */ (mach_msg_header_t *)&message,
      /* option */ MACH_SEND_MSG,
      /* send size */ sizeof(message),
      /* recv size */ 0,
      /* recv_name */ MACH_PORT_NULL,
      /* timeout */ MACH_MSG_TIMEOUT_NONE,
      /* notify port */ MACH_PORT_NULL);
        printf("\n\n Client message :\n\n  %s", msg2char);

// Check that the data is the same:
        ReceiveMessage rcvMessage = {0};
        while (ret == MACH_MSG_SUCCESS) {
        ret = receive_msg(replyPort, /* timeout */ 1 * MS_IN_S, &rcvMessage);
        if (ret == MACH_MSG_SUCCESS){
         if (strcmp(message.Message_Body, rcvMessage.message.Message_Body)==0)
                printf(" (*) Send/Receive is equal!\n\n");
           else printf(" Send/Receive is NOT equal\n\n");}
    
        }
    }
// Set timeout condition
    if (ret == MACH_RCV_TIMED_OUT) {
    } else if (ret != MACH_MSG_SUCCESS) {
     printf("Failed mach_msg: %d\n", ret);
     return EXIT_FAILURE;
  }

  else {
    ret = receive_msg(replyPort, /* timeout */ 1 * MS_IN_S, &rcvMessage);
  }

  if (ret == MACH_RCV_TIMED_OUT) {
printf("--------------------------- TIMED OUT ! ----------------------------\n");
  } else if (ret != MACH_MSG_SUCCESS) {
    printf("Failed to receive a message: %#x\n", ret);
    return 1;
  }
    
    
  return 0;
}
    
