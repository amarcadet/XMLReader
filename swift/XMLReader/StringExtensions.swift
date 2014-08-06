//
//  StringExtensions.swift
//  XMLReader
//
//  Created by Antoine on 05/08/2014.
//  Copyright (c) 2014 Epershand. All rights reserved.
//

import Foundation

// part borrowed from https://github.com/pNre/ExSwift/blob/master/ExSwift/String.swift
extension String {
    
    /**
        Strip specified characters from the start of a string
    
        :param: set The character set to be trim from the start of the string
    
        :returns: Stripped string
    */
    func ltrimCharactersInSet(set: NSCharacterSet) -> String {
        if let range = rangeOfCharacterFromSet(set.invertedSet) {
            return self[range.startIndex..<endIndex]
        }
        
        return self
    }
    
    /**
        Strip whitespaces and newlines from the start of a string
    
        :returns: Stripped string
    */
    func ltrim() -> String {
        return self.ltrimCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    /**
        Strip specified characters from the end of a string
        
        :param: set The character set to be trim from the end of the string
        
        :returns: Stripped string
    */
    func rtrimCharactersInSet(set: NSCharacterSet) -> String {
        if let range = rangeOfCharacterFromSet(set.invertedSet, options: NSStringCompareOptions.BackwardsSearch) {
            return self[startIndex..<range.endIndex]
        }
        
        return self
    }
    
    /**
        Strip whitespaces and newlines from the end of a string
        
        :returns: Stripped string
    */
    func rtrim() -> String {
        return self.rtrimCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    /**
        Strip whitespaces and newlines from both the start and the end of a string
    
        :param: set The character set to be trim from the start and the end of the string
    
        :returns: Stripped string
    */
    func trimCharactersInSet(set: NSCharacterSet) -> String {
        return ltrimCharactersInSet(set).rtrimCharactersInSet(set)
    }
    
    /**
        Strip whitespaces and newlines from both the start and the end of a string
    
        :returns: Stripped string
    */
    func trim() -> String {
        return ltrim().rtrim()
    }

}
