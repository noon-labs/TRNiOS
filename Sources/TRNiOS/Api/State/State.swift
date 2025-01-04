import Foundation
import Web3
import Alamofire
import BigInt

public struct StateGetRuntimeVersionResponse: JSONRpcResponse, Codable {
    public var id: UInt16?
    public var jsonrpc: String?
    public var error: JsonRpcError?
    public var result: RuntimeVersion?
}

public struct RuntimeVersion: Codable {
    public var specName: String
    public var implName: String
    public var authoringVersion: UInt64
    public var specVersion: UInt64
    public var implVersion: UInt64
    public var apis: [[EthereumData: UInt64]]
    public var transactionVersion: UInt64
    public var stateVersion: UInt64
}

public struct StateCallResponse: JSONRpcResponse, Codable {
    public var id: UInt16?
    public var jsonrpc: String?
    public var error: JsonRpcError?
    public var result: EthereumData?
}

public struct Weight {
    public var refTime: BigUInt
    public var proofSize: BigUInt
}

public struct RuntimeDispatchInfo {
    public var weight: Weight
    public var `class`: Int
    public var partialFee: BigUInt
    
    init(src: Data) throws {
        let data = src.bytes
        let (offset1, refTime) = decodeCompact(u8a: data)
        let (offset2, proofSize) = decodeCompact(u8a: Array(data[offset1..<data.count]))
        let classValue = Int(data[offset1 + offset2])
        let a: [UInt8] = data[offset1 + offset2 + 1..<data.count].reversed()
        let partialFee = BigUInt(a)

        self.weight = Weight(refTime: refTime, proofSize: proofSize)
        self.class = classValue
        self.partialFee = partialFee
    }
}

public enum StateCallQuery: String, Codable {
    case TransactionPaymentApiQueryInfo = "TransactionPaymentApi_query_info"
}

extension Api {
    public func stateGetRuntimeVersion(hash: EthereumData) async throws -> RuntimeVersion {
        let params = JSONRpcRequset(method: RpcMethod.StateGetRuntimeVersion, params: [hash.hex()])
        
        let req = AF.request(self.url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
        
        
        let res = await req.serializingDecodable(StateGetRuntimeVersionResponse.self).result
        switch res {
        case .success(let r):
            if r.error != nil {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: r.error])
            }
            guard let runtimeVersion = r.result else {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error StateGetRuntimeVersion"])
            }
            return runtimeVersion
        case .failure(let err):
            throw err
        }
    }
    
    public func stateCallTransactionPayment(extrinsic: SubmittableExtrinsic) async throws -> RuntimeDispatchInfo {
        let extrinsicU8a = try extrinsic.toU8a()
        let extrinsicSizeU8a = bnToU8a(bn: BigUInt(extrinsicU8a.count), bitLength: 32)
        let encodedParam = u8aConcatStrict(u8as: [extrinsicU8a, extrinsicSizeU8a])
        let queryParams = [StateCallQuery.TransactionPaymentApiQueryInfo.rawValue, encodedParam.toHexString()]
        
        let params = JSONRpcRequset(method: RpcMethod.StateCall, params: queryParams)
        
        let req = AF.request(self.url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
        
        let res = await req.serializingDecodable(StateCallResponse.self).result
        switch res {
        case .success(let r):
            if r.error != nil {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: r.error])
            }
            guard let encodedDispatchInfo = r.result else {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: "invalid runtime dispatch info"])
            }
            
            return try RuntimeDispatchInfo(src: Data(encodedDispatchInfo.makeBytes()))
        case .failure(let err):
            throw err
        }
    }
}
