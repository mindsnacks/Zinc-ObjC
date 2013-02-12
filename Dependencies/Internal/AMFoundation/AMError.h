#import <Foundation/Foundation.h>

// TODO: needs docs like crazy

#ifdef __cplusplus
extern "C" {
#endif
    
    static NSString *const AMErrorOriginKey = @"ErrorOrigin";
    static NSString *const AMErrorNameKey = @"ErrorName";
    
    enum
    {
        AMERR_WRAPPED = 1,	
    };
    
#define AMError(E,D) _AMErrorMake(E, #E, D, __FILE__, __LINE__, nil)
#define AMErrorWithInfo(E,D,I) _AMErrorMake(E, #E, D, __FILE__, __LINE__, I)
    
#define AMErrorAddOriginToError(S) (S = _AMErrorAddOrigin(S, __FILE__, __LINE__))
#define AMErrorAddOriginToErrorP(S) AMErrorAssignIfNotNil(S, (S != NULL) ? AMErrorAddOriginToError(*S) : NULL)
    
    static inline void AMErrorAssignIfNotNil( NSError** outError, NSError* error )
    {
        if( outError != nil ) *outError = error;
    }
    
    
#pragma mark Internal Methods, use macros
    
    static inline NSError* _AMErrorMake( int errorCode, char const *errorName, NSString* domain, char const *fileName, int lineNumber, NSDictionary *userInfo )
    {
        NSString *errorNameString = [NSString stringWithCString:errorName encoding:NSUTF8StringEncoding];
        NSString *fileNameString = [[NSString stringWithCString:fileName encoding:NSUTF8StringEncoding] lastPathComponent];
        NSString *errorOrigin = [NSString stringWithFormat:@"%@:%d", fileNameString, lineNumber ];
        
        NSString *localizedDescription = [[NSBundle mainBundle] localizedStringForKey:errorNameString
                                                                                value:errorNameString
                                                                                table:@"Errors"];
        
        NSMutableDictionary *dict;
        if( userInfo != nil )
            dict = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        else
            dict = [NSMutableDictionary dictionaryWithCapacity:3];
        [dict setValue:errorOrigin forKey:AMErrorOriginKey];
        [dict setValue:errorNameString forKey:AMErrorNameKey];
        [dict setValue:localizedDescription forKey:NSLocalizedDescriptionKey];
        
        return [NSError errorWithDomain:domain code:errorCode userInfo:dict];
    }
    
    static inline NSError* _AMErrorAddOrigin( NSError* origError, char const *fileName, int lineNumber )
    {
        NSString *fileNameString = [[NSString stringWithCString:fileName encoding:NSUTF8StringEncoding] lastPathComponent];
        NSString *errorOrigin = [NSString stringWithFormat:@"%@:%d", fileNameString, lineNumber ];
        
        NSMutableDictionary* userInfo;
        if( [origError userInfo] != nil )
            userInfo = [NSMutableDictionary dictionaryWithDictionary:[origError userInfo]];
        else
            userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
        
        [userInfo setValue:errorOrigin forKey:AMErrorOriginKey];
        
        return [NSError errorWithDomain:[origError domain] code:[origError code] userInfo:userInfo];
    }
    
    
	
#ifdef __cplusplus
}
#endif
