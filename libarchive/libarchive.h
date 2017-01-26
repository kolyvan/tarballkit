//
//  libarchive.h
//  https://github.com/kolyvan/tarballkit
//
//  Created by Konstantin Bukreev on 24.01.17.
//

/*
 Copyright (c) 2017 Konstantin Bukreev All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

// simple objc wrapper to libarchive api https://github.com/libarchive/libarchive

typedef NS_ENUM(NSInteger, RawArchiveError) {
    RawArchiveErrorInternal = 1,
    RawArchiveErrorOpen,
    RawArchiveErrorNext,
    RawArchiveErrorRead,
    RawArchiveErrorWrite,
    RawArchiveErrorNotFound,
};

typedef NS_ENUM(NSInteger, RawArchiveFilter) {
    RawArchiveFilterNone        = 0,
    RawArchiveFilterGzip        = 1,
    RawArchiveFilterBzip2       = 2,
    RawArchiveFilterUnsupported = 255,
};

@interface RawArchiveItem: NSObject
@property (readonly, nonatomic, strong, nonnull) NSString *path;
@property (readonly, nonatomic) int64_t offset;
@property (readonly, nonatomic) int64_t size;
@property (readonly, nonatomic, nullable) NSDate *created;
@property (readonly, nonatomic, nullable) NSDate *modified;
@end

@interface RawArchiveEntry: NSObject
@property (readwrite, nonatomic, strong, nonnull) NSString *path;
@property (readwrite, nonatomic, strong, nonnull) NSData *content;
@property (readwrite, nonatomic, nullable) NSDate *created;
@property (readwrite, nonatomic, nullable) NSDate *modified;
@end

@interface RawArchive: NSObject

@property (readonly, nonatomic) RawArchiveFilter filter;

+ (nullable instancetype) openRead:(nonnull NSString *)filePath error:(NSError * _Nullable * _Nullable)error;
- (nullable NSData *) readData:(nonnull NSString *)path error:(NSError * _Nullable * _Nullable)error;
- (nullable RawArchiveEntry *) readNext:(NSError * _Nullable * _Nullable)error;
- (nullable NSArray<RawArchiveItem *> *) itemsWithError:(NSError * _Nullable * _Nullable)error;

+ (nullable instancetype) openWrite:(nonnull NSString *)filePath error:(NSError * _Nullable * _Nullable)error;
+ (nullable instancetype) openAppend:(nonnull NSString *)filePath error:(NSError * _Nullable * _Nullable)error;
- (BOOL) writeEntry:(nonnull RawArchiveEntry *)rawEntry error:(NSError * _Nullable * _Nullable)error;

@end
