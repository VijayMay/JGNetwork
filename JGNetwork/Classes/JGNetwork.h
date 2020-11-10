//
//  JGNetwork.h
//  JGNetwork
//
//  Created by MWJ on 2020/11/5.
//

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;
@class AFSecurityPolicy;
@class AFHTTPResponseSerializer;
@class AFHTTPRequestSerializer;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kJGMethodPost;
extern NSString *const kJGMethodGet;
extern NSString *const kJGMethodHead;
extern NSString *const kJGMethodPut;
extern NSString *const kJGMethodTrace;
extern NSString *const kJGMethodPatch;
extern NSString *const kJGMethodDelete;
extern NSString *const kJGMethodConnect;
extern NSString *const kJGReturnCode;
extern NSString *const kJGReturnMessage;

typedef void (^JGServiceResponseBlock)(id __nullable responseObject, NSError *__nullable error);

@interface JGNetwork : NSObject

+ (AFHTTPSessionManager *)sharedManager;

/**
 服务器地址
 */
+ (NSURL *)baseURL;

+ (NSString *)defaultApiPath;

/**
 设置超时时间
 */
+ (NSTimeInterval)timeOutInterval;

/**
 HTTPS证书验证
 */
+ (AFSecurityPolicy *)securityPolicy;

/**
 Request设置
 */
+ (AFHTTPRequestSerializer *)requestSerializer;

/**
 Response设置
 */
+ (AFHTTPResponseSerializer *)responseSerializer;

/**
 请求任务方法默认是POST请求。

 @param parameters 参数
 @param apiPath API地址
 @param block 返回(id responseObject, NSError *error)
 */
+ (NSURLSessionDataTask *)startDataTaskWithParameters:(NSDictionary *)parameters
                                              apiPath:(NSString *)apiPath
                                      completionBlock:(JGServiceResponseBlock)block;

/**
 请求任务方法需要指定请求方式。

 @param parameters 参数
 @param apiPath API地址
 @param method @"GET"或kHttpMethodGET
 @param block 返回(id responseObject, NSError *error)
 */
+ (NSURLSessionDataTask *)startDataTaskWithParameters:(NSDictionary *)parameters
                                              apiPath:(NSString *)apiPath
                                           HTTPMethod:(NSString *)method
                                      completionBlock:(JGServiceResponseBlock)block;


/**
 文件上传

 @param fileData 参数
 @param apiPath API地址
 @param name 服务器用来解析的字段区分用途
 @param fileName 文件名
 @param parameters 请求参数
 @param completion  返回(JGServiceResponseBlock)
 @param progress 下载进度
 */
+ (NSURLSessionDataTask *)uploadFile:(NSData *)fileData
                             apiPath:(NSString *)apiPath
                                name:(NSString *)name
                            fileName:(NSString *)fileName
                          parameters:(id)parameters
                     completionBlock:(JGServiceResponseBlock)completion
                       progerssBlock:(void (^)(CGFloat progressValue))progress;

/**
 必须要重写的NSError处理方法

 @param responseObject responseObject
 @return 返回NSError对象
 */
+ (NSError *)checkServerResponse:(id)responseObject error:(NSError * __nullable)error;


/**
 responseObject解析，子类可以重写此方法

 @param responseObject responseObject
 @return responseObject
 */
+ (id)analyticWithResponseObject:(id)responseObject;

/**
 根据业务需求自定义设置request

 @param request NSMutableURLRequest
 */
+ (void)setupRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
