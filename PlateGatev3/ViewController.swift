//
//  ViewController.swift
//  PlateGatev3
//
//  Created by Kishan Patel on 2/22/20.
//  Copyright © 2020 Kishan Patel. All rights reserved.
//

import UIKit
import Vision
import AVKit
import CoreMedia

class ViewController: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var OcrRequest: VNRecognizeTextRequest?
    var visionModel: VNCoreMLModel?
    var isInferencing = false
    
    
    
    
            
    // MARK: - AV Property
    var correctResponse = "0"
    var videoCapture: VideoCapture!
    let semaphore = DispatchSemaphore(value: 1)
    
    let videoPreview: UIView = {
       let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let BoundingBoxView: DrawingBoundingBoxView = {
       let boxView = DrawingBoundingBoxView()
        boxView.translatesAutoresizingMaskIntoConstraints = false
        return boxView
    }()

    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .green
        label.font = UIFont(name: "Avenir", size: 30)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setUpModel()
        setupLabel()
        setupCameraView()
        setUpCamera()
        setupBoundingBoxView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    // MARK: - Setup CoreML model and Text Request recognizer
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: model_plate_turi().model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            OcrRequest = VNRecognizeTextRequest(completionHandler: visionTextRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("fail to create vision model")
        }
    }

    // MARK: - SetUp Camera preview
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 10
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // start video preview when setup is done
                self.videoCapture.start()
            }
        }
    }
    
    fileprivate func setupCameraView() {
        view.addSubview(videoPreview)
//        videoPreview.s
        videoPreview.bottomAnchor.constraint(equalTo: identifierLabel.topAnchor).isActive = true
//        videoPreview.bottomAnchor.constraint(equalTo: view.bottom).isActive = true

        videoPreview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        videoPreview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        videoPreview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
//        videoPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

    }
    
    fileprivate func setupBoundingBoxView() {
        view.addSubview(BoundingBoxView)
        BoundingBoxView.bottomAnchor.constraint(equalTo: videoPreview.bottomAnchor).isActive = true
        BoundingBoxView.leftAnchor.constraint(equalTo: videoPreview.leftAnchor).isActive = true
        BoundingBoxView.rightAnchor.constraint(equalTo: videoPreview.rightAnchor).isActive = true
        BoundingBoxView.topAnchor.constraint(equalTo: videoPreview.topAnchor).isActive = true
    }
    
    fileprivate func setupLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -0).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }

}

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        if !self.isInferencing, let pixelBuffer = pixelBuffer {
            self.isInferencing = true
            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}
extension String {

func fromBase64() -> String? {
    guard let data = Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0)) else {
        return nil
    }

    return String(data: data as Data, encoding: String.Encoding.utf8)
}

func toBase64() -> String? {
    guard let data = self.data(using: String.Encoding.utf8) else {
        return nil
    }

    return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}

extension ViewController {
    
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        guard let OcrRequest = OcrRequest else {fatalError()}
        OcrRequest.recognitionLevel = .fast
        // vision framework configures the input size of image following our model's input configuration automatically which is 416X416
        self.semaphore.wait()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request, OcrRequest])
    }
    
    // MARK: - Post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let predictions = request.results as? [VNRecognizedObjectObservation] {
            DispatchQueue.main.async {
                self.BoundingBoxView.predictedObjects = predictions
                self.isInferencing = false
            }
        } else {
            
            self.isInferencing = false
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        for currentObservation in observations {
            let topCandidate = currentObservation.topCandidates(1)
                if let recognizedText = topCandidate.first {
                    DispatchQueue.main.async {
                        self.identifierLabel.text = recognizedText.string
                    }
                }
                
            }
        }
        
        request.recognitionLevel = .fast
        self.semaphore.signal()
    }
    
    func visionTextRequestDidComplete(request: VNRequest, error: Error?) {
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            for currentObservation in observations {
                let topCandidate = currentObservation.topCandidates(1)
                    if let recognizedText = topCandidate.first {
                        DispatchQueue.main.async {
                            //var ierror: NSError?
                            //var regex: NSREgularExpression = NSRegularExpression(pattern: ".*", options: 0)
                            //recognizedText.string =
                            let myString = recognizedText.string
                            //let regex = try! NSRegularExpression(pattern: ".*([A-Z]{3})(.{0,3})([0-9]{3}).*")
                            let regex = try! NSRegularExpression(pattern: ".*([A-Z0-9]{3})([^A-Z0-9]{1,3})([A-Z0-9]{3}).*")
                            let range = NSMakeRange(0, myString.count)
                            let modString = regex.stringByReplacingMatches(in: myString, options: [], range: range, withTemplate: "$1$3")
                            
                            
                            
                            
                            //if (recognizedText.string.range(of:  #"\b[[A-Z0-9][A-Z0-9][A-Z0-9][\.\s]?[A-Z0-9][A-Z0-9][A-Z0-9]]\b"#, options: .regularExpression) != nil){
                            if (myString != modString) {
                                self.identifierLabel.text = modString
                                
                                
                                let en3 = modString
                                let url = URL(string: "http://plategate.tech/check.php?plate=\(en3)")

                                guard let requestUrl = url else{ fatalError() }
                                var request = URLRequest(url: requestUrl)
                                
                                request.httpMethod = "GET"
                                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                                    // Check if Error took place
                                    
                                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                                        self.correctResponse = dataString
                                    }
                                    
                                }
                                task.resume()
                                if (self.correctResponse == "1") {
                                    //print("in set")
                                    self.BoundingBoxView.matchColor = 1
//                                    self.identifierLabel.textColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                                    
                                    
                                } else {
                                    //print("not in sent")
                                    
                                    self.BoundingBoxView.matchColor = 0
//                                    self.identifierLabel.textColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
                                    
                                    
                                    
                
                                }
                                
                            }
//                            else{
//                                DrawingBoundingBoxView.setMatching(false)
//                            }
                        }
                    }
                    
                }
            self.semaphore.signal()
        }
}


