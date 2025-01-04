import Foundation
import Alamofire
import Web3

public struct ChainGetBlockResponse: JSONRpcResponse, Codable {
    public var id: UInt16?
    public var jsonrpc: String?
    public var error: JsonRpcError?
    public var result: BlockResult?
}

public struct ChainBlockHashResponse: JSONRpcResponse, Codable {
    public var id: UInt16?
    public var jsonrpc: String?
    public var error: JsonRpcError?
    public var result: EthereumData?
}

public struct BlockResult: Codable {
    public var block: Block
}

public struct Block: Codable {
    public var header: Header
    public var extrinsics: [EthereumData]
}

public struct Header: Codable {
    public var parentHash: EthereumData
    public var number: EthereumQuantity
    public var stateRoot: EthereumData
    public var extrinsicsRoot: EthereumData
    public var digest: Log
}

public struct Log: Codable {
    public var logs: [EthereumData]
}



extension Api {
    public func chainGetBlock(hash: EthereumData) async throws -> Block {
        let params = JSONRpcRequset(method: RpcMethod.ChainGetBlock, params: [hash.hex()])

        let req = AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)


        let res = await req.serializingDecodable(ChainGetBlockResponse.self).result
        switch res {
        case .success(let r):
            if r.error != nil {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: r.error])
            }
            guard let block = r.result else {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: "invalid block"])
            }
            return block.block
        case .failure(let err):
            throw err
        }
    }
    
    public func chainGetBlockHash() async throws -> EthereumData {
        let params = JSONRpcRequset(id: 1, jsonrpc: "2.0", method: RpcMethod.ChainGetBlockHash, params: [])

        let req = AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)


        let res = await req.serializingDecodable(ChainBlockHashResponse.self).result
        switch res {
        case .success(let r):
            if r.error != nil {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: r.error])
            }
            guard let hash = r.result else {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: "invalid blockhash"])
            }
            return hash
        case .failure(let err):
            throw err
        }

    }
    
    public func chainGetFinalizedHead() async throws -> EthereumData {
        let params = JSONRpcRequset(id: 1, jsonrpc: "2.0", method: RpcMethod.ChainGetFinalizedHead, params: [])

        let req = AF.request(url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)


        let res = await req.serializingDecodable(ChainBlockHashResponse.self).result
        switch res {
        case .success(let r):
            if r.error != nil {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: r.error])
            }
           
            guard let hash = r.result else {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: "invalid blockhash"])
            }
            return hash
        case .failure(let err):
            throw err
        }

    }
}
