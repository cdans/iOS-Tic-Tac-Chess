//
//  GameViewController.swift
//  Tic Tac Chess iOS
//
//  Created by Christoph Dansard on 05.09.24.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {

    var gameView: SCNView {
        return self.view as! SCNView
    }
    
    var gameController: GameController!
    var gameBoard: SCNNode!
    var currentPlayer: Player = .x
    var boardState: [[Player?]] = Array(repeating: Array(repeating: nil, count: 4), count: 4)
    
    enum Player: String {
        case x = "X"
        case o = "O"
        
        var color: UIColor {
            switch self {
            case .x: return .red
            case .o: return .blue
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupCamera()
        createGameBoard()
        drawBoardLines()
        
        // Add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        var gestureRecognizers = gameView.gestureRecognizers ?? []
        gestureRecognizers.insert(tapGesture, at: 0)
        self.gameView.gestureRecognizers = gestureRecognizers
    }
    
    func setupScene() {
        let scene = SCNScene()
        gameView.scene = scene
        gameView.allowsCameraControl = true
        gameView.showsStatistics = true
        gameView.backgroundColor = .black
    }
    
    func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // Adjust camera position to view the board from above and centered
        cameraNode.position = SCNVector3(x: 0, y: 8, z: 0)
        cameraNode.eulerAngles = SCNVector3(x: -.pi/2, y: 0, z: 0)  // Point camera downwards
        gameView.scene?.rootNode.addChildNode(cameraNode)
    }
    
    func createGameBoard() {
        gameBoard = SCNNode()
        
        for x in 0..<4 {
            for z in 0..<4 {
                let cellNode = SCNNode(geometry: SCNBox(width: 1, height: 0.1, length: 1, chamferRadius: 0))
                cellNode.position = SCNVector3(x: Float(x) - 1.5, y: 0, z: Float(z) - 1.5)
                cellNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                gameBoard.addChildNode(cellNode)
            }
        }
        
        gameView.scene?.rootNode.addChildNode(gameBoard)
    }
    
    func drawBoardLines() {
        let lineColor = UIColor.black
        let lineWidth: CGFloat = 0.02
        
        // Draw horizontal lines
        for i in 1...3 {
            let line = SCNNode(geometry: SCNBox(width: 4, height: lineWidth, length: lineWidth, chamferRadius: 0))
            line.geometry?.firstMaterial?.diffuse.contents = lineColor
            line.position = SCNVector3(x: 0, y: 0.05, z: Float(i) - 2)
            gameBoard.addChildNode(line)
        }
        
        // Draw vertical lines
        for i in 1...3 {
            let line = SCNNode(geometry: SCNBox(width: lineWidth, height: lineWidth, length: 4, chamferRadius: 0))
            line.geometry?.firstMaterial?.diffuse.contents = lineColor
            line.position = SCNVector3(x: Float(i) - 2, y: 0.05, z: 0)
            gameBoard.addChildNode(line)
        }
    }
    
    @objc
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        let location = gestureRecognizer.location(in: gameView)
        let hitResults = gameView.hitTest(location, options: [:])
        
        if let result = hitResults.first {
            let node = result.node
            if node.geometry is SCNBox {
                let position = node.position
                let boardX = Int(position.x + 1.5)
                let boardZ = Int(position.z + 1.5)
                
                if boardState[boardX][boardZ] == nil {
                    placePiece(at: node)
                    boardState[boardX][boardZ] = currentPlayer
                    
                    if checkForWin() {
                        showWinnerMessage()
                        resetBoard()
                    } else if isBoardFull() {
                        showDrawMessage()
                        resetBoard()
                    } else {
                        switchPlayer()
                    }
                }
            }
        }
    }
    
    func placePiece(at node: SCNNode) {
        let pieceNode = SCNNode(geometry: SCNSphere(radius: 0.4))
        pieceNode.position = SCNVector3(node.position.x, 0.5, node.position.z)
        pieceNode.geometry?.firstMaterial?.diffuse.contents = currentPlayer.color
        gameBoard.addChildNode(pieceNode)
    }
    
    func switchPlayer() {
        currentPlayer = (currentPlayer == .x) ? .o : .x
    }
    
    func checkForWin() -> Bool {
        // Check rows
        for row in boardState {
            if row.compactMap({ $0 }).count == 4 && Set(row.compactMap { $0 }).count == 1 {
                return true
            }
        }
        
        // Check columns
        for col in 0..<4 {
            let column = boardState.map { $0[col] }
            if column.compactMap({ $0 }).count == 4 && Set(column.compactMap { $0 }).count == 1 {
                return true
            }
        }
        
        // Check diagonals
        let diagonal1 = [boardState[0][0], boardState[1][1], boardState[2][2], boardState[3][3]]
        let diagonal2 = [boardState[0][3], boardState[1][2], boardState[2][1], boardState[3][0]]
        
        if diagonal1.compactMap({ $0 }).count == 4 && Set(diagonal1.compactMap { $0 }).count == 1 {
            return true
        }
        
        if diagonal2.compactMap({ $0 }).count == 4 && Set(diagonal2.compactMap { $0 }).count == 1 {
            return true
        }
        
        return false
    }
    
    func isBoardFull() -> Bool {
        return boardState.flatMap { $0 }.compactMap { $0 }.count == 16
    }
    
    func showWinnerMessage() {
        let alert = UIAlertController(title: "Winner!", message: "Player \(currentPlayer.rawValue) wins!", preferredStyle: .alert)
        alert.view.tintColor = currentPlayer.color
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showDrawMessage() {
        let alert = UIAlertController(title: "Draw!", message: "The game ended in a draw.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func resetBoard() {
        // Remove all piece nodes from the game board
        gameBoard.childNodes.filter { $0.geometry is SCNSphere }.forEach { $0.removeFromParentNode() }
        
        // Reset the board state
        boardState = Array(repeating: Array(repeating: nil, count: 4), count: 4)
        
        // Reset the current player to X
        currentPlayer = .x
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}
