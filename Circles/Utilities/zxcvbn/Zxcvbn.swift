//
//  Zxcvbn.swift
//  Circles
//
//  Created by Charles Wright on 4/1/23.
//




#if false

import Foundation

public struct Match: Comparable {
    var pattern: String
    var i: Int
    var j: Int
    var token: String
    var matchedWord: String
    var rank: Int
    var dictionaryName: String
    var reversed: Bool
    var l33t: Bool
    
    public static func < (lhs: Match, rhs: Match) -> Bool {
        if lhs.i == rhs.i {
            return lhs.j < rhs.j
        }
        else {
            return lhs.i < rhs.i
        }
    }
}

public func dictionaryMatch(password: String,
                            rankedDictionaries: [String: [String:Int]]
) -> [Match] {
    var matches = [Match]()
    let length = password.count
    let lowered = password.lowercased()
    
    for (dictionaryName, rankedDict) in rankedDictionaries {
        for i in 0..<length {
            let r1 = password.index(password.startIndex, offsetBy: i)
            for j in (i+1)..<length {
                let r2 = password.index(password.startIndex, offsetBy: j+1)
                let range = r1 ... r2
                let word = String(lowered[range])
                if let rank = rankedDict[word] {
                    let match = Match(pattern: "dictionary",
                                      i: i,
                                      j: j,
                                      token: String(password[r1...r2]),
                                      matchedWord: word,
                                      rank: rank,
                                      dictionaryName: dictionaryName,
                                      reversed: false,
                                      l33t: false)
                    matches.append(match)
                }
            }
        }
    }
    return matches.sorted()
}

public func reverseDictionaryMatch(password: String,
                                   rankedDictionaries: [String: [String:Int]]
) -> [Match] {
    let reversed = String(password.reversed())
    let matches = dictionaryMatch(password: reversed,
                                  rankedDictionaries: rankedDictionaries)
    return matches.map { m in
        Match(pattern: m.pattern,
              i: password.count - 1 - m.j,
              j: password.count - 1 - m.i,
              token: String(m.token.reversed()),
              matchedWord: m.matchedWord,
              rank: m.rank,
              dictionaryName: m.dictionaryName,
              reversed: true,
              l33t: false)
    }
    .sorted()
}

let L33T_TABLE: [String: [String]] = [
    "a": ["4", "@"],
    "b": ["8"],
    "c": ["(", "{", "[", "<"],
    "e": ["3"],
    "g": ["6", "9"],
    "i": ["1", "!", "|"],
    "l": ["1", "|", "7"],
    "o": ["0"],
    "s": ["$", "5"],
    "t": ["+", "7"],
    "x": ["%"],
    "z": ["2"],
]

let REGEXEN: [String: Regex] = [
    "recent_year":  #/19\d\d|200\d|201\d|202\d/g/#
]

let DATE_MAX_YEAR = 2050
let DATE_MIN_YEAR = 1000

let DATE_SPLITS: [Int: [[Int]]] = [
  4:[         // for length-4 strings, eg 1191 or 9111, two ways to split:
    [1, 2],   // 1 1 91 (2nd split starts at index 1, 3rd at index 2)
    [2, 3],   // 91 1 1
    ],
  5:[
    [1, 3],   // 1 11 91
    [2, 3],   // 11 1 91
    ],
  6:[
    [1, 2],   // 1 1 1991
    [2, 4],   // 11 11 91
    [4, 5],   // 1991 1 1
    ],
  7:[
    [1, 3],   // 1 11 1991
    [2, 3],   // 11 1 1991
    [4, 5],   // 1991 1 11
    [4, 6],   // 1991 11 1
    ],
  8:[
    [2, 4],   // 11 11 1991
    [4, 6],   // 1991 11 11
    ]
]

func relevantL33tSubtable(password: String,
                          table: [String: [String]]
) -> [String: [String]] {
    var subtable: [String: [String]] = [:]
    let passwordChars = Set(password.chars)

    for (letter, subs) in table {
        let relevantSubs = subs.filter { passwordChars.contains($0) }
        if !relevantSubs.isEmpty {
            subtable[letter] = relevantSubs
        }
    }
    return subtable
}

func enumerateL33tSubs(table: [String: [String]]) {
    let keys = Array(table.keys)
    

}

public func l33tMatch(password: String,
                      rankedDictionaries: [String: [String:Int]]
) -> [Match] {
    var matches = [Match]()
    
    
    
    return matches
}


public func repeatMatch(password: String,
                        rankedDictionaries: [String: [String:Int]]
) -> [Match] {
    var matches = [Match]()

    let greedy = #/(.+)\1+/#
    let lazy = #/(.+?)\1+/#
    let lazyAnchored = #/(.+?)\1+$/#
    
    var lastIndex = 0
    
    while lastIndex < password.count {
        let substring = password.suffix(from: password.index(password.startIndex, offsetBy: lastIndex))
        guard let greedyMatch = try? greedy.firstMatch(in: substring)
        else {
            break
        }
                
    }

    return matches
}

#endif
