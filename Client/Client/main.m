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
