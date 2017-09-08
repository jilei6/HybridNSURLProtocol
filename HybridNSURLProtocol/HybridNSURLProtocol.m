//
//  HybridNSURLProtocol.m
//  WKWebVIewHybridDemo
//
//  Created by shuoyu liu on 2017/1/16.
//  Copyright © 2017年 shuoyu liu. All rights reserved.
//

#import "HybridNSURLProtocol.h"
#import <UIKit/UIKit.h>
#import "NSHTTPURLResponse+Plus.h"


static NSString* const KHybridNSURLProtocolHKey = @"KHybridNSURLProtocol";
@interface HybridNSURLProtocol ()<NSURLSessionDelegate,NSURLSessionDataDelegate,NSURLSessionTaskDelegate>
@property (nonnull,strong) NSURLSessionDataTask *task;

@end


@implementation HybridNSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSLog(@"request.URL.absoluteString = %@",request.URL.absoluteString);
    NSString *scheme = [[request URL] scheme];
    if ( ([scheme caseInsensitiveCompare:@"http"]  == NSOrderedSame ||
          [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame ))
    {
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:KHybridNSURLProtocolHKey inRequest:request])
            return NO;
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    
    //request截取重定向 这个可以根据需求重新定向URL 我这没有需求，所以没处理
    if ([request.URL.absoluteString isEqualToString:@""])
    {
        NSURL* url1 = [NSURL URLWithString:@""];
        mutableReqeust = [NSMutableURLRequest requestWithURL:url1];
    }
    
    return mutableReqeust;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //给我们处理过的请求设置一个标识符, 防止无限循环,
    [NSURLProtocol setProperty:@YES forKey:KHybridNSURLProtocolHKey inRequest:mutableReqeust];
    
    //这里最好加上缓存判断，加载本地离线文件， 这个直接简单的例子。
    if ([mutableReqeust.URL.absoluteString containsString:@""])
    {
        /*
        NSData* data = UIImagePNGRepresentation([UIImage imageNamed:@""]);
        NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"image/png" expectedContentLength:data.length textEncodingName:nil];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
         */
    }
    //这里处理页面里面发出的AJAX请求拦截处理。
    else if ([mutableReqeust.URL.absoluteString containsString:@"http://www.baidu"])
    {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        self.task = [session dataTaskWithRequest:self.request];
        [self.task resume];
      
    }
}

+ (void)unmarkRequestAsIgnored:(NSMutableURLRequest *)request
{
    NSString *key = NSStringFromClass([self class]);
    [NSURLProtocol removePropertyForKey:key inRequest:request];
}
- (void)stopLoading
{
    if (self.task != nil)
    {
        [self.task  cancel];
    }
}
#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler
{
    if ([self client] != nil && [self task] == task) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [[self class] unmarkRequestAsIgnored:mutableRequest];
        [[self client] URLProtocol:self wasRedirectedToRequest:mutableRequest redirectResponse:response];
        
        NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        [self.task cancel];
        [self.client URLProtocol:self didFailWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    if ([self client] != nil && (_task == nil || _task == task)) {
        if (error == nil) {
            [[self client] URLProtocolDidFinishLoading:self];
        } else if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            // Do nothing.
        } else {
            [[self client] URLProtocol:self didFailWithError:error];
        }
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    if ([self client] != nil && [self task] != nil && [self task] == dataTask) {
        NSHTTPURLResponse *URLResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            URLResponse = (NSHTTPURLResponse *)response;
            URLResponse = [NSHTTPURLResponse rxr_responseWithURL:URLResponse.URL
                                                      statusCode:URLResponse.statusCode
                                                    headerFields:URLResponse.allHeaderFields
                                                 noAccessControl:YES];
        }
        NSLog(@"response---%@",response);
        [[self client] URLProtocol:self
                didReceiveResponse:URLResponse ?: response
                cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    if ([self client] != nil && [self task] == dataTask) {
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:nil];
        NSLog(@"json---%@",json);
        [[self client] URLProtocol:self didLoadData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *_Nullable cachedResponse))completionHandler
{
    if ([self client] != nil && [self task] == dataTask) {

        completionHandler(proposedResponse);
    }
}



@end
