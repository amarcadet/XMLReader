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

///
struct XMLReaderOptions : OptionSet{
    var rawValue: UInt
    
    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    typealias RawValue = UInt
    
    // conforms to BooleanType
    var boolValue: Bool {
        get {
            return self.rawValue != 0
        }
    }
    
    // conforms to RawOptionSetType
    static func fromMask(raw: UInt) -> XMLReaderOptions { return self.init(rawValue: raw) }
    
    static func fromRaw(raw: UInt) -> XMLReaderOptions? { return self.init(rawValue: raw) }
    
    // conforms to NilLiteralConvertible
    static func convertFromNilLiteral() -> XMLReaderOptions { return self.init(rawValue: 0) }
    
    // Options
    static var None: XMLReaderOptions { return self.init(rawValue: 0) }
    
    /// Specifies whether the receiver reports the namespace and the qualified name of an element.
    static var ProcessNamespaces: XMLReaderOptions { return XMLReaderOptions(rawValue: 1 << 0) }
    
    /// Specifies whether the receiver reports the scope of namespace declarations.
    static var ReportNamespacePrefixes: XMLReaderOptions { return XMLReaderOptions(rawValue: 1 << 1) }
    
    /// Specifies whether the receiver reports declarations of external entities.
    static var ResolveExternalEntities: XMLReaderOptions { return XMLReaderOptions(rawValue: 1 << 2) }
}

// conforms to Equatable
func == (lhs: XMLReaderOptions, rhs: XMLReaderOptions) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

enum XMLReaderError : Error {
    
    case invalidEncoding
    case unknownValueType
    
}

///
class XMLReader: NSObject, XMLParserDelegate {
    
    var dictionaryStack: [XMLDictionary]
    var textInProgress: String
    var error: Error?
    
    override init() {
        self.dictionaryStack = []
        self.dictionaryStack.append([:])
        
        self.textInProgress = ""
    }
    
    /**

        :param: data
        :param: completion
    */
    class func parse(data: NSData, completion: @escaping (_ xml: NSDictionary, _ error: Error?) -> ()) {
        let reader = XMLReader()
        reader.parse(data: data, options: .None, completion: completion)
    }
    
    
    /**
    
        :param: string
        :param: completion
    */
    class func parse(string: NSString, completion: @escaping (_ xml: NSDictionary, _ error: Error?) -> ()) {
        guard let data = (string as String).data(using: .utf8) as NSData? else {
            completion([:], XMLReaderError.invalidEncoding as NSError)
            return
        }
        XMLReader.parse(data: data, completion: completion)
    }
    
    
    /**
    
        :param: data
        :param: options
        :param: completion
    */
    class func parse(data: NSData, options: XMLReaderOptions, completion: @escaping (_ xml: NSDictionary, _ error: Error?) -> ()) {
        let reader = XMLReader()
        reader.parse(data: data, options: options, completion: completion)
    }
    
    
    /**
    
        :param: data
        :param: options
        :param: completion
    */
    class func parse(string: NSString, options: XMLReaderOptions, completion: @escaping (_ xml: NSDictionary, _ error: Error?) -> ()) {
        guard let data = (string as String).data(using: .utf8) as NSData? else {
            completion([:], XMLReaderError.invalidEncoding as NSError)
            return
        }
        XMLReader.parse(data: data, options: options, completion: completion)
    }
    
    
    /**

        :param: data
        :param: options
    
        :returns:
    */
    func parse(data: NSData, options: XMLReaderOptions, completion: @escaping (_ xml: NSDictionary, _ error: Error?) -> ())
    {
        let parser: XMLParser = XMLParser(data: data as Data)
        
        parser.shouldProcessNamespaces          = (options == .ProcessNamespaces)
        parser.shouldReportNamespacePrefixes    = (options == .ReportNamespacePrefixes)
        parser.shouldResolveExternalEntities    = (options == .ResolveExternalEntities)
        
        parser.delegate = self;
        DispatchQueue.global(qos: .background).async {
            parser.parse()
            DispatchQueue.main.async {
                completion((self.dictionaryStack.first! as NSDictionary), self.error)
            }
        }
    }

    
    // MARK: - NSXMLParserDelegate
    
    // sent when the parser begins parsing of the document.
    func parserDidStartDocument(_ parser: XMLParser) {
        // Clear out any old data
        self.dictionaryStack = [];
        self.textInProgress = ""
        
        // Initialize the stack with a fresh dictionary
        self.dictionaryStack.append([:])
    }
    
    // sent when the parser has completed parsing. If this is encountered, the parse was successful.
    func parserDidEndDocument(_ parser: XMLParser)
    {
        
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // Get the dictionary for the current level in the stack
        var parentDict: XMLDictionary? = self.dictionaryStack.last
        
        // Create the child dictionary for the new element, and initialize it with the attributes
        var childDict = XMLDictionary()
        
        // Add new values
        for (k, v) in attributeDict {
            childDict.updateValue(v as AnyObject, forKey: k as String)
        }
        
        // If there's already an item for this key, it means we need to create an array
        if let existingValue: AnyObject = parentDict![elementName] {
            var array: [XMLDictionary]? = nil
            
            if let existingValue = existingValue as? [XMLDictionary] {
                // The array exists, so use it
                array! = existingValue
            } else if let existingValue = existingValue as? XMLDictionary {
                // Create an array if it doesn't exist
                array! = [XMLDictionary]()
                array!.append(existingValue)
                
                // Replace the child dictionary with an array of children dictionaries
                parentDict!.updateValue(array! as AnyObject, forKey: elementName)
            } else {
                self.error = XMLReaderError.unknownValueType
            }
            
            // Add the new child dictionary to the array
            array!.append(childDict)
        } else {
            // No existing value, so update the dictionary
            parentDict!.updateValue(childDict as AnyObject, forKey: elementName)
        }
        
        // Update the stack
        self.dictionaryStack.append(childDict)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // Update the parent dict with text info
        var dictInProgress: XMLDictionary? = self.dictionaryStack.last
        
        // Set the text property
        if !self.textInProgress.isEmpty {
            // Trim whitespaces and newlines when end of element is reached
            dictInProgress![kXMLReaderTextNodeKey] = self.textInProgress.trimWhitespacesAndNewlines() as AnyObject
                        
            // Reset the text
            self.textInProgress = ""
        }
        
        // Pop the current dict
        self.dictionaryStack.removeLast()
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // Build the text value
        self.textInProgress += string
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.error = parseError as NSError
    }
    
}
