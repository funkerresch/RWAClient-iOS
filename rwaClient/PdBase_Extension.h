//
//  PdBase_Extension.h
//  rwaclient
//
//  Created by Admin on 12.02.19.
//  Copyright © 2019 beryllium design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PdBase (PdBaseExtension)
/// Send a float message.
+ (int)sendDouble:(double)value toReceiver:(NSString *)receiverName;
@end


