//
//  PdBase_Extension.m
//  rwaclient
//
//  Created by Admin on 12.02.19.
//  Copyright © 2019 beryllium design. All rights reserved.
//

#import "PdBase.h"
#import "PdBase_Extension.h"

extern int libpd_float(const char *recv, float x);

@implementation PdBase (PdBaseExtension)
+ (int)sendDouble:(double)value toReceiver:(NSString *)receiverName {
    return libpd_float([receiverName cStringUsingEncoding:NSUTF8StringEncoding], value);
   
    return 0;
}
@end
