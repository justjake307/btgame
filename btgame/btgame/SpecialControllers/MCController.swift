// PIERCE OWNS THIS FILE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// READ ABOVE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//  MCController.swift
//  btgame
//
//  Created by Jake Gray on 5/15/18.
//  Copyright © 2018 Jake Gray. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreBluetooth

protocol MCControllerDelegate {
    func playerJoinedSession()
    func incrementDoneButtonCounter()
    func toTopicView(timeline: Timeline)
    func toCanvasView(timeline: Timeline)
    func toGuessView(timeline: Timeline)
}

class MCController: NSObject, MCSessionDelegate {
    
    // MARK: - Shared Instance
    static let shared = MCController()
    
    // MARK: - Properties
    
    var isAdvertiser = false
    var displayName: String?
    var delegate: MCControllerDelegate?
    var session: MCSession!
    var peerID: MCPeerID!
    var browser: MCBrowserViewController!
    var advertiser: MCNearbyServiceAdvertiser?
    var advertiserAssistant: MCAdvertiserAssistant?
    var currentGamePeers = [MCPeerID]()
    var playerArray: [Player] = [] {
        didSet {
            let array = playerArray.compactMap({$0.displayName})
            print(array)
        }
    }

    var peerIDDict: [Player:MCPeerID] = [:] {
        didSet {
            print(peerIDDict)
        }
    }
    
    // MARK: - Manager Initializer
    override init() {
        super.init()
    }
    
    func setupMC(){
        guard let name = displayName else {
            return
        }
        peerID = MCPeerID(displayName: name)
        
        // May need to change
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        currentGamePeers.append(peerID)
        
        //login on welcomeview option
        browser = MCBrowserViewController(serviceType: Constants.serviceType, session: session)
        advertiserAssistant = MCAdvertiserAssistant(serviceType: Constants.serviceType, discoveryInfo: nil, session: session)
        
        createPlayer()
    }
    
    fileprivate func createPlayer() {
        guard let name = displayName else {return}
        let newPlayer = PlayerController.create(displayName: name, id: peerID, isAdvertiser: isAdvertiser)
        playerArray.append(newPlayer)
    }
    
    
    // MARK: - MCSession delegate functions
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state{
        case MCSessionState.connected:
            print("Connected to session")
            currentGamePeers.append(peerID)
            delegate?.playerJoinedSession()
            if isAdvertiser {
                do {
                    guard let data = DataManager.shared.encodePlayer(player: playerArray[0]) else {return}
                    print("The advertiser sent himself to a browser")
                    try session.send(data, toPeers: [peerID], with: .reliable)
                } catch let e{
                    print("Error sending advertiser player object: \(e)")
                }
            }
            
            
            
        case MCSessionState.connecting:
            print("Connecting to session")
            
            
        default:
            print("Did not connect to session")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        if let player = DataManager.shared.decodePlayer(from: data){
            playerArray.append(player)
            peerIDDict[player] = peerID
            print("I am in the player handler")
            if !isAdvertiser {
                do {
                    //player receives the advertiser (player object) and then send itself (player) back to advertiser
                    let browserPlayer = playerArray[0]
                    guard let data = DataManager.shared.encodePlayer(player: browserPlayer) else { return }
                    try session.send(data, toPeers: [peerID], with: .reliable)
                } catch let e {
                    print("Error sending self to advertiser: \(e)")
                }
            }
            return
        }
        
        if let _ = DataManager.shared.decodeCounter(from: data){
            if(isAdvertiser){
                delegate?.incrementDoneButtonCounter()
            }
            print("Inside counter function")
            return
        }
//        if let timeline = DataManager.shared.decodeTimeline(from: data){
//            if(isAdvertiser){
//                //do timeline things
//            }
//            return
//        }
        
        if let event = DataManager.shared.decodeEvent(from: data){
            print("Event received")
            if(!isAdvertiser){
                print("EVENT INSTRUCTION: \(event.instruction.rawValue)")
                print("EVENT INSTRUCTION: \(event.timeline)")
                switch event.instruction{
                case .toTopics:
                    delegate?.toTopicView(timeline: event.timeline)
                    GameController.shared.startTimer()
                case .endRoundReturn:
                    return
                    //                    GameController.shared.currentGame.returnedTimelines.append(event.timeline)
//                    if (GameController.shared.currentGame.returnedTimelines.count) == currentGamePeers.count {
//                        GameController.shared.startNewRound()
//                    }
                case .toGuess:
                    delegate?.toGuessView(timeline: event.timeline)
                    GameController.shared.startTimer()
                    return
                case .toCanvas:
                    delegate?.toCanvasView(timeline: event.timeline)
                    GameController.shared.startTimer()
                    return
                }
                
            } else {
                switch event.instruction{
                case .toTopics:
                    return
                case .endRoundReturn:
                    GameController.shared.currentGame.returnedTimelines.append(event.timeline)
                    print("SPECIAL RETURNED TIMELINES: \(GameController.shared.currentGame.returnedTimelines)")
                    if (GameController.shared.currentGame.returnedTimelines.count) == currentGamePeers.count {
                        GameController.shared.startNewRound()
                    }
                case .toGuess:
                    return
                case .toCanvas:
                    return
                }
            }
        }

    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Nothing to do here
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Nothing to do here
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Nothing to do here
    }
    
    func sendEvent(withInstruction instruction: Event.Instruction, timeline: Timeline, toPeers peer: MCPeerID) {
        
        let event = Event(withInstruction: instruction, timeline: timeline)
        print("TIMELINE TOPICS:  \(timeline.possibleTopics)")
        
        guard let eventData = DataManager.shared.encodeEvent(event: event) else {return}

        print("Event Object Data Prepared")
        try? session.send(eventData, toPeers: [peer], with: .reliable)
        print("Event Object Data Sent")

    }

}
