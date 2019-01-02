//
//  StringExtension.swift
//  ProtonMail - Created on 2/23/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

extension String {
    
//    func hiden() -> String {
//        var newString : String = ""
//        for c in self {
//            switch c {
//            case "(", ")", " ", "-", ".", "@", ":":
//                newString.append(c)
//            default:
//                newString.append("*")
//            }
//        }
//        return newString
//    }
    
    var armored : Bool {
        get {
            return self.hasPrefix("-----BEGIN PGP MESSAGE-----")
        }
    }
    
    func contains(check s: String) -> Bool {
        return self.range(of: s, options: NSString.CompareOptions.caseInsensitive) != nil ? true : false
    }
    
    func isMatch(_ regex: String, options: NSRegularExpression.Options) -> Bool {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            let matchCount = exp.numberOfMatches(in: self,
                                                 options: .reportProgress,
                                                 range: NSMakeRange(0, self.count))
            return matchCount > 0
        } catch {
            PMLog.D("\(error)")
        }
        return false;
    }
    
    
    func hasRe () -> Bool {
        let re = LocalString._composer_short_reply
        let checkCount = re.count
        if self.count < checkCount {
            return false;
        }
        let index = self.index(self.startIndex, offsetBy: checkCount)
        let check = String(self[..<index])
        return check.contains(re)
    }
    
    func hasFwd () -> Bool {
        let fwd = LocalString._composer_short_forward
        let checkCount = fwd.count
        if self.count < checkCount {
            return false;
        }
        let index = self.index(self.startIndex, offsetBy: checkCount)
        let check = String(self[..<index])
        return check.contains(fwd)
    }
    
    /**
     String extension check is email valid use the basic regex
     
     :returns: true | false
     */
    func isValidEmail() -> Bool {
        let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" +
        "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
        "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" +
        "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" +
        "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
        "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    /**
     String extension for remove the whitespaces begain&end
     
     Example:
     " adsf " => "ads"
     
     :returns: trimed string value
     */
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    /**
     String extension parse a json string to a list of dict
     
     :returns: [ [String:String] ]
     */
    func parseJson() -> [[String:Any]]? {
        if self.isEmpty {
            return [];
        }
        
        PMLog.D(self)
        do {
            if let data = self.data(using: String.Encoding.utf8) {
                let decoded = try JSONSerialization.jsonObject(with: data, options: []) as? [[String : Any]]
                return decoded
            }
        } catch let ex as NSError {
            PMLog.D(" func parseJson() -> error error \(ex)")
        }
        return nil
    }
    
    
    /**
     get display address for message details
     
     :returns: parsed address
     */
    func getDisplayAddress() -> String {
        var lists: [String] = []
        if let recipients : [[String : Any]] = self.parseJson() {
            for dict:[String : Any] in recipients {
                let to = dict.getDisplayName()
                if !to.isEmpty  {
                    lists.append(to)
                }
            }
        }
        return lists.joined(separator: ",")
    }
    
    
    
    /**
     String extension split a string by comma
     
     Example:
     "a,b,c,d" => ["a","b","c","d"]
     
     :returns: [String]
     */
    func splitByComma() -> [String] {
        return self.components(separatedBy: ",")
    }
    
    func ln2br() -> String {
        let out = self.replacingOccurrences(of: "\r\n", with: "<br />")
        return out.replacingOccurrences(of: "\n", with: "<br />")
    }
    
    func rmln() -> String {
        return  self.replacingOccurrences(of: "\n", with: "")
    }
    
    func lr2lrln() -> String {
        return  self.replacingOccurrences(of: "\r", with: "\r\n")
    }
    
    /**
     String extension formating the Json format contact for forwarding email.
     
     :returns: String
     */
    func formatJsonContact(_ mailto : Bool = false) -> String {
        var lists: [String] = []
        
        if let recipients : [[String : Any]] = self.parseJson() {
            for dict:[String : Any] in recipients {
                if mailto {
                    lists.append(dict.getName() + " &lt;<a href=\"mailto:\(dict.getAddress())\" class=\"\">\(dict.getAddress())</a>&gt;")
                } else {
                    lists.append(dict.getName() + "&lt;\(dict.getAddress())&gt;")
                }
            }
        }
        return lists.joined(separator: ",")
    }
    
    /**
     String extension decode some encoded htme tags
     
     :returns: String
     */
    func decodeHtml() -> String {
        var result = self.replacingOccurrences(of: "&amp;", with: "&", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&#039;", with: "'", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&#39;", with: "'", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&lt;", with: "<", options: NSString.CompareOptions.caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "&gt;", with: ">", options: NSString.CompareOptions.caseInsensitive, range: nil)
        return result
    }
    
    func encodeHtml() -> String {
        var result = self.replacingOccurrences(of: "&", with: "&amp;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "\"", with: "&quot;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "'", with: "&#039;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: "<", with: "&lt;", options: .caseInsensitive, range: nil)
        result = result.replacingOccurrences(of: ">", with: "&gt;", options: .caseInsensitive, range: nil)
        return result
    }
    
    func plainText() -> String {
        return self
    }
    
    
    func stringByStrippingStyleHTML() -> String {        
        let trimmed = self.preg_replace_none_regex("\r\n", replaceto: "")
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: "<style[^>]*?>.*?</style>", options:options)
            let replacedString = regex.stringByReplacingMatches(in: trimmed,
                                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                                range: NSRange(location: 0, length: trimmed.count),
                                                                withTemplate: "")
            if !replacedString.isEmpty && replacedString.count > 0 {
                return replacedString
            }
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return self
    }
    
    func preg_replace_none_regex (_ partten: String, replaceto:String) -> String {
        return self.replacingOccurrences(of: partten, with: replaceto, options: NSString.CompareOptions.caseInsensitive, range: nil)
    }
    
    func preg_replace (_ partten: String, replaceto:String) -> String {
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            let replacedString = regex.stringByReplacingMatches(in: self,
                                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                                range: NSRange(location: 0, length: self.count),
                                                                withTemplate: replaceto)
            if !replacedString.isEmpty && replacedString.count > 0 {
                return replacedString
            }
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return self
    }
    
    func preg_match (_ partten: String) -> Bool {
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            return regex.firstMatch(in: self,
                                    options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                    range: NSRange(location: 0, length: self.count)) != nil
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        
        return false
    }
    //<link rel="stylesheet" type="text/css" href="http://url/">
    func hasImage () -> Bool {
        
        if self.preg_match("\\ssrc='(?!cid:)") {
            return true
        }
        if self.preg_match("\\ssrc=\"(?!cid:)") {
            return true
        }
        if self.preg_match("xlink:href=") {
            return true
        }
        if self.preg_match("poster=") {
            return true
        }
        if self.preg_match("background=") {
            return true
        }
        if self.preg_match("url\\(|url&#40;|url&#x28;|url&lpar;") {
            return true
        }
        return false
    }
    
    func stringByPurifyImages () -> String {
        //src=\"(?!cid:)(.*?)(^|>|\"|\\s)
        //let out = self.preg_replace("src=\"(.*?)(^|>|\"|\\s)|srcset=\"(.*?)(^|>|\"|\\s)|src='(.*?)(^|>|'|\\s)|xlink:href=\"(.*?)(^|>|\"|\\s)|poster=\"(.*?)(^|>|\"|\\s)|background=\"(.*?)(^|>|\"|\\s)|url\\((.*?)(^|>|\\)|\\s)", replaceto: " ")
        
        var out = self.preg_replace("\\ssrc='(?!cid:)", replaceto: " data-src='")
        out = out.preg_replace("\\ssrc=\"(?!cid:)", replaceto: " data-src=\"")
        out = out.preg_replace("srcset=", replaceto: " data-srcset=")
        out = out.preg_replace("xlink:href=", replaceto: " data-xlink:href=")
        out = out.preg_replace("poster=", replaceto: " data-poster=")
        out = out.preg_replace("background=", replaceto: " data-background=")
        out = out.preg_replace("url\\(|url&#40;|url&#x28;|url&lpar;", replaceto: " data-url(")
        
        
        // this is get http part and replace
        //        if self.preg_match("(<link\\b.*href=[\"'])(http.*.[\"'])(.*>)") {
        //            return true
        //        }
        
        return out
    }
    
    func stringFixImages () -> String {
        var out = self.preg_replace(" data-src='", replaceto: " src='")
        out = out.preg_replace(" data-src=\"", replaceto: " src=\"")
        out = out.preg_replace(" data-srcset=", replaceto: " srcset=")
        out = out.preg_replace(" data-xlink:href=", replaceto: " xlink:href=")
        out = out.preg_replace(" data-poster=", replaceto: " poster=")
        out = out.preg_replace(" data-background=", replaceto: " background=")
        out = out.preg_replace(" data-url\\(", replaceto: " url(")
        
        return out
    }
    
    func stringBySetupInlineImage(_ from : String, to: String) -> String {
        return self.preg_replace_none_regex(from, replaceto:to)
    }
    
    func stringByPurifyHTML() -> String {
        
//
        //|<(\\/?link.*?)>   <[^>]*?alert.*?>| |<[^>]*?confirm.*?> //the comment out part case hpylink have those key works been filtered out
        var out = self.preg_replace("<style[^>]*?>.*?</style>|<script(.*?)<\\/script>|<(\\/?script.*?)>|<(\\/?meta.*?)>|<object(.*?)<\\/object>|<(\\/?object.*?)>|<input(.*?)<\\/input>|<(\\/?input.*?)>|<iframe(.*?)<\\/iframe>|<video(.*?)<\\/video>|<audio(.*?)<\\/audio>|<[^>]*?onload.*?>|<input(.*?)<\\/input>|<[^>]*?prompt.*?>|<img.*?.onerror=alert.*?>|<link[^>]*.href.[^>]*>|<[^>]*? on([a-z]+)\\s*=.*?>|<(\\/?animate.*?)>", replaceto: " ")
        out = out.preg_replace("onload=alert", replaceto: "onload＝alert") //temp
        out = out.preg_replace("onerror=alert", replaceto: "onload＝alert") //temp
        //out = out.preg_replace("vbscript", replaceto: "Vbscript")
        //out = out.preg_replace("vbscript", replaceto: "Vbscript")
        //        var out = self.preg_replace("<script(.*?)<\\/script>", replaceto: "")
        //        //out = out.preg_replace("<(script.*?)>(.*?)<(\\/script.*?)>", replaceto: "")
        //        out = out.preg_replace("<(\\/?script.*?)>", replaceto: "")
        //
        //        out = out.preg_replace("<(\\/?meta.*?)>", replaceto: "");
        //        out = out.preg_replace("<object(.*?)<\\/object>", replaceto: "")
        //        out = out.preg_replace("<(\\/?object.*?)>", replaceto: "")
        //        //out = out.preg_replace("<(object.*?)>(.*?)<(\\/object.*?)>", replaceto: "");
        //        //out = out.preg_replace("<(\\/?objec.*?)>", replaceto: "");
        //        out = out.preg_replace("<input(.*?)<\\/input>", replaceto: "")
        //        out = out.preg_replace("<(\\/?input.*?)>", replaceto: "");
        //
        //        //remove inline style optinal later
        //        //out = out.preg_replace("(<[a-z ]*)(style=(\"|\')(.*?)(\"|\'))([a-z ]*>)", replaceto: "");
        //        out = out.preg_replace("<(\\/?link.*?)>", replaceto: "");
        //
        //        out = out.preg_replace("<iframe(.*?)<\\/iframe>", replaceto: "");
        //        //out = out.preg_replace("<style(.*?)<\\/style>", replaceto: "");
        //        //out = out.preg_replace("\\s+", replaceto:" ")
        //        //out = out.preg_replace("<[ ]+", replaceto:"<")
        //        //out = out.preg_replace("<(style.*?)>(.*?)<(\\/style.*?)>", replaceto: "");
        //        //out = out.preg_replace("<(\\/?style.*?)>", replaceto: "");
        //        //        out = out.preg_replace("javascript", replaceto: "Javascript")
        //        //        out = out.preg_replace("vbscript", replaceto: "Vbscript")
        //        //        out = out.preg_replace("&#", replaceto: "&＃")
        //        //        out = out.preg_replace("<(noframes.*?)>(.*?)<(\\/noframes.*?)>", replaceto: "")
        //        //        out = out.preg_replace("<(\\/?noframes.*?)>", replaceto: "")
        //        //        out = out.preg_replace("<(i?frame.*?)>(.*?)<(\\/i?frame.*?)>", replaceto: "")
        //        //        out = out.preg_replace("<(\\/?i?frame.*?)>", replaceto: "")
        //
        //        //optional later
        //        out = out.preg_replace("<video(.*?)<\\/video>", replaceto: "")
        //        out = out.preg_replace("<audio(.*?)<\\/audio>", replaceto: "")
        
        
        return out;
        //        function htmltotxt($str){
        //            $str = preg_replace( "@<script(.*?)</script>@is", "", $str );  //过滤js
        //            $str = preg_replace( "@<iframe(.*?)</iframe>@is", "", $str ); //过滤frame
        //            $str = preg_replace( "@<style(.*?)</style>@is", "", $str ); //过滤css
        //            $str = preg_replace( "@<(.*?)>@is", "", $str ); //过滤标签
        //            $str=preg_replace("/\s+/", " ", $str); //过滤多余回车
        //            $str=preg_replace("/<[ ]+/si","<",$str); //过滤<__("<"号后面带空格)
        //            $str=preg_replace("/<\!–.*?–>/si","",$str); //注释
        //            $str=preg_replace("/<(\!.*?)>/si","",$str); //过滤DOCTYPE
        //            $str=preg_replace("/<(\/?html.*?)>/si","",$str); //过滤html标签
        //            $str=preg_replace("/<(\/?head.*?)>/si","",$str); //过滤head标签
        //            $str=preg_replace("/<(\/?meta.*?)>/si","",$str); //过滤meta标签
        //            $str=preg_replace("/<(\/?body.*?)>/si","",$str); //过滤body标签
        //            $str=preg_replace("/<(\/?link.*?)>/si","",$str); //过滤link标签
        //            $str=preg_replace("/<(\/?form.*?)>/si","",$str); //过滤form标签
        //            $str=preg_replace("/cookie/si","COOKIE",$str); //过滤COOKIE标签
        //            $str=preg_replace("/<(applet.*?)>(.*?)<(\/applet.*?)>/si","",$str); //过滤applet标签
        //            $str=preg_replace("/<(\/?applet.*?)>/si","",$str); //过滤applet标签
        //            $str=preg_replace("/<(style.*?)>(.*?)<(\/style.*?)>/si","",$str); //过滤style标签
        //            $str=preg_replace("/<(\/?style.*?)>/si","",$str); //过滤style标签
        //            $str=preg_replace("/<(title.*?)>(.*?)<(\/title.*?)>/si","",$str); //过滤title标签
        //            $str=preg_replace("/<(\/?title.*?)>/si","",$str); //过滤title标签
        //            $str=preg_replace("/<(object.*?)>(.*?)<(\/object.*?)>/si","",$str); //过滤object标签
        //            $str=preg_replace("/<(\/?objec.*?)>/si","",$str); //过滤object标签
        //            $str=preg_replace("/<(noframes.*?)>(.*?)<(\/noframes.*?)>/si","",$str); //过滤noframes标签
        //            $str=preg_replace("/<(\/?noframes.*?)>/si","",$str); //过滤noframes标签
        //            $str=preg_replace("/<(i?frame.*?)>(.*?)<(\/i?frame.*?)>/si","",$str); //过滤frame标签
        //            $str=preg_replace("/<(\/?i?frame.*?)>/si","",$str); //过滤frame标签
        //            $str=preg_replace("/<(script.*?)>(.*?)<(\/script.*?)>/si","",$str); //过滤script标签
        //            $str=preg_replace("/<(\/?script.*?)>/si","",$str); //过滤script标签
        //            $str=preg_replace("/javascript/si","Javascript",$str); //过滤script标签
        //            $str=preg_replace("/vbscript/si","Vbscript",$str); //过滤script标签
        //            $str=preg_replace("/on([a-z]+)\s*=/si","On\\1=",$str); //过滤script标签
        //            $str=preg_replace("/&#/si","&＃",$str); //过滤script标签，如javAsCript:alert(
        //            return $str;
        //        }
    }
    
    func stringByEscapeHTML() -> String {
        var out = self.preg_replace("\'", replaceto: "\\\'")
        out = out.preg_replace("\"", replaceto: "\\\"")
        out = out.preg_replace("\n", replaceto: "\\n")
        out = out.preg_replace("\r", replaceto: "\\r")
        return out
    }
    
    func stringByStrippingBodyStyle() -> String {
        let options : NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regexBody = try NSRegularExpression(pattern: "<body[^>]*>", options:options)
            let matches = regexBody.matches(in: self,
                                            options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                            range: NSRange(location: 0, length: self.count))
            if let first = matches.first {
                if first.numberOfRanges > 0 {
                    let range = first.range(at: 0)
                    if let nRange = self.range(from: range) {
                        var bodyTag = String(self[nRange])
                        if !bodyTag.isEmpty && bodyTag.count > 0  {
                            let regexStyle = try NSRegularExpression(pattern: "style=\"[^\"]*\"", options:options)
                            bodyTag = regexStyle.stringByReplacingMatches(in: bodyTag, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: bodyTag.count), withTemplate: "")
                            if !bodyTag.isEmpty && bodyTag.count > 0  {
                                let newBody = self.replacingCharacters(in: nRange, with: bodyTag)
                                if !newBody.isEmpty && newBody.count > 0  {
                                    return newBody
                                }
                            }
                        }
                    }
                }
            }
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return self
    }
    
    static  func randomString(_ len:Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        let length = UInt32 (letters.length)
        for _ in 0 ..< len {
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        return randomString as String
    }
    
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
    
    func encodeBase64() -> String {
        let utf8str = self.data(using: String.Encoding.utf8)
        let base64Encoded = utf8str!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return base64Encoded
    }
    
    func decodeBase64() -> String {
        let decodedData = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0))
        let decodedString = NSString(data: decodedData!, encoding: String.Encoding.utf8.rawValue)
        PMLog.D(any: decodedString!) // foo
        
        return decodedString! as String
    }
    
    func decodeBase64() -> Data {
        let decodedData = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0))
        return decodedData!
    }
    
    //
    func toContacts() -> [ContactVO] {
        var out : [ContactVO] = [ContactVO]();
        if let recipients : [[String : Any]] = self.parseJson() {
            for dict:[String : Any] in recipients {
                let name = dict["Name"] as? String ?? ""
                let email = dict["Address"] as? String ?? ""
                out.append(ContactVO(id: "", name: name, email: email))
            }
        }
        return out
    }
    
    func toContact() -> ContactVO? {
        var out : ContactVO? = nil
        let recipients : [String : String] = self.parseObject()
        
        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""
        
        if !address.isEmpty {
            out = ContactVO(id: "", name: name, email: address)
        }
        return out
    }
    
    func parseObject () -> [String:String] {
        if self.isEmpty {
            return ["" : ""];
        }
        do {
            let data : Data! = self.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:String] ?? ["" : ""]
            return decoded
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return ["":""]
    }
    
    func stringByAppendingPathComponent(_ pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
    
}


extension String {
    
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
}
