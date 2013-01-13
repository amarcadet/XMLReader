#import "XMLCreator.h"
#import "NSDataAdditions.h"

@implementation XMLCreator

-(NSString*)cleanStringForXML:(NSString*)string{
    /*&     &amp;
     <     &lt;
     >     &gt;
     "     &quot;
     '     &apos;
     /     &#47;
     */
    if(string == nil || [string isEqualToString:@"(null)"])
        return @"";
    
    NSString *toReturn = [[NSString alloc] init];
    
    toReturn = [string stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    toReturn = [toReturn stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    toReturn = [toReturn stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    toReturn = [toReturn stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    toReturn = [toReturn stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
    toReturn = [toReturn stringByReplacingOccurrencesOfString:@"/" withString:@"&#47;"];
    
    return toReturn;
}

+(NSString*)xmlStringFromObject:(id)object{
    NSString *toReturn= @"";
    
    NSLog(@"%@",[object class]);
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        
        for (NSString *key in (NSDictionary*)object){
            
            if ([object[key] isKindOfClass:[NSArray class]]){
                
                for (id thing in object[key])
                    toReturn = [toReturn stringByAppendingString:[self xmlStringFromObject:thing]];
            }else
                toReturn = [toReturn stringByAppendingFormat:@"<%@>%@</%@>",key,object[key],key];
            
        }
    }
    else if ([object isKindOfClass:[NSArray class]]){
        
        for (id thing in object)
            toReturn = [toReturn stringByAppendingString:[self xmlStringFromObject:thing]];
        
    } else if ([object isKindOfClass:[NSNumber class]]){
        
        if((strcmp([object objCType], @encode(int))) == 0) {
            toReturn = [toReturn stringByAppendingFormat:@"<int>%@</int>",object];
            
        } else if ((strcmp([object objCType], @encode(float))) == 0){
            
            toReturn = [toReturn stringByAppendingFormat:@"<float>%@</float>",object];
            
        } else if ((strcmp([object objCType], @encode(double))) == 0){
            
            toReturn = [toReturn stringByAppendingFormat:@"<double>%@</double>",object];
        }
   
    } else if ([object isKindOfClass:[NSString class]]){
        toReturn = [toReturn stringByAppendingFormat:@"<string>%@</string>",object];
        
    } else{
        @throw @"Unrecognised type";
    }
    
    
    return toReturn;
}

@end
