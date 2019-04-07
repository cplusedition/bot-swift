/*
 *  Copyright (c) 2018, Cplusedition Limited.  All rights reserved.
 *
 *  This file is licensed to you under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

public struct RFC1123 {
    static let shared = RFC1123()
    let formatter = DateFormatter()
    public init() {
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
    }
}

public struct RFC822 {
    static let shared = RFC822()
    let formatter = DateFormatter()
    public init() {
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
    }
}

public struct ISO8601 {
    static let shared = ISO8601()
    let formatter = DateFormatter()
    public init() {
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
    }
}

public struct USDateFormatter {
    static let shared = USDateFormatter()
    let formatter = DateFormatter()
    public init() {
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MM/dd/yyyy HH':'mm':'ss"
    }
}

public extension Date {
    public var rfc1123: String {
        return RFC1123.shared.formatter.string(from: self)
    }
    
    public init?(rfc1123: String) {
        guard let date = RFC1123.shared.formatter.date(from: rfc1123) else {
            return nil
        }
        self = date
    }
    
    public var rfc822: String {
        return RFC822.shared.formatter.string(from: self)
    }
    
    public init?(rfc822: String) {
        guard let date = RFC822.shared.formatter.date(from: rfc822) else {
            return nil
        }
        self = date
    }
    
    public var iso8601: String {
        return ISO8601.shared.formatter.string(from: self)
    }
    
    public init?(iso8601: String) {
        guard let date = ISO8601.shared.formatter.date(from: iso8601) else {
            return nil
        }
        self = date
    }
    
    public var enUS: String {
        return USDateFormatter.shared.formatter.string(from: self)
    }
    
    public init?(enUS: String) {
        guard let date = USDateFormatter.shared.formatter.date(from: enUS) else {
            return nil
        }
        self = date
    }
}

public class DateUtil {
    
    public static let K: Int = 1000
    public static let M: Int = 1000 * 1000
    public static let SEC: Int64 = 1000 // in ms
    public static let MIN: Int64 = SEC * 60 // in ms
    public static let HOUR: Int64 = MIN * 60 // in ms
    public static let DAY: Int64 = HOUR * 24 // in ms
    public static let GMT = TimeZone(abbreviation: "GMT")!
    
    public static var ms: Int64 {
        return Int64((Date.timeIntervalBetween1970AndReferenceDate + Date.timeIntervalSinceReferenceDate)*1000)
    }

    public static var now: Date {
        return Date()
    }
    
    public static var today: String {
        return simpleDateString()
    }
    
   public static func getCalendar(_ locale: Locale = Locale.current) -> Calendar {
        return locale.calendar;
    }
    
    public static func shortWeekdaySymbol(_ weekday: Int) -> String? {
        let symbols = getCalendar().shortWeekdaySymbols
        guard weekday >= 1 && weekday <= symbols.count else { return nil }
        return symbols[weekday - 1]
    }
    
    public static func duration(days: Int64? = nil, hours: Int64? = nil, minutes: Int64? = nil, seconds: Int64? = nil, ms: Int64? = nil) -> Int64 {
        var ret: Int64 = 0
        if let v = ms {
            ret += v
        }
        if let v = seconds {
            ret += v * DateUtil.SEC
        }
        if let v = minutes {
            ret += v * DateUtil.MIN
        }
        if let v = hours {
            ret += v * DateUtil.HOUR
        }
        if let v = days {
            ret += v * DAY
        }
        return ret;
    }
    
    public static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int=0,
        _ minute: Int=0,
        _ second: Int=0,
        _ ms: Int=0,
        timezone: TimeZone?=TimeZone.current) -> Date {
        let c = DateComponents(
            calendar: getCalendar(),
            timeZone: timezone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: ms*1000*1000)
            return c.date!
    }
    
   public static func components(_ date: Date, tz: TimeZone = TimeZone.current) -> DateComponents {
        return getCalendar().dateComponents(in: tz, from: date)
    }
    
    public static func components(_ components: Set<Calendar.Component>, _ date: Date) -> DateComponents {
        return getCalendar().dateComponents(components, from: date)
    }
    
    public static func simpleDateString(_ date: Date = Date()) -> String {
        let c = components(date)
        return String(format: "%04d%02d%02d", c.year!, c.month!, c.day!)
    }
    
    public static func simpleDateString(_ ms: Int64) -> String {
        return simpleDateString(Date(ms: ms))
    }
    
    public static func simpleTimeString(_ date: Date = Date()) -> String {
        let c = components(date)
        return String(format: "%02d%02d%02d", c.hour!, c.minute!, c.second!)
    }
    
    public static func simpleTimeString(_ ms: Int64) -> String {
        return simpleTimeString(Date(ms: ms))
    }
    
    public static func simpleDateTimeString(_ ms: Int64) -> String {
        return simpleDateTimeString(Date(ms: ms))
    }
    
    /// @return A string in form YYYYMMdd-HHmmss
    public static func simpleDateTimeString(_ date: Date = Date()) -> String {
        let c = components(date)
        return String(format: "%04d%02d%02d-%02d%02d%02d", c.year!, c.month!, c.day!, c.hour!, c.minute!, c.second!)
    }
    
    public static func simpleDateTimeMsString(_ ms: Int64) -> String {
        return simpleDateTimeMsString(Date(ms: ms))
    }
    
    /// @return A string in form YYYYMMdd-HHmmssms
    public static func simpleDateTimeMsString(_ date: Date = Date()) -> String {
        let c = components(date)
        let ms = UInt((Double(c.nanosecond!) / Double(M)).rounded())
        return String(format: "%04d%02d%02d-%02d%02d%02d%03d", c.year!, c.month!, c.day!, c.hour!, c.minute!, c.second!, ms)
    }
    
    /// Print given time or now() in default date format.
   public static func toString(ms: Int64? = nil) -> String {
        return Date(timeIntervalSince1970: Double(ms == nil ? DateUtil.ms : ms!)/1000.0).enUS
    }

    /// Format the given date using the given format template, timezone and locale. Current timezone and locale is used if not specified.
   public static func toString(format: String, date: Date, timezone: TimeZone = TimeZone.current, locale: Locale = Locale.current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timezone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
}

