// Developed by Ben Dodson (ben@bendodson.com)

import SwiftUI
import Network

class LocalDeviceManager: ObservableObject {
    
    public private(set) var applicationService: String
    public var didReceiveMessage: ((Data) -> Void)?
    public var errorHandler: ((Error) -> Void)?
    public private(set) var minimumIncompleteLength: Int
    public private(set) var maximumLength: Int
    
    private var listener: NWListener?
    private var endpoint: NWEndpoint?
    private var connection: NWConnection?
    
    init(applicationService: String, didReceiveMessage: ( (Data) -> Void)? = nil, errorHandler: ( (Error) -> Void)? = nil, minimumIncompleteLength: Int = 1024, maximumLength: Int = 1024 * 512) {
        self.applicationService = applicationService
        self.didReceiveMessage = didReceiveMessage
        self.errorHandler = errorHandler
        self.minimumIncompleteLength = minimumIncompleteLength
        self.maximumLength = maximumLength
    }
    
    var isConnected: Bool {
        guard let connection else { return false }
        return connection.state == .ready
    }
 
    func connect(to endpoint: NWEndpoint) {
        self.endpoint = endpoint
        let connection = NWConnection(to: endpoint, using: .applicationService)
        setUpConnection(connection)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    func createListener() throws {
        listener = try NWListener(using: .applicationService)
        listener?.service = .init(applicationService: applicationService)
        
        listener?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .failed(let error):
                errorHandler?(error)
                disconnect()
            default:
                break
            }
            self.objectWillChange.send()
        }
        
        listener?.newConnectionHandler = { connection in
            self.setUpConnection(connection)
        }
        
        listener?.start(queue: .main)
    }
    
    func send(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed({ [weak self] error in
            guard let self else { return }
            if let error {
                errorHandler?(error)
            }
        }))
    }
    
    private func setUpConnection(_ connection: NWConnection) {
        self.connection = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .failed(let error):
                errorHandler?(error)
                disconnect()
            default:
                break
            }
            self.objectWillChange.send()
        }
        
        receive()
        connection.start(queue: .main)
    }
    
    private func receive() {
        guard let connection else { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] content, contentContext, isComplete, error in
            guard let self else { return }
            if let error {
                errorHandler?(error)
            }
            if let content {
                didReceiveMessage?(content)
            }
            receive()
        }
    }
    
    
}
