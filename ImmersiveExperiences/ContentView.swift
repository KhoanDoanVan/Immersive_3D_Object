//
//  ContentView.swift
//  ImmersiveExperiences
//
//  Created by Đoàn Văn Khoan on 13/1/25.
//

import SwiftUI
import UIKit
import SceneKit
import ARKit


struct ContentView: View {
    @State private var selectedModel: String = "digitalCamera" // Default model
    @State private var showModelPicker: Bool = false
    @State private var shouldReset: Bool = false

    var body: some View {
        ZStack {
            ARViewContainer(
                selectedModel: $selectedModel,
                shouldReset: $shouldReset
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    
                    // Reset Button
                    Button {
                        shouldReset = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                Spacer()

                // Model Picker Button
                Button {
                    showModelPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                }
                .padding()
                .sheet(isPresented: $showModelPicker) {
                    ModelPicker(selectedModel: $selectedModel)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension UIColor {
    static let transparentBlue = UIColor(red: 0, green: 0, blue: 1, alpha: 0.2)
}

class ARViewController: UIViewController, ARSCNViewDelegate {

    var arView: ARSCNView!
    var selectedModel: String = "digitalCamera" /// Example model name
    var onResetScene: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize ARSCNView
        arView = ARSCNView(frame: self.view.frame)
        arView.delegate = self
        arView.autoenablesDefaultLighting = true
        self.view.addSubview(arView)
        
        // Add tap gesture for placing objects
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical] // Detect both horizontal and vertical planes
        arView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause AR session
        arView.session.pause()
    }
    
    // MARK: - Handle Tap Gesture
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        performRaycast(at: tapLocation)
    }
    
    // MARK: - Perform Raycast
    private func performRaycast(at point: CGPoint) {
        guard let raycastQuery = arView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any) else {
            print("Raycast query failed")
            return
        }
        
        let results = arView.session.raycast(raycastQuery)
        if let firstResult = results.first {
            add3DObject(at: firstResult) // Place object at the raycast result
        } else {
            print("No surfaces detected")
        }
    }
    
    // MARK: - Add 3D Object
//    private func add3DObject(at raycastResult: ARRaycastResult) {
//        let modelName = selectedModel // Use the selected model dynamically
//        print("Adding 3D object: \(modelName)")
//        
//        // Load the 3D model
//        guard let scene = SCNScene(named: "\(modelName).dae") else {
//            print("Model not found: \(modelName)")
//            return
//        }
//        
//        // Create a container node
//        let containerNode = SCNNode()
//        containerNode.name = "container_\(modelName)"
//        
//        // Add child nodes from the scene to the container node
//        for child in scene.rootNode.childNodes {
//            let childClone = child.clone()
//            containerNode.addChildNode(childClone)
//        }
//        
//        // Set the position using raycast result
//        containerNode.position = SCNVector3(
//            raycastResult.worldTransform.columns.3.x,
//            raycastResult.worldTransform.columns.3.y,
//            raycastResult.worldTransform.columns.3.z
//        )
//        
//        // Add the container node to the AR scene
//        arView.scene.rootNode.addChildNode(containerNode)
//    }
    
    private func add3DObject(at raycastResult: ARRaycastResult) {
        let modelName = selectedModel // Tên mô hình được chọn
        print("Adding 3D object: \(modelName)")
        
        // Load the .scn file
        guard let scene = SCNScene(named: "\(modelName).dae") else {
            print("Model not found: \(modelName)")
            return
        }
        
        // Create a container node
        let containerNode = SCNNode()
        containerNode.name = "container_\(modelName)"
        
        // Add child nodes from the scene to the container node
        for child in scene.rootNode.childNodes {
            let childClone = child.clone()
            containerNode.addChildNode(childClone)
        }
        
        if modelName == "digitalCamera" {
            containerNode.scale = SCNVector3(1, 1, 1)
        } else {
            containerNode.scale = SCNVector3(0.005, 0.005, 0.005)
        }
        
        // Set the position using raycast result
        containerNode.position = SCNVector3(
            raycastResult.worldTransform.columns.3.x,
            raycastResult.worldTransform.columns.3.y,
            raycastResult.worldTransform.columns.3.z
        )
        
        // Add the container node to the AR scene
        arView.scene.rootNode.addChildNode(containerNode)
    }

    // MARK: - Reset Scene
    func resetScene() {
        arView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name?.starts(with: "container_") == true {
                node.removeFromParentNode()
            }
        }
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    @Binding var selectedModel: String
    @Binding var shouldReset: Bool

    func makeUIViewController(context: Context) -> ARViewController {
        let controller = ARViewController()
        controller.selectedModel = selectedModel
        controller.onResetScene = {
            controller.resetScene()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        // Update the selected model dynamically
        uiViewController.selectedModel = selectedModel

        // Reset the scene if required
        if shouldReset {
            uiViewController.resetScene()
            
            // Reset the binding state back to false on the main thread
            DispatchQueue.main.async {
                shouldReset = false
            }
        }
    }
}

struct ModelPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedModel: String

    let models = ["digitalCamera","CathedralRuins_01", "foundationRuin_01", "PillarSegment_01", "RomanRail_01", "RomanTypeCol_01", "RuinArch_01", "RuinPillar_01", "RuinWallSegment_01", "RuinWallSegment_02", "SpeakingStones_01", "TempleRuin_01", "TempleRuin_02"] /// Available models

    var body: some View {
        NavigationStack {
            List(models, id: \.self) { model in
                Button {
                    selectedModel = model
                } label: {
                    HStack {
                        Text(model.capitalized)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedModel == model {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Choose Model")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
