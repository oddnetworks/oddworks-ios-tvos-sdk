//
//  OddVastService.swift
//  OddSDK
//
//  Created by Patrick McConnell on 7/12/17.
//  Copyright © 2017 Odd Networks. All rights reserved.
//

/*
////////////

 This is a rough implementation of a VAST ad file parser. It currently only supports the simplest
 inline linear ad format based on Googles IMA.

//////////
 */

import UIKit

extension String {
    func intValue() -> Int {
        return Int(self) ?? 0
    }
    
    func boolValue() -> Bool {
        return self.lowercased() == "true" || self == "1" ? true : false
    }
}

enum VastVersion: String {
    case v3_0 = "3.0"
    case v2_1 = "2.1"
    case v2_0 = "2.0"
}

public struct MediaFile {
    var id: String?
    var delivery: String?
    var width: Int?
    var height: Int?
    var type: String?
    var bitrate: Int?
    var scalable: Bool?
    var maintainAspectRatio: Bool?
    public var uri: String?
}

struct VideoClicks {
    var id: String?
    var uri: String?
}

public struct TrackingEvent {
    public var event: String?
    var uri: String?
    
    public func ping() {
        guard let uri = self.uri,
            let url = URL(string: uri) else { return }
        
        let request = NSMutableURLRequest(url: url)
        
        let task = URLSession.shared.dataTask( with: request as URLRequest, completionHandler: { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                OddLogger.debug("VAST Tracking Event Status code: \(httpResponse.statusCode) for \(self.event!)")
                return
            }
            
            OddLogger.warn("No Response for Tracking Event")
        })
        
        task.resume()
    }
}

struct Linear {
    var duration: String = "0:0:0"
    var mediaFiles: [MediaFile] = Array<MediaFile>()
    var trackingEvents: [TrackingEvent] = Array<TrackingEvent>()
    var videoClicks: [VideoClicks]?
    
    var containsMediaFiles: Bool {
        get {
            return !self.mediaFiles.isEmpty
        }
    }
    
    var containsTrackingEvents: Bool {
        get {
            return !self.trackingEvents.isEmpty
        }
    }
    
    var mp4MediaFiles : [MediaFile] {
        get {
            if !self.containsMediaFiles {
                return []
            }
        
            return self.mediaFiles.filter({ (mediaFile) -> Bool in
                return mediaFile.type == "video/mp4"
            })
        }
    }
    
    var bestMP4MediaFile: MediaFile? {
        let mp4s = self.mp4MediaFiles
        
        if mp4s.isEmpty {
            return nil
        }
        
        var bestMp4 = mp4s.first!
        
        let bestBitrate: Int = Int(bestMp4.bitrate ?? 0)
        
        mp4s.forEach { (mp4) in
            if mp4.width == nil || mp4.height == nil { return }
            
            let aspectRatio = mp4.width! / mp4.height!
            let bitrate: Int = Int(mp4.bitrate ?? 0)
            
            let bestWidth = bestMp4.width ?? 0
            
            if mp4.width! >= bestWidth && aspectRatio == 16/9 && bitrate > bestBitrate {
                bestMp4 = mp4
            }
        }
        
        return bestMp4
    }
    
    func info() -> String {
        return "Linear with duration: \(self.duration) has \(self.mediaFiles.count) mediaFiles, \(self.trackingEvents.count) trackingEvents"
    }
}

struct Creative {
    var id: String?
    var sequence: String?
    var linear: Linear?
    
    func info() -> String {
        return "Creative - Id: \(String(describing: self.id)), Sequence: \(String(describing: self.sequence)) and \(String(describing: self.linear?.info()))"
    }
    
    func linearContainsMediaFiles() -> Bool {
        guard let linear = self.linear else { return false }
        
        return linear.containsMediaFiles
    }
    
    func linearContainsTrackingEvents() -> Bool {
        guard let linear = self.linear else { return false }
        
        return linear.containsTrackingEvents
    }
}

// samples so far only have a string
struct AdSystem {
    var value: String?
    var version: String?
}

struct InLine {
    var adSystem: String?
    var adTitle: String?
    var description: String?
    var error: String?
    var impression: String?
    var creatives: [Creative]?
    
    func creativesContainingMediaFiles() -> [Creative]? {
        guard let creatives = self.creatives else { return nil }
        
        return creatives.filter({ (creative) -> Bool in
            return creative.linearContainsMediaFiles()
        })
    }
}

struct Ad {
    var id: String?
    var inLine: InLine?
    
    var allCreativesContainingMediaFiles: [Creative]? {
        get {
            if !self.containsMediaFiles() { return nil }
            
            return self.inLine!.creativesContainingMediaFiles()
        }
    }
    
    var firstCreativeContainingMediaFiles: Creative? {
        get {
            if !self.containsMediaFiles() { return nil }
            
            return self.allCreativesContainingMediaFiles?.first
        }
    }
    
    func containsMediaFiles() -> Bool {
        guard let inLine = inLine else { return false }
        
        guard let inLineWithMediaFiles = inLine.creativesContainingMediaFiles() else { return false }
        
        return !inLineWithMediaFiles.isEmpty
    }

}

public struct Vast {
    var version: VastVersion?
    var ads: [Ad] = []
    
    func firstAdWithMediaFiles() -> Ad? {
        let adsWithMediaFiles = ads.filter { (ad) -> Bool in
            return ad.containsMediaFiles()
        }
        return adsWithMediaFiles.first
    }
    
    public func firstBestAdMp4() -> (mp4: MediaFile?, trackingEvents: [TrackingEvent]) {
        
        guard let ad = self.firstAdWithMediaFiles(),
            let creative = ad.firstCreativeContainingMediaFiles,
            let bestMp4 = creative.linear?.bestMP4MediaFile else {
            return (nil, [])
        }
        
        guard let trackingEvents = creative.linear?.trackingEvents else {
            return (bestMp4, [])
        }
        
        return (bestMp4, trackingEvents)
    }
}


public class OddVastService: NSObject, XMLParserDelegate {
    var vast: Vast? = nil
    
    var currentBranch: String = ""
    
    var currentAd: Ad = Ad()
    var currentInLine: InLine = InLine()
    var currentCreatives: [Creative] = Array<Creative>()
    var currentCreative: Creative = Creative()
    var currentLinear: Linear = Linear()
    var currentMediaFile: MediaFile = MediaFile()
    var currentMediaFiles: [MediaFile] = Array<MediaFile>()
    var currentTrackingEvent: TrackingEvent = TrackingEvent()
    var currentTrackingEvents: [TrackingEvent] = Array<TrackingEvent>()
    
    var readBuffer = [String: String]()
    
    // inserts any paramters into uri as required
    public static func completeURI(_ uri: String, mediaObject: OddMediaObject) -> String {
//        [referrer_url]
//        [description_url]
//        [timestamp]
        let bundleId = Bundle.main.bundleIdentifier ?? "Oddworks"
        
        let referrerURL = bundleId
        
        let id = mediaObject.id ?? "unknownId"
        let title = mediaObject.title ?? "unknown"
        
        let  description = "\(id) - \(title)"
        
        let timestamp = Date().timeIntervalSince1970
        let timeString = String(format: "%.0f", timestamp)
        
        var result = uri
        
        result = result.replacingOccurrences(of: "[referrer_url]", with: referrerURL)
        result = result.replacingOccurrences(of: "[description_url]", with: description)
        result = result.replacingOccurrences(of: "[timestamp]", with: timeString)
        
        OddLogger.debug("VAST completeURI: \(result)")
        
        return result
    }

    public init(url: URL, onComplete: ((Vast?) -> ())?) {
        
        func parseAndCallback(withData data: Data) {
            DispatchQueue.global().async(execute: {
                self.parseVastData(data)
                DispatchQueue.main.async {
                    onComplete?(self.vast)
                }
            })
        }
        
        super.init()
        
        if url.absoluteString.contains("file:///") {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                parseAndCallback(withData: data)
            } catch {
                OddLogger.error("Error creating Data from url")
                return
            }
        } else {
            let request = NSMutableURLRequest(url: url)
            URLSession.shared.reset(completionHandler: {
                OddLogger.debug("Session Reset")
            })
            let task = URLSession.shared.dataTask( with: request as URLRequest, completionHandler: { data, response, error in
                guard let data = data else {
                    if let error = error {
                        OddLogger.error(error.localizedDescription)
                    } else {
                        OddLogger.error("Unable to load xml from server")
                    }
                    return
                }
                parseAndCallback(withData: data)
            })
            task.resume()
        }
    }
    
    func parseVastData(_ data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    // MARK: - XMLParserDelegate
    
    public func parserDidStartDocument(_ parser: XMLParser) {
        OddLogger.debug("Begin Parse")
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        OddLogger.debug("End Parse")
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        self.currentBranch = elementName
        
        switch elementName {
        case "VAST" : parseVast(attributes: attributeDict)
        case "Ad" : parseAd(attributes: attributeDict)
        case "InLine": self.currentInLine = InLine()
        case "Creative": parseCreative(attributes: attributeDict)
        case "Linear": self.currentLinear = Linear()
        case "MediaFile": parseMediaFile(attributes: attributeDict)
        case "Tracking": parseTrackingEvent(attributes: attributeDict)
        default: break
//        default: OddLogger.info("elementName: \(elementName) namespaceURI: \(String(describing: namespaceURI)) qName: \(String(describing: qName)) attribs: \(attributeDict)")
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "MediaFiles": self.currentLinear.mediaFiles = self.currentMediaFiles
        case "TrackingEvents": self.currentLinear.trackingEvents = self.currentTrackingEvents
        case "Linear": self.currentCreative.linear = self.currentLinear;
        case "Creative" : self.currentCreatives.append(self.currentCreative)
        case "Creatives": self.currentInLine.creatives = self.currentCreatives
        case "InLine": self.currentAd.inLine = self.currentInLine
        case "Ad" : self.vast?.ads.append(self.currentAd)
        
        default: break
        }
        
        OddLogger.debug("CurrentCreative: \(self.currentCreative.info())")
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        OddLogger.debug("Found: \(string) for branch: \(self.currentBranch)")
        
        let cleanString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        switch self.currentBranch{
        case "AdSystem" : self.currentInLine.adSystem = cleanString
        case "AdTitle"  : self.currentInLine.adTitle = cleanString
        case "Duration" : self.currentLinear.duration = cleanString
        default: break
        }
        self.currentBranch = ""
    }
    
    public func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        let string = String(data: CDATABlock, encoding: .utf8)
        let cleanString = string?.trimmingCharacters(in: .whitespacesAndNewlines)
        OddLogger.debug("FOUND CDATA: \(String(describing: cleanString))")
        
        switch self.currentBranch {
        case "Description": self.currentInLine.description = cleanString
        case "Error": self.currentInLine.error = cleanString
        case "Impression": self.currentInLine.impression = cleanString
        case "Tracking":
            self.currentTrackingEvent.uri = cleanString
            self.currentTrackingEvents.append(self.currentTrackingEvent)
        case "MediaFile":
            self.currentMediaFile.uri = cleanString
            self.currentMediaFiles.append(self.currentMediaFile)
        default: break
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        OddLogger.error(parseError.localizedDescription)
    }
    //MARK: - Vast parsing
    
    func parseVast(attributes: [String : String]) {
        OddLogger.debug("parseVast: \(attributes)")
        guard let versionString = attributes["version"],
            let version = VastVersion(rawValue: versionString ) else { return }
        
        self.vast = Vast(version: version, ads: [])
        OddLogger.debug("Creating Vast Object version: \(String(describing: self.vast?.version))")
    }
    
    func parseAd(attributes a: [String : String]) {
        self.currentAd = Ad(id: a["id"], inLine: nil)
    }
    
    func parseCreative(attributes a: [String : String]) {
        self.currentCreative = Creative(id: a["id"], sequence: a["sequence"], linear: nil)
    }
    
    func parseMediaFile(attributes a: [String : String]) {
        
        self.currentMediaFile = MediaFile(id: a["id"],
                                  delivery: a["delivery"],
                                  width: a["width"]?.intValue(),
                                  height: a["height"]?.intValue(),
                                  type: a["type"],
                                  bitrate: a["bitrate"]?.intValue(),
                                  scalable: a["scalable"]?.boolValue(),
                                  maintainAspectRatio: a["maintainAspectRatio"]?.boolValue(),
                                  uri: nil)
    }
    
    func parseTrackingEvent(attributes a: [String : String]) {
        OddLogger.debug("parseTrackingEvent: \(a)")
        self.currentTrackingEvent = TrackingEvent(event: a["event"], uri: nil)
    }
    
}

