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
