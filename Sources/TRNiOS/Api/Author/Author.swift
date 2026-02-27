import Foundation
import Web3
import Alamofire
import Blake2

struct AuthorSubmitExtrinsicResponse: JSONRpcResponse, Codable {
    var id: UInt16?
    var jsonrpc: String?
    var error: JsonRpcError?
    var result: EthereumData?
}

public struct AuthorSubmitExtrinsicResult {
    public let hash: EthereumData
    public let id: String
}

extension Api {
    public func authorSubmitExtrinsic(encodedData: String) async throws -> EthereumData {
        let params = JSONRpcRequset(method: RpcMethod.AuthorSubmitExtrinsic, params: [encodedData])
        
        let req = AF.request(self.url, method: .post, parameters: params, encoder: JSONParameterEncoder.default)
        
        let res = await req.serializingDecodable(AuthorSubmitExtrinsicResponse.self).result
        switch res {
        case .success(let r):
            if let error = r.error {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: error])
            }
            guard let hash = r.result else {
                throw NSError(domain: "api", code: 0, userInfo: [NSLocalizedDescriptionKey: "invalid extrinsic"])
            }
            return hash
        case .failure(let err):
            throw err
        }
    }
    
    /// Extrinsic을 제출하고 ID와 같이 반환
    public func authorSubmitExtrinsicAndGetId(
        encodedData: String,
        maxSearchBlocks: Int = 20,
        maxWaitTime: TimeInterval = 60
    ) async throws -> AuthorSubmitExtrinsicResult {
        // 1. Extrinsic 제출
        let hash = try await authorSubmitExtrinsic(encodedData: encodedData)

        // 2. 블록에 포함될 때까지 대기 및 검색
        do {
            let id = try await findExtrinsicId(hash: hash,
                                               maxSearchBlocks: maxSearchBlocks,
                                               maxWaitTime: maxWaitTime)
            
            return AuthorSubmitExtrinsicResult(hash: hash, id: id)
        } catch {
            return AuthorSubmitExtrinsicResult(hash: hash, id: "")
        }
    }

    /// Extrinsic hash로부터 Substrate 표준 형식의 ID를 Finalized 블록을 주기적으로 체크하여 찾는다
    private func findExtrinsicId(
        hash: EthereumData,
        maxSearchBlocks: Int,
        maxWaitTime: TimeInterval
    ) async throws -> String {
        let startTime = Date()
        var lastCheckedBlockNumber: UInt64 = 0
        while Date().timeIntervalSince(startTime) < maxWaitTime {
            // 최신 finalized 블록 가져오기
            let finalizedHash = try await chainGetFinalizedHead()
            let finalizedBlock = try await chainGetBlock(hash: finalizedHash)
            let finalizedBlockNumber = try UInt64(finalizedBlock.header.number.quantity)
            // 새로운 finalized 블록이 있는지 확인
            if finalizedBlockNumber > lastCheckedBlockNumber {
                var currentBlockHash = finalizedHash
                var currentBlock = finalizedBlock
                var searchedBlocks = 0

                while searchedBlocks < maxSearchBlocks {
                    let currentBlockNumber = try UInt64(currentBlock.header.number.quantity)
                    // 현재 블록의 extrinsics에서 hash 찾기
                    for (idx, extrinsic) in currentBlock.extrinsics.enumerated() {
                        let extrinsicHash = try Blake2b.hash(size: 32, data: extrinsic.bytes)
                        let extrinsicHashData = try EthereumData(extrinsicHash)
                        if extrinsicHashData.hex() == hash.hex() {
                            let blockNumber = try UInt64(currentBlock.header.number.quantity)
                            return "\(blockNumber)-\(idx)"
                        }
                    }
                    // 이전 블록으로 이동
                    currentBlockHash = currentBlock.header.parentHash
                    currentBlock = try await chainGetBlock(hash: currentBlockHash)
                    searchedBlocks += 1
                }

                lastCheckedBlockNumber = finalizedBlockNumber
            }
            // 새로운 finalized 블록이 나올 때까지 1초
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        return ""
    }
}

