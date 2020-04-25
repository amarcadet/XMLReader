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
        Strip whitespaces and newlines from both the start and the end of a string
        - returns: A string with trimmed whitespaces and newlines from both ends
    */
    func trimWhitespacesAndNewlines() -> String {
        let set = CharacterSet.whitespacesAndNewlines
        return self.trimmingCharacters(in: set)
    }

}
