//
//  JGNetwork.m
//  JGNetwork
//
//  Created by MWJ on 2020/11/5.
//

#import "JGNetwork.h"
#import <AFNetworking/AFHTTPSessionManager.h>


NSString *const kJGMethodPost = @"POST";
NSString *const kJGMethodGet = @"GET";
NSString *const kJGMethodHead = @"HEAD";
NSString *const kJGMethodPut = @"PUT";
NSString *const kJGMethodTrace = @"TRACE";
NSString *const kJGMethodPatch = @"PATCH";
NSString *const kJGMethodDelete = @"DELETE";
NSString *const kJGMethodConnect = @"CONNECT";
NSString *const kJGReturnCode = @"returnCode";
NSString *const kJGReturnMessage = @"returnMessage";

#define EXCEPTION_NAME @"Needs Overriding"
#define EXCEPTION_MSG @"Method %s must be overrided to provide concrete implementaion."

@implementation JGNetwork

+ (NSURL *)baseURL {
    [NSException raise:EXCEPTION_NAME format:EXCEPTION_MSG, __func__];
    return nil;
}

+ (NSString *)defaultHTTPMethod {
    return kJGMethodPost;
}

+ (NSString *)defaultApiPath {
    return @"";
}

+ (NSTimeInterval)timeOutInterval {
    return 15;
}

+ (AFSecurityPolicy *)securityPolicy {
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    return securityPolicy;
}

+ (AFHTTPRequestSerializer *)requestSerializer {
    return [AFJSONRequestSerializer serializer];
}

+ (AFHTTPResponseSerializer *)responseSerializer {
    return [AFJSONResponseSerializer serializer];
}

+ (AFHTTPSessionManager *)sharedManager {
    static AFHTTPSessionManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 1;
        sharedManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
        sharedManager.securityPolicy = [self.class securityPolicy];
    });
    sharedManager.requestSerializer = [self.class requestSerializer];
    sharedManager.responseSerializer = [self.class responseSerializer];
    return sharedManager;
}

+ (NSURLSessionDataTask *)startDataTaskWithParameters:(NSDictionary *)parameters
                                              apiPath:(NSString *)apiPath
                                      completionBlock:(JGServiceResponseBlock)block {
    return [self.class requestWithParameters:parameters
                                     apiPath:apiPath
                                  HTTPMethod:[self defaultHTTPMethod]
                        serviceResponseBlock:block];
}

+ (NSURLSessionDataTask *)startDataTaskWithParameters:(NSDictionary *)parameters
                                              apiPath:(NSString *)apiPath
                                           HTTPMethod:(NSString *)method
                                      completionBlock:(JGServiceResponseBlock)block {
    return [self.class requestWithParameters:parameters
                                     apiPath:apiPath
                                  HTTPMethod:method
                        serviceResponseBlock:block];
}

+ (NSURLSessionDataTask *)requestWithParameters:(NSDictionary *)parameters
                                        apiPath:(NSString *)apiPath
                                     HTTPMethod:(NSString *)method
                           serviceResponseBlock:(JGServiceResponseBlock)block {

    if (!block) {
        return nil;
    }

    method = (method.length == 0) ? [self.class defaultHTTPMethod] : method;
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.class requestConfigWithParameters:parameters
                                                                   apiPath:apiPath
                                                                HTTPMethod:method
                                                                     error:&serializationError];
    //根据业务需求自定义设置request
    [self setupRequest:request];
    [request setValue:@"ios" forHTTPHeaderField:@"jg"];
    
    if (serializationError) {
        block(nil, serializationError);
        return nil;
    }
    
    AFHTTPSessionManager *sharedManager = [self.class sharedManager];
#if DEBUG
    NSLog(@"请求URL:%@",request.URL);
    NSLog(@"============分割线=============");
    NSLog(@"请求头:\n%@",request.allHTTPHeaderFields);
    NSLog(@"============分割线=============");
#endif
    NSURLSessionDataTask *task = [sharedManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
#if DEBUG
            NSLog(@"响应responseObject:\n%@",responseObject);
            NSLog(@"错误error:\n%@",error);
#endif
            if (block) {
                NSError *serviceError = [self checkServerResponse:responseObject error:error];
                if (serviceError) {
                    block(responseObject, serviceError);
                } else {
                    block([self analyticWithResponseObject:responseObject], nil);
                }
            }
    }];

    [task resume];
    return task;
}

+ (NSMutableURLRequest *)requestConfigWithParameters:(NSDictionary *)parameters
                                             apiPath:(NSString *)apiPath
                                          HTTPMethod:(NSString *)method
                                               error:(NSError **)error {
    AFHTTPSessionManager *sharedManager = [self.class sharedManager];
    if (apiPath.length == 0) {
        apiPath = [self.class defaultApiPath];
    }
    NSURL *url = [self baseURL];
    if (apiPath.length > 0) {
        url = [url URLByAppendingPathComponent:apiPath];
    }
    NSString *URLString = url.absoluteString;
    NSMutableURLRequest *request = nil;
    request = [sharedManager.requestSerializer requestWithMethod:method
                                                       URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString]
                                                      parameters:parameters
                                                           error:error];
    request.timeoutInterval = [self.class timeOutInterval];
    
    return request;
}

+ (NSError *)checkServerResponse:(id)responseObject error:(NSError *)error {
    if (responseObject == nil || [responseObject isKindOfClass:[NSNull class]]) {
        NSAssert(@"Response Object Can't be empty ", nil);
    }
    //需要针对服务器返回的errorCode解析异常统一处理或由子类重写。
    /*
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:responseObject[kReturnMessage]};
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:[responseObject[kReturnCode] integerValue]
                                     userInfo:userInfo];
    
    return error;
     */
    return nil;
}

+ (id)analyticWithResponseObject:(id)responseObject {
    return responseObject;
}

+ (void)setupRequest:(NSMutableURLRequest *)request {
    
}

@end
