//
//  ViewController.swift
//  check-yourself
//
//  Created by Hamish Brindle on 2018-03-23.
//  Copyright © 2018 Hamish Brindle. All rights reserved.
//

import Foundation
import UIKit
import Speech
import ToneAnalyzerV3
import AssistantV1

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    // MARK: Properties
    
    // Outlets
    @IBOutlet weak var badge: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var response: UILabel!
    @IBOutlet weak var toneLabel: UILabel!
    @IBOutlet weak var recording: UILabel!
    
    // UI
    var gradient: CAGradientLayer!
    
    // Dispatch (ASync)
    let dispatchGroup = DispatchGroup()
    
    // Speech-to-Text
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    let audioEngine = AVAudioEngine()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var speechResult = SFSpeechRecognitionResult()
    var isRecording = false
    
    // Watson Services
    var assistant: Assistant!
    var toneAnalyzer: ToneAnalyzer!
    var workspace = Credentials.AssistantWorkspace
    var context: Context?
    var watsonResponse: String?
    var toneResponse: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWatsonServices()
        // startAssistant()
    }
}

// MARK: - Overrides
extension ViewController {
    
    /// Color of the status bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    /// Not entirely sure why we need this yet, but we do
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = status.bounds
    }
    
}

// MARK: - Watson Services
extension ViewController {
    
    /// Setup our Watson API request objects
    func setupWatsonServices() {
        toneAnalyzer = ToneAnalyzer(
            username: Credentials.ToneAnalyzerUsername,
            password: Credentials.ToneAnalyzerPassword,
            version: "2018-03-23" // use today's date for the most recent version
        )
        assistant = Assistant(
            username: Credentials.AssistantUsername,
            password: Credentials.AssistantPassword,
            version: "2018-03-23" // use today's date for the most recent version
        )
    }
    
    /// Present an error message if shit goes sideways
    func failure(error: Error) {
        let alert = UIAlertController(
            title: "Not Connected!",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    /// Start a new conversation with our bot
    func startAssistant() {
        assistant.message(
            workspaceID: workspace,
            failure: failure,
            success: presentAssistantResponse
        )
    }
    
    /// Send Assistant a message
    func sendAssistantMessage(input: String) {
        
        let i = InputData(text: input)
        let request = MessageRequest(input: i, context: self.context)
        print(request)
        self.assistant.message(
            workspaceID: workspace,
            request: request,
            failure: failure,
            success: presentAssistantResponse
        )
    }
    
    /// Present Assistant's reply and present it to the user
    func presentAssistantResponse(_ response: MessageResponse) {
        
        // Launch thread
        dispatchGroup.enter()
        
        let text = response.output.text.joined()
        context = response.context // save context to continue conversation
        watsonResponse = text
        
        // Finish thread
        dispatchGroup.leave()
        
        // Tie our result in the with UI thread
        dispatchGroup.notify(queue: .main) {
            self.response.text = self.watsonResponse!
        }
    }
    
    /// Without the use of Watson, we use our own responses (boring).
    func presentResponse() {
        self.response.text = Response.getResponse(tone: toneResponse!)
    }
    
    /// Send input to API for tone analysis
    func requestTone(input: String) {
        
        // Launch thread
        dispatchGroup.enter()
        
        // Let user know we're processing their input
        self.recording.text = "Waiting..."
        
        // Send off the user's input to be analyzed
        let tone = ToneInput.init(text: input)
        toneAnalyzer.tone(toneInput: tone, contentType: "text/plain", failure: failure) { tones in
            self.toneResponse = self.analyze(tone: tones) // Make our custom toneResponse string
            self.dispatchGroup.leave()
        }
        
        // Processing is done, present results to user
        dispatchGroup.notify(queue: .main) {
            self.toneLabel.text = self.toneResponse
            self.presentResponse()
            
            let badgeColor: UIColor = Response.getBadgeColor(tone: self.toneResponse!)
            self.badge.backgroundColor = badgeColor
            
            self.recording.text = "Press To Record"
        }
    }
}

// MARK: - Tone Analysis
extension ViewController {
    
    /// Analyze the tone and present (concat) all the results
    func analyze(tone: ToneAnalysis) -> String {
        
        // The number of recognized tones
        let count = tone.documentTone.tones!.count
        
        if count == 0 {
            return "Neutral"
        }
        
        return tone.documentTone.tones![safe: 0]!.toneName
    }
    
}

// MARK: - Speech-to-Text
extension ViewController {
    
    /// Begin recording user's voice
    func startRecording() throws {
        
        if !audioEngine.isRunning {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            let inputNode = audioEngine.inputNode
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create the recognition request") }
            
            // Configure request so that results are returned before audio recording is finished
            recognitionRequest.shouldReportPartialResults = true
            
            // A recognition task is used for speech recognition sessions
            // A reference for the task is saved so it can be cancelled
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    print("result: \(result.isFinal)")
                    isFinal = result.isFinal
                    
                    self.speechResult = result
                    self.status.text = result.bestTranscription.formattedString
                    
                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
                
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
        }
        
    }
    
    /// Stop recording and send results off to be processed
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            
            // Cancel the previous task if it's running
            if let recognitionTask = recognitionTask {
                recognitionTask.cancel()
                self.recognitionTask = nil
            }
            
            let i = speechResult.bestTranscription.formattedString
            
            // Request the sentiment of the user's input
            requestTone(input: i)
            
        }
    }
}

// MARK: Configuration
extension ViewController {
    
    /// Setup all the UI elements
    func setupUI() {
        // Fade edges of label for text input
        gradient = CAGradientLayer()
        gradient.frame = status.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 0, 0.9, 1]
        gradient.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        status.layer.mask = gradient
        
        badge.layer.cornerRadius = 20
    }
    
    /// Listener: Holding down record button
    @IBAction func recordButtonDown(_ sender: UIButton) {
        if !isRecording {
            do {
                try self.startRecording()
                recording.text = "Recording..."
                status.text = ""
                isRecording = true
            } catch {
                print("Could not record voice: \(error).")
            }
        }
    }
    
    /// Listener: Releasing record button
    @IBAction func recordButtonUp(_ sender: UIButton) {
        if isRecording {
            recording.text = "Finished Recording."
            stopRecording()
            isRecording = false
        }
    }
}

// MARK: - Utilities
extension Array {
    
    /// Shit, can't remember what this does, but it circumnavigates 'indices out of bounds' errors inside tone analysis
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
    
}

