#import "RNCookieManagerIOS.h"
#if __has_include("RCTConvert.h")
#import "RCTConvert.h"
#else
#import <React/RCTConvert.h>
#endif

@implementation RNCookieManagerIOS

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(set:(NSDictionary *)props
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    // Check if mandatory properties are provided
    
    NSArray* mandatoryProps = @[@"path", @"name", @"value"];
    
    for(NSString* propName in mandatoryProps) {
        if (props[propName] == [NSNull null] || props[propName] == nil) {
            NSString* errorMsg = [NSString stringWithFormat:@"Cookie property '%@' must be provided", propName];
            reject(@"missing_required_prop", errorMsg, [NSError errorWithDomain:@"com.react.native.cookies" code:0 userInfo:@{NSLocalizedDescriptionKey:errorMsg}]);
            return;
        }
    }
    
    // Domain OR origin must be provided
    
    if ((props[@"domain"] == [NSNull null] || props[@"domain"] == nil) &&
        (props[@"origin"] == [NSNull null] || props[@"origin"] == nil)) {
        NSString* errorMsg = @"At least one of 'domain' or 'origin' cookie properties must be provided";
        reject(@"missing_required_prop", errorMsg, [NSError errorWithDomain:@"com.react.native.cookies" code:0 userInfo:@{NSLocalizedDescriptionKey:errorMsg}]);
        return;
    }
    
    // Cookie is valid
    
    NSString *path = [RCTConvert NSString:props[@"path"]];
    NSString *name = [RCTConvert NSString:props[@"name"]];
    NSString *value = [RCTConvert NSString:props[@"value"]];
    
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:path forKey:NSHTTPCookiePath];
    [cookieProperties setObject:name forKey:NSHTTPCookieName];
    [cookieProperties setObject:value forKey:NSHTTPCookieValue];
    
    if(props[@"domain"] != [NSNull null] && props[@"domain"] != nil) {
        [cookieProperties setObject:[RCTConvert NSString:props[@"domain"]] forKey:NSHTTPCookieDomain];
    }
    if(props[@"origin"] != [NSNull null] && props[@"origin"] != nil) {
        [cookieProperties setObject:[RCTConvert NSString:props[@"origin"]] forKey:NSHTTPCookieOriginURL];
    }
    if(props[@"version"] != [NSNull null] && props[@"version"] != nil) {
        [cookieProperties setObject:[RCTConvert NSString:props[@"version"]] forKey:NSHTTPCookieVersion];
    }
    if(props[@"expiration"] != [NSNull null] && props[@"expiration"] != nil) {
        [cookieProperties setObject:[RCTConvert NSDate:props[@"expiration"]] forKey:NSHTTPCookieExpires];
    }
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    
    NSLog(@"SETTING COOKIE");
    NSLog(@"%@", cookieProperties);
    
    if (cookie == nil) {
        NSString* errorMsg = @"Cookie creation failed, check the properties";
        reject(@"cookie_creation_failed", errorMsg, [NSError errorWithDomain:@"com.react.native.cookies" code:0 userInfo:@{NSLocalizedDescriptionKey:errorMsg}]);
        return;
    }
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    
    resolve(nil);
}

RCT_EXPORT_METHOD(setFromResponse:(NSURL *)url
                  value:(NSDictionary *)value
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:value forURL:url];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:NULL];
    resolve(nil);
}

RCT_EXPORT_METHOD(getFromResponse:(NSURL *)url
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request  queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:httpResponse.allHeaderFields forURL:response.URL];
                               NSMutableDictionary *dics = [NSMutableDictionary dictionary];
                               
                               for (int i = 0; i < cookies.count; i++) {
                                   NSHTTPCookie *cookie = [cookies objectAtIndex:i];
                                   [dics setObject:cookie.value forKey:cookie.name];
                                   NSLog(@"cookie: name=%@, value=%@", cookie.name, cookie.value);
                                   [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                               }
                               resolve(dics);
                           }];
}

RCT_EXPORT_METHOD(get:(NSURL *) url
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSMutableDictionary *cookies = [NSMutableDictionary dictionary];
    for (NSHTTPCookie *c in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url]) {
        [cookies setObject:c.value forKey:c.name];
    }
    resolve(cookies);
}

RCT_EXPORT_METHOD(clearAll:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *c in cookieStorage.cookies) {
        [cookieStorage deleteCookie:c];
    }
    resolve(nil);
}

RCT_EXPORT_METHOD(clearByName:(NSString *) name
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *c in cookieStorage.cookies) {
        if ([[c name] isEqualToString:name]) {
            [cookieStorage deleteCookie:c];
        }
    }
    resolve(nil);
}

// TODO: return a better formatted list of cookies per domain
RCT_EXPORT_METHOD(getAll:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSMutableDictionary *cookies = [NSMutableDictionary dictionary];
    for (NSHTTPCookie *c in cookieStorage.cookies) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setObject:c.value forKey:@"value"];
        [d setObject:c.name forKey:@"name"];
        [d setObject:c.domain forKey:@"domain"];
        [d setObject:c.path forKey:@"path"];
        [cookies setObject:d forKey:c.name];
    }
    resolve(cookies);
}

@end

