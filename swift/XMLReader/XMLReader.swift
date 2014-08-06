//
//  XMLReader.swift
//  XMLReader
//
//  Created by Antoine on 04/08/2014.
//  Copyright (c) 2014 Epershand. All rights reserved.
//

import Foundation

typealias XMLDictionary = Dictionary<String, AnyObject>

let kXMLReaderTextNodeKey: String = "text"
let kXMLReaderAttributePrefix: String = "@"

//enum XMLReaderOptions: UInt8 {
//    case None                       = 0
//    
//    /// Specifies whether the receiver reports the namespace and the qualified name of an element.
//    case ProcessNamespaces          = 0b00000001
//    
//    /// Specifies whether the receiver reports the scope of namespace declarations.
//    case ReportNamespacePrefixes    = 0b00000010
//    
//    /// Specifies whether the receiver reports declarations of external entities.
//    case ResolveExternalEntities    = 0b00000100
//}
//
//func == (lhs: XMLReaderOptions, rhs: XMLReaderOptions) -> Bool {
//    let res = lhs & rhs
//    return (res != 0)
//}


///
struct XMLReaderOptions : RawOptionSetType {
    var value: UInt = 0
    
    init(_ value: UInt) { self.value = value }
    func toRaw() -> UInt { return self.value }
    
    // conforms to BooleanType
    var boolValue: Bool {
        get {
            return self.value != 0
        }
    }
    
    // conforms to RawOptionSetType
    static func fromMask(raw: UInt) -> XMLReaderOptions { return self(raw) }
    
    static func fromRaw(raw: UInt) -> XMLReaderOptions? { return self(raw) }
    
    // conforms to NilLiteralConvertible
    static func convertFromNilLiteral() -> XMLReaderOptions { return self(0) }
    
    // Options
    static var None: XMLReaderOptions { return self(0) }
    
    /// Specifies whether the receiver reports the namespace and the qualified name of an element.
    static var ProcessNamespaces: XMLReaderOptions { return XMLReaderOptions(1 << 0) }
    
    /// Specifies whether the receiver reports the scope of namespace declarations.
    static var ReportNamespacePrefixes: XMLReaderOptions { return XMLReaderOptions(1 << 1) }
    
    /// Specifies whether the receiver reports declarations of external entities.
    static var ResolveExternalEntities: XMLReaderOptions { return XMLReaderOptions(1 << 2) }
}

// conforms to Equatable
func == (lhs: XMLReaderOptions, rhs: XMLReaderOptions) -> Bool {
    return lhs.value == rhs.value
}

///
class XMLReader: NSObject, NSXMLParserDelegate {
    
    var dictionaryStack: [XMLDictionary]
    var textInProgress: String
    var error: NSError?
    
    override init() {
        self.dictionaryStack = []
        self.dictionaryStack.append([:])
        
        self.textInProgress = ""
    }
    
    /**

        :param: data
        :param: completion
    */
    class func parse(#data: NSData, completion: (xml: NSDictionary, error: NSError?) -> ()) {
        let reader = XMLReader()
        reader.parse(data: data, options: .None, completion: completion)
    }
    
    
    /**
    
        :param: string
        :param: completion
    */
    class func parse(#string: NSString, completion: (xml: NSDictionary, error: NSError?) -> ()) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)
        XMLReader.parse(data: data, completion: completion)
    }
    
    
    /**
    
        :param: data
        :param: options
        :param: completion
    */
    class func parse(#data: NSData, options: XMLReaderOptions, completion: (xml: NSDictionary, error: NSError?) -> ()) {
        let reader = XMLReader()
        reader.parse(data: data, options: options, completion: completion)
    }
    
    
    /**
    
        :param: data
        :param: options
        :param: completion
    */
    class func parse(#string: NSString, options: XMLReaderOptions, completion: (xml: NSDictionary, error: NSError?) -> ()) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)
        XMLReader.parse(data: data, options: options, completion: completion)
    }
    
    
    /**

        :param: data
        :param: options
    
        :returns:
    */
    func parse(#data: NSData, options: XMLReaderOptions, completion: (xml: NSDictionary, error: NSError?) -> ())
    {
        let parser: NSXMLParser = NSXMLParser(data: data)
        
        parser.shouldProcessNamespaces          = (options == .ProcessNamespaces)
        parser.shouldReportNamespacePrefixes    = (options == .ReportNamespacePrefixes)
        parser.shouldResolveExternalEntities    = (options == .ResolveExternalEntities)
        
        parser.delegate = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            parser.parse()
            dispatch_async(dispatch_get_main_queue()) {
                completion(xml: self.dictionaryStack.first!, error: self.error)
            }
        }
    }

    
    // MARK: - NSXMLParserDelegate
    
    // sent when the parser begins parsing of the document.
    func parserDidStartDocument(parser: NSXMLParser!)
    {
        NSLog("parserDidStartDocument")
        
        // Clear out any old data
        self.dictionaryStack = [];
        self.textInProgress = ""
        
        // Initialize the stack with a fresh dictionary
        self.dictionaryStack.append([:])
    }
    
    // sent when the parser has completed parsing. If this is encountered, the parse was successful.
    func parserDidEndDocument(parser: NSXMLParser!)
    {
        NSLog("parserDidEndDocument")
    }
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!)
    {
        NSLog("didStartElement")
        
        // Get the dictionary for the current level in the stack
        var parentDict: XMLDictionary? = self.dictionaryStack.last
        
        // Create the child dictionary for the new element, and initialize it with the attributes
        var childDict = XMLDictionary()
        
        // Add new values
        for (k, v) in attributeDict {
            childDict.updateValue(v, forKey: k as String)
        }
        
        // If there's already an item for this key, it means we need to create an array
        if let existingValue: AnyObject = parentDict![elementName] {
            var array: [XMLDictionary]? = nil
            
            if existingValue is [XMLDictionary] {
                // The array exists, so use it
                array! = existingValue as [XMLDictionary]
            } else if existingValue is XMLDictionary {
                // Create an array if it doesn't exist
                array! = [XMLDictionary]()
                array!.append(existingValue as XMLDictionary)
                
                // Replace the child dictionary with an array of children dictionaries
                parentDict!.updateValue(array!, forKey: elementName)
            } else {
                NSLog("Something weird happened")
            }
            
            // Add the new child dictionary to the array
            array!.append(childDict)
        } else {
            // No existing value, so update the dictionary
            parentDict!.updateValue(childDict, forKey: elementName)
        }
        
        // Update the stack
        self.dictionaryStack.append(childDict)
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!)
    {
        NSLog("didEndElement")
        
        // Update the parent dict with text info
        var dictInProgress: XMLDictionary? = self.dictionaryStack.last
        
        // Set the text property
        if !self.textInProgress.isEmpty {
            // Trim whitespaces and newlines when end of element is reached
            dictInProgress![kXMLReaderTextNodeKey] = self.textInProgress.ltrim()
            
            // Reset the text
            self.textInProgress = ""
        }
        
        // Pop the current dict
        self.dictionaryStack.removeLast()
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!)
    {
        NSLog("foundCharacters: %s", string)
        
        // Build the text value
        self.textInProgress += string
    }
    
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!)
    {
        NSLog("parseErrorOccurred: %@", parseError)
        
        self.error = parseError
    }
    
}
