// AFAmazonS3Manager.m
//
// Copyright (c) 2014 Mattt Thompson (http://mattt.me/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFAmazonS3Manager.h"

NSString * const AFAmazonS3ManagerErrorDomain = @"com.alamofire.networking.s3.error";

@interface AFAmazonS3Manager ()
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFAmazonS3Manager
@synthesize baseURL = _s3_baseURL;

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
	
    self.requestSerializer = [AFAmazonS3RequestSerializer serializer];
    self.responseSerializer = [AFXMLParserResponseSerializer serializer];
	
    return self;
}

- (id)initWithAccessKeyID:(NSString *)accessKey
                   secret:(NSString *)secret
{
    self = [self initWithBaseURL:nil];
    if (!self) {
        return nil;
    }
	
    [self.requestSerializer setAccessKeyID:accessKey secret:secret];
	
    return self;
}

- (NSURL *)baseURL {
    if (!_s3_baseURL) {
        return self.requestSerializer.endpointURL;
    }
	
    return _s3_baseURL;
}

#pragma mark -

- (void)enqueueS3RequestOperationWithMethod:(NSString *)method
                                       path:(NSString *)path
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(id responseObject))success
                                    failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(__unused AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
	
    [self.operationQueue addOperation:requestOperation];
}


#pragma mark Service Operations

- (void)getServiceWithSuccess:(void (^)(id responseObject))success
                      failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"GET" path:@"/" parameters:nil success:success failure:failure];
}

#pragma mark Bucket Operations

- (void)getBucket:(NSString *)bucket
          success:(void (^)(id responseObject))success
          failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"GET" path:bucket parameters:nil success:success failure:failure];
}

- (void)putBucket:(NSString *)bucket
       parameters:(NSDictionary *)parameters
          success:(void (^)(id responseObject))success
          failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"PUT" path:bucket parameters:parameters success:success failure:failure];
	
}

- (void)deleteBucket:(NSString *)bucket
             success:(void (^)(id responseObject))success
             failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"DELETE" path:bucket parameters:nil success:success failure:failure];
}

#pragma mark Object Operations

- (void)headObjectWithPath:(NSString *)path
                   success:(void (^)(NSHTTPURLResponse *response))success
                   failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"HEAD" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
        if (success) {
            success(operation.response);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
	
    [self.operationQueue addOperation:requestOperation];
}

- (void)getObjectWithPath:(NSString *)path
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(id responseObject, NSData *responseData))success
                  failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject, operation.responseData);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
	
    [requestOperation setDownloadProgressBlock:progress];
	
    [self.operationQueue addOperation:requestOperation];
}

- (void)getObjectWithPath:(NSString *)path
             outputStream:(NSOutputStream *)outputStream
                 progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                  success:(void (^)(id responseObject))success
                  failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString] parameters:nil error:nil];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(__unused AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
	
    [requestOperation setDownloadProgressBlock:progress];
    [requestOperation setOutputStream:outputStream];
	
    [self.operationQueue addOperation:requestOperation];
}

- (void)postObjectWithFile:(NSString *)path
           destinationPath:(NSString *)destinationPath
                parameters:(NSDictionary *)parameters
                  progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                   success:(void (^)(id responseObject))success
                   failure:(void (^)(NSError *error))failure
{
    [self setObjectWithMethod:@"POST" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (void)putObjectWithFile:(NSString *)path
          destinationPath:(NSString *)destinationPath
               parameters:(NSDictionary *)parameters
                 progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                  success:(void (^)(id responseObject))success
                  failure:(void (^)(NSError *error))failure
{
    [self setObjectWithMethod:@"PUT" file:path destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
}

- (void)putObjectWithData:(NSData *)data
			   permission:(AFAmazonPermissionType)permission
          destinationPath:(NSString *)destinationPath
               parameters:(NSDictionary *)parameters
                 progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                  success:(void (^)(id responseObject))success
                  failure:(void (^)(NSError *error))failure
{
	[self addPermissionHeadersForType:permission];
    [self setObjectWithMethod:@"PUT" data:data destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure
	 ];
}



- (void)deleteObjectWithPath:(NSString *)path
                     success:(void (^)(id responseObject))success
                     failure:(void (^)(NSError *error))failure
{
    [self enqueueS3RequestOperationWithMethod:@"DELETE" path:path parameters:nil success:success failure:failure];
}

- (void)setObjectWithMethod:(NSString *)method
                       file:(NSString *)filePath
            destinationPath:(NSString *)destinationPath
                 parameters:(NSDictionary *)parameters
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *fileRequest = [NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    [fileRequest setCachePolicy:NSURLCacheStorageNotAllowed];
	
    NSError *fileError = nil;
	NSURLResponse *response = nil;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:fileRequest returningResponse:&response error:&fileError];
	if (data && response) {
		
		[self setObjectWithMethod:method data:data destinationPath:destinationPath parameters:parameters progress:progress success:success failure:failure];
		
    }
}

- (void)setObjectWithMethod:(NSString *)method
                       data:(NSData *)data
            destinationPath:(NSString *)destinationPath
                 parameters:(NSDictionary *)parameters
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure{
	
	if (data) {
        
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[self.baseURL URLByAppendingPathComponent:destinationPath] absoluteString] parameters:parameters error:nil];
        request.HTTPBody = data;
		
		
		
        AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(__unused AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                success(responseObject);
            }
        } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
		
        [requestOperation setUploadProgressBlock:progress];
		
        [self.operationQueue addOperation:requestOperation];
    }else{
		NSLog(@"No data specified to send");
	}
}

-(void)addPermissionHeadersForType:(AFAmazonPermissionType)permission {
	NSMutableArray* xAmzHeaders = [[NSMutableArray alloc] init];
	
    switch (permission) {
		case AFAmazonPermissionUndefined:
			[[self requestSerializer] setValue:nil forHTTPHeaderField:@"x-amz-acl"];
			break;
        case AFAmazonPermissionPrivate:
            [[self requestSerializer] setValue:@"private" forHTTPHeaderField:@"x-amz-acl"];
            break;
        case AFAmazonPermissionPublicRead:
			[[self requestSerializer] setValue:@"public-read" forHTTPHeaderField:@"x-amz-acl"];
			
            break;
        case AFAmazonPermissionPublicReadWrite:
			[[self requestSerializer] setValue:@"public-read-write" forHTTPHeaderField:@"x-amz-acl"];
			
            break;
        case AFAmazonPermissionAuthenticatedRead:
			[[self requestSerializer] setValue:@"authenticated-read" forHTTPHeaderField:@"x-amz-acl"];
			
            break;
        case AFAmazonPermissionBucketOwnerRead:
			[[self requestSerializer] setValue:@"bucket-owner-read" forHTTPHeaderField:@"x-amz-acl"];
			
            break;
        case AFAmazonPermissionOwnerFullControl:
			[[self requestSerializer] setValue:@"bucket-owner-full-control" forHTTPHeaderField:@"x-amz-acl"];
			
            break;
    }
    [xAmzHeaders addObject:@"x-amz-acl"];
}



#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingBaseURL {
    return [NSSet setWithObjects:@"baseURL", @"requestSerializer.bucket", @"requestSerializer.region", @"requestSerializer.useSSL", nil];
}

@end
