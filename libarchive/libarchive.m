//
//  libarchive.m
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

#import "libarchive.h"
#import "archive.h"
#import "archive_entry.h"
#define __LIBARCHIVE_BUILD
#import "archive_private.h"

@interface RawArchiveItem()
@property (readwrite, nonatomic, strong, nonnull) NSString *path;
@property (readwrite, nonatomic) int64_t offset;
@property (readwrite, nonatomic) int64_t size;
@property (readwrite, nonatomic, nullable) NSDate *created;
@property (readwrite, nonatomic, nullable) NSDate *modified;
@end

@implementation RawArchiveItem
@end

@implementation RawArchiveEntry
@end

typedef enum {
    RawArchiveModeRead,
    RawArchiveModeWrite,
} RawArchiveMode;

@implementation RawArchive {
    struct archive  *_archive;
    NSFileHandle    *_fileHandle;
    RawArchiveMode  _mode;
}

- (instancetype) initWithHandle:(struct archive *)archive fileHandle:(NSFileHandle *)fileHandle mode:(RawArchiveMode)mode filter:(RawArchiveFilter)filter
{
    if ((self = [super init])) {
        _archive    = archive;
        _fileHandle = fileHandle;
        _mode       = mode;
        _filter     = filter;

        // hack, force the valid utf-8 charset instead of asci, due to broken default_iconv_charset() in archive_string.c
        _archive->current_code = strdup("UTF-8");
    }
    return self;
}

#pragma mark - lifetime

- (void) dealloc
{
    [self close];
}

- (void) close
{
    if (_archive == NULL) {
        return;
    }

    if (_mode == RawArchiveModeRead) {
        archive_read_close(_archive);
    } else if (_mode == RawArchiveModeWrite) {
        archive_write_close(_archive);
    }

    archive_free(_archive);
    _archive = NULL;
}

#pragma mark - read

+ (instancetype) openRead:(NSString *)filePath error:(NSError **)error
{
    NSParameterAssert(filePath.length > 0);

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (fileHandle == nil) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:NULL];
        }
        return nil;
    }

    struct archive *archive = archive_read_new();
    if (!archive) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorInternal archive:NULL];
        }
        return nil;
    }

    archive_read_support_filter_gzip(archive);
    archive_read_support_format_tar(archive);
    const int r = archive_read_open_fd(archive, fileHandle.fileDescriptor, 10240);

    if (r != ARCHIVE_OK) {
        archive_free(archive);
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:archive];
        }
        return nil;
    }

    RawArchiveFilter filter;
    switch (archive_filter_code(archive, 0)) {
        case ARCHIVE_FILTER_NONE: filter = RawArchiveFilterNone; break;
        case ARCHIVE_FILTER_GZIP: filter = RawArchiveFilterGzip; break;
        default:                  filter = RawArchiveFilterUnsupported; break;
    }

    return [[self alloc] initWithHandle:archive fileHandle:fileHandle mode:RawArchiveModeRead filter:filter];
}

- (NSArray<RawArchiveItem *> *) itemsWithError:(NSError **)error
{
    NSMutableArray *items = [NSMutableArray array];

    struct archive_entry *entry;

    while (1) {

        const int r = archive_read_next_header(_archive, &entry);
        if (r == ARCHIVE_EOF) {
            break; // ok, eof
        }

        if (r == ARCHIVE_WARN) { // skip
#if DEBUG
            const char *cstring = archive_error_string(_archive);
            if (cstring != NULL) {
                NSLog(@"skip tar item due to error: %s", cstring);
            }
#endif
            continue;
        }

        if (r != ARCHIVE_OK) {
            if (error) {
                *error = [RawArchive errorWithCode:RawArchiveErrorNext archive:_archive];
            }
            return nil;
        }

        if (!S_ISREG(archive_entry_mode(entry))) {
            continue;
        }

        const char *cstring = archive_entry_pathname(entry);
        if (cstring != NULL) {

            NSString *path = [NSString stringWithUTF8String:cstring];
            if (path != nil && path.length > 0) {

                RawArchiveItem *item = [self makeItem:path entry:entry];
                if (item != nil) {
                    [items addObject:item];
                }
            }
        }
    }

    return [items copy];
}

- (RawArchiveItem *) makeItem:(NSString *)path entry:(struct archive_entry *)entry
{
    RawArchiveItem *result = [RawArchiveItem new];
    if (result == nil) {
        return nil;
    }
    result.path = path;
    result.size = archive_entry_size(entry);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    result.offset = archive_position_uncompressed(_archive);
#pragma clang diagnostic pop
    if (archive_entry_ctime_is_set(entry)) {
        result.created = [NSDate dateWithTimeIntervalSince1970:archive_entry_ctime(entry)];
    }
    if (archive_entry_mtime_is_set(entry)) {
        result.modified = [NSDate dateWithTimeIntervalSince1970:archive_entry_mtime(entry)];
    }
    return result;
}

- (RawArchiveEntry *) makeEntry:(NSString *)path entry:(struct archive_entry *)entry
{
    RawArchiveEntry *result = [RawArchiveEntry new];
    if (result == nil) {
        return nil;
    }
    result.path = path;
    if (archive_entry_ctime_is_set(entry)) {
        result.created = [NSDate dateWithTimeIntervalSince1970:archive_entry_ctime(entry)];
    }
    if (archive_entry_mtime_is_set(entry)) {
        result.modified = [NSDate dateWithTimeIntervalSince1970:archive_entry_mtime(entry)];
    }
    return result;
}

- (NSData *) readData:(NSString *)path error:(NSError **)error
{
    NSParameterAssert(path.length > 0);

    struct archive_entry *entry;

    while (1) {

        const int r = archive_read_next_header(_archive, &entry);
        if (r == ARCHIVE_EOF) {
            if (error) {
                *error = [RawArchive errorWithCode:RawArchiveErrorNotFound archive:_archive];
            }
            break;
        }

        if (r != ARCHIVE_OK) {
            if (error) {
                *error = [RawArchive errorWithCode:RawArchiveErrorNext archive:_archive];
            }
            break;
        }

        if (!S_ISREG(archive_entry_mode(entry))) {
            continue;
        }

        const char *cstring = archive_entry_pathname(entry);
        if (cstring != NULL) {
            NSString *current = [NSString stringWithUTF8String:cstring];
            if (current && [current localizedStandardCompare:path] == NSOrderedSame) {
                return [self readContentOfCurrentEntry: error];
            }
        }
    }

    return nil;
}

- (RawArchiveEntry *) readNext:(NSError **)error
{
    struct archive_entry *entry;

    while (1) {

        const int r = archive_read_next_header(_archive, &entry);
        if (r == ARCHIVE_EOF) {
            if (error) {
                *error = [RawArchive errorWithCode:RawArchiveErrorNotFound archive:_archive];
            }
            break;
        }

        if (r != ARCHIVE_OK) {
            if (error) {
                *error = [RawArchive errorWithCode:RawArchiveErrorNext archive:_archive];
            }
            break;
        }

        if (!S_ISREG(archive_entry_mode(entry))) {
            continue;
        }

        const char *cstring = archive_entry_pathname(entry);
        if (cstring != NULL) {
            NSString *path = [NSString stringWithUTF8String:cstring];
            if (path != nil) {
                RawArchiveEntry *result = [self makeEntry:path entry:entry];
                if (result == nil) {
                    return nil;
                }
                result.content = [self readContentOfCurrentEntry:error];
                if (result.content == nil) {
                    return nil;
                }
                return result;
            }
        }
    }

    return nil;
}

- (NSData *) readContentOfCurrentEntry:(NSError **)error
{
    NSMutableData *data = [NSMutableData data];

    while (1) {

        const void *buff = NULL; off_t offset = 0; size_t size = 0;
        const int r = archive_read_data_block(_archive, &buff, &size, &offset);

        if (r == ARCHIVE_EOF) {
            break;
        }

        if (r != ARCHIVE_OK) {
            if (error) {
                *error = [RawArchive errorWithCode:RawArchiveErrorRead archive:_archive];
            }
            return nil;
        }

        if (size > 0) {
            [data appendBytes:buff length:size];
        }
    }

    return data;
}

#pragma mark - write

+ (instancetype) openWrite:(NSString *)filePath error:(NSError **)error
{
    NSParameterAssert(filePath.length > 0);

    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (fileHandle == nil) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:NULL];
        }
        return nil;
    }

    struct archive *archive = archive_write_new();
    if (!archive) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorInternal archive:NULL];
        }
        return nil;
    }

    archive_write_set_format_pax_restricted(archive);
    const int r = archive_write_open_fd(archive, fileHandle.fileDescriptor);

    if (r != ARCHIVE_OK) {
        archive_free(archive);
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:archive];
        }
        return nil;
    }

    return [[self alloc] initWithHandle:archive fileHandle:fileHandle mode:RawArchiveModeWrite filter:RawArchiveFilterNone];
}

+ (NSFileHandle *) openFileAtEndOfArchive:(NSString *)filePath error:(NSError **)error
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    if (fileHandle == nil) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:NULL];
        }
        return nil;
    }

    struct archive *archive = archive_read_new();
    if (!archive) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorInternal archive:NULL];
        }
        return nil;
    }

    archive_read_support_format_tar(archive);

    const int r = archive_read_open_fd(archive, fileHandle.fileDescriptor, 10240);
    if (r != ARCHIVE_OK) {
        archive_free(archive);
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:archive];
        }
        return nil;
    }

    // seek the end of archive
    struct archive_entry *entry;
    while (archive_read_next_header(archive, &entry) == ARCHIVE_OK) {}
    const int64_t endPosition = archive_read_header_position(archive);
    archive_read_free(archive);

    @try {
        [fileHandle seekToFileOffset:endPosition];
        [fileHandle truncateFileAtOffset:endPosition];
    } @catch (NSException *exp) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:archive];
        }
        return nil;
    }

    return fileHandle;
}

+ (instancetype) openAppend:(NSString *)filePath error:(NSError **)error
{
    NSParameterAssert(filePath.length > 0);

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [self openWrite:filePath error:error];
    }

    NSFileHandle *fileHandle = [self openFileAtEndOfArchive:filePath error:error];
    if (fileHandle == nil) {
        return nil;
    }

    struct archive *archive = archive_write_new();
    if (!archive) {
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorInternal archive:NULL];
        }
        return nil;
    }

    archive_write_set_format_pax_restricted(archive);
    const int r = archive_write_open_fd(archive, fileHandle.fileDescriptor);

    if (r != ARCHIVE_OK) {
        archive_free(archive);
        if (error) {
            *error = [self errorWithCode:RawArchiveErrorOpen archive:archive];
        }
        return nil;
    }

    return [[self alloc] initWithHandle:archive fileHandle:fileHandle mode:RawArchiveModeWrite filter:RawArchiveFilterNone];
}

- (BOOL) writeEntry:(RawArchiveEntry *)rawEntry error:(NSError **)error
{
    NSParameterAssert(rawEntry.path.length > 0);
    __auto_type data = rawEntry.content;

    struct archive_entry *entry = archive_entry_new();
    if (!entry) {
        if (error) {
            *error = [RawArchive errorWithCode:RawArchiveErrorInternal archive:_archive];
        }
        return NO;
    }

    archive_entry_set_pathname(entry, rawEntry.path.UTF8String);
    archive_entry_set_size(entry, data.length);
    archive_entry_set_filetype(entry, AE_IFREG);
    archive_entry_set_perm(entry, 0644);
    if (rawEntry.created != nil) {
        archive_entry_set_ctime(entry, rawEntry.created.timeIntervalSince1970, 0);
    }
    if (rawEntry.modified != nil) {
        archive_entry_set_ctime(entry, rawEntry.modified.timeIntervalSince1970, 0);
    }

    BOOL result = NO;
    if (ARCHIVE_OK == archive_write_header(_archive, entry)) {
        const ssize_t numBytes = archive_write_data(_archive, data.bytes, data.length);
        result = (numBytes == data.length);
    }

    archive_entry_free(entry);

    if (!result && error) {
        *error = [RawArchive errorWithCode:RawArchiveErrorWrite archive:_archive];
    }
    
    return result;
}

#pragma mark - helpers

+ (NSError *) errorWithCode:(RawArchiveError)code archive:(struct archive *)archive
{
    NSString *localizedDescription, *localizedReason;

    switch (code) {
        case RawArchiveErrorInternal:   localizedDescription = NSLocalizedString(@"Internal error", nil); break;
        case RawArchiveErrorOpen:       localizedDescription = NSLocalizedString(@"Unable to open file", nil); break;
        case RawArchiveErrorNext:       localizedDescription = NSLocalizedString(@"Failed to list entries", nil); break;
        case RawArchiveErrorRead:       localizedDescription = NSLocalizedString(@"Failed to read entry", nil); break;
        case RawArchiveErrorWrite:      localizedDescription = NSLocalizedString(@"Failed to write entry", nil); break;
        case RawArchiveErrorNotFound:   localizedDescription = NSLocalizedString(@"Not found", nil); break;
    }

    if (archive != NULL) {
        const char *cstring = archive_error_string(archive);
        if (cstring && strlen(cstring) > 0) {
            localizedReason = [NSString stringWithUTF8String:cstring];
        }
        const int err = archive_errno(archive);
        if (err != 0) {
            if (localizedReason != nil) {
                localizedReason = [localizedReason stringByAppendingFormat:@" #%d", err];
            } else {
                localizedReason = [NSString stringWithFormat:@"#%zd", err];
            }
        }
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (localizedDescription != nil) {
        userInfo[NSLocalizedDescriptionKey] = localizedDescription;
    }
    if (localizedReason != nil) {
        userInfo[NSLocalizedFailureReasonErrorKey] = localizedReason;
    }

    return [NSError errorWithDomain:@"com.kolyvan.tarballkit" code:code userInfo:userInfo];
}

@end
