//
//  Response.swift
//  check-yourself
//
//  Created by Hamish Brindle on 2018-04-13.
//  Copyright © 2018 Hamish Brindle. All rights reserved.
//

import Foundation
import UIKit

public class Response {
    
    private static let ANGER: [String] = [
        "So angry! Who hurt you?",
        "Wow, calm down, son.",
        "Bruh, why you so spicy?!",
        "Don't take that tone..",
        "You must hate everyone."
    ]
    
    private static let SADNESS: [String] = [
        "Goodness, cheer up!",
        "Don't cry bb",
        "Dust yourself off and smile!",
        "Don't be sad, you're great!",
        "Feeling sorry for yourself?"
    ]
    
    private static let JOY: [String] = [
        "That's the spirit!",
        "Wow, what a great attitude!",
        "I love the positivity <3",
        "Inspiring tone, champ!",
        "You da best."
    ]
    
    private static let CONFIDENT: [String] = [
        "You are strong!",
        "Pound that chest!",
        "What a strong tone!",
        "You're a champion!",
        "Stay strong - I love it!"
    ]
    
    private static let TENTATIVE: [String] = [
        "You sound unsure...",
        "You need some conviction.",
        "Hey, be more assertive.",
        "You need some confidence!",
        "Are you unsure? You sound like it."
    ]
    
    private static let FEAR: [String] = [
        "Don't be scared.",
        "Life is too short for fear.",
        "Conquer your fears! Get up!",
        "Don't let fear run your life.",
        "Are you OK? You sound afraid."
    ]
    
    private static let NEUTRAL: [String] = [
        "Not sure what to say...",
        "Hmm, maybe try again?",
        "Fairly neutral, can't respond.",
        "What do I say to that?",
        "OK, that meant nothing to me."
    ]

    public static func getResponse(tone: String) -> String {
        
        let t = tone.uppercased()
        
        switch t {
            
        case "ANGER":
            let random = Int(arc4random_uniform(UInt32(ANGER.count)))
            return ANGER[random]
        case "SADNESS":
            let random = Int(arc4random_uniform(UInt32(SADNESS.count)))
            return SADNESS[random]
        case "JOY":
            let random = Int(arc4random_uniform(UInt32(JOY.count)))
            return JOY[random]
        case "CONFIDENT":
            let random = Int(arc4random_uniform(UInt32(CONFIDENT.count)))
            return CONFIDENT[random]
        case "TENTATIVE":
            let random = Int(arc4random_uniform(UInt32(TENTATIVE.count)))
            return TENTATIVE[random]
        case "FEAR":
            let random = Int(arc4random_uniform(UInt32(FEAR.count)))
            return FEAR[random]
        default:
            let random = Int(arc4random_uniform(UInt32(NEUTRAL.count)))
            return NEUTRAL[random]
        }
    }
    
    public static func getBadgeColor(tone: String) -> UIColor {
        
        var color: UIColor
        let t = tone.uppercased()
        
        switch t {
        case "ANGER":
            color = #colorLiteral(red: 0.9195765257, green: 0.348343879, blue: 0.3516151011, alpha: 1)
            break
        case "SADNESS":
            color = #colorLiteral(red: 0.01700238966, green: 0.03015602583, blue: 0.6164386334, alpha: 1)
            break
        case "JOY":
            color = #colorLiteral(red: 1, green: 0.9565743995, blue: 0.2417983692, alpha: 1)
            break
        case "CONFIDENT":
            color = #colorLiteral(red: 0.05858789119, green: 1, blue: 0.56019796, alpha: 1)
            break
        case "TENTATIVE":
            color = #colorLiteral(red: 1, green: 0.7130702656, blue: 0.1005644615, alpha: 1)
            break
        case "FEAR":
            color = #colorLiteral(red: 0.786209296, green: 0.4962795662, blue: 1, alpha: 1)
            break
        default:
            color = #colorLiteral(red: 0.7712398069, green: 0.7742268459, blue: 0.7579209991, alpha: 1)
        }
        
        return color
        
    }
}
