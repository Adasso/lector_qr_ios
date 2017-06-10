//
//  ViewController.swift
//  computerRegister
//
//  Created by Alvaro Dasso on 5/27/17.
//  Copyright © 2017 Alvaro Dasso. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import MessageUI


class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    @IBAction func closeButtom(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    var labsRef: DatabaseReference!
    var dbRef: DatabaseReference!
    var databaseHandleLab:DatabaseHandle!
    
    
     var ref: DatabaseReference!
    
    
    
    var labnumber: String!
    var computernumber: String!
    var floornumber: String!

    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    let supportedCodeTypes = [AVMetadataObjectTypeUPCECode,
                              AVMetadataObjectTypeCode39Code,
                              AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeCode93Code,
                              AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypeEAN8Code,
                              AVMetadataObjectTypeEAN13Code,
                              AVMetadataObjectTypeAztecCode,
                              AVMetadataObjectTypePDF417Code,
                              AVMetadataObjectTypeQRCode]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //dbRef = rootRef.child("cloud-b9835")

   
        
        
        
       
   /*     databaseHandleLab = Database.database().reference().child("Labs").observe(.value, with: { (snapshot) in
            
            var newItems = [DataSnapshot]()
            
            for item in snapshot.children {
                newItems.append(item as! DataSnapshot)
            }
            
        }){ (error) in
            print(error.localizedDescription)
        }
        */
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        
//        let qrRef = labsRef.child("PC_01_L301")
        
        
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)

        // Set delegate and use the default dispatch queue to execute the call back
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
      
        // Move the message label and top bar to the front
        view.bringSubview(toFront: messageLabel)
        view.bringSubview(toFront: topbar)
        
        // Start video capture.
        captureSession?.startRunning()
        
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR/barcode is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                
               var qrReaded = metadataObj.stringValue
                messageLabel.text = metadataObj.stringValue
                callDatabase(qr: qrReaded!)
            }
        }
    }
    
    func callDatabase(qr: String){
        
        let ref = Database.database().reference().child("Labs")
        let qrRef = ref.child(qr)
        let labnumRef = qrRef.child("Laboratorio")
        let compRef = qrRef.child("Computadora")
        let floorRef = qrRef.child("Piso")
        
        databaseHandleLab = qrRef.observe(DataEventType.value, with: { (snapshot) in
            if ( snapshot.value is NSNull ) {
                print("not found")
            } else {
                
                if let dictionary = snapshot.value as? [String : AnyObject] {
                    
                    
                     self.labnumber = dictionary["Laboratorio"] as! String
                     self.computernumber = dictionary["Computadora"] as! String
                     self.floornumber = dictionary["Piso"] as! String
                    print("lab :" + self.labnumber + "Computadora : " + self.computernumber + "Piso : " + self.floornumber)
                    if (self.labnumber != nil && self.computernumber != nil && self.floornumber != nil){
                         self.captureSession?.stopRunning();
                     self.sendEmail( )
                    }

                }
           
            }
        }) { (Error) in
            
        }
        
      
    
    }
    
    
    func sendEmail( ) {
        
        
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self as! MFMailComposeViewControllerDelegate // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["alvaro.dasso@utec.edu.pe"])
        mailComposerVC.setSubject("Falla de computadora "+labnumber)
        mailComposerVC.setMessageBody("Problemas: \n\n Laboratorio: "+labnumber+"\n Piso: "+floornumber+"\n Computadora: "+computernumber+"\n\n Descripción:\n\n", isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        dismiss(animated: true, completion: nil)
    }
    /*func sendEmail(){
        let userID = Auth.auth().currentUser?.uid
        ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let username = value?["username"] as? String ?? ""
            let user = User.init(username: username)
            
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
    }*/
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession?.stopRunning();
        }
    }


}

