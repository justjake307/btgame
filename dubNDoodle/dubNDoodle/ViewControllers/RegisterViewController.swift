//
//  RegisterViewController.swift
//  btgame
//
//  Created by Jake Gray on 5/15/18.
//  Copyright © 2018 Jake Gray. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    
    var isAdvertiser: Bool = false
    
    let enterNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Please enter your name."
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let playerNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "John Smith"
        tf.text = UserDefaults.standard.string(forKey: "username") ?? ""
        tf.backgroundColor = UIColor.white
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.clearButtonMode = .whileEditing
        tf.setPadding()
        return tf
    }()
    
    let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainScheme2()
        button.setTitle("Next", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        return button
    }()
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.mainOffWhite()
        self.title = "Player Name"

        // Contstraints
        setupView()
        playerNameTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MCController.shared.advertiserAssistant?.stop()
        MCController.shared.currentGamePeers = []
        MCController.shared.playerArray = []
    }
    
    func setupView() {
        view.addSubview(enterNameLabel)
        view.addSubview(playerNameTextField)
        view.addSubview(submitButton)
        
        enterNameLabel.anchor(top: playerNameTextField.topAnchor,
                              left: view.safeAreaLayoutGuide.leftAnchor,
                              bottom: nil,
                              right: view.safeAreaLayoutGuide.rightAnchor,
                              paddingTop: 8,
                              paddingLeft: 20,
                              paddingBottom: 0,
                              paddingRight: 20,
                              width: 0,
                              height: 100)
        
        playerNameTextField.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                                   left: view.safeAreaLayoutGuide.leftAnchor,
                                   bottom: nil,
                                   right: view.safeAreaLayoutGuide.rightAnchor,
                                   paddingTop: 0,
                                   paddingLeft: 0,
                                   paddingBottom: 0,
                                   paddingRight: 0,
                                   width: 0,
                                   height: 44)
        
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        submitButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

    }
    
    @objc func submitButtonTapped() {
        guard let name = playerNameTextField.text, !name.isEmpty else {
            print("No name entered")
            return
        }
        var formattedName = name
        if name.count > 15 {
            formattedName = String(name.prefix(15))
        }
        print("REGISTER NAME: \(formattedName)")
        //persist name
        UserDefaults.standard.set(formattedName, forKey: "username")
        MCController.shared.displayName = formattedName
        MCController.shared.isAdvertiser = self.isAdvertiser
        MCController.shared.setupMC()
        let destinationVC = SetupViewController()
        destinationVC.delegate = self
        navigationController?.pushViewController(destinationVC, animated: true)
        
    }
    
    @objc func screenTapped() {
        
    }

}
extension RegisterViewController: SetupViewControllerDelegate {
    func userDidGoBackToRegister() {
        print("UserDidGobackToRegster called from registerVC")
        if self == navigationController?.topViewController {
            MCController.shared.session.disconnect()
        }
    }
}
