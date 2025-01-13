import XCTest
import Web3
@testable import TRNiOS

final class TestBridge: XCTestCase {
    func testBridge() async throws {
        // 0. initialized api
        let api = try Api(chain: .root)
        let senderPrivateKey = try EthereumPrivateKey(hexPrivateKey: "0xf2155a0a177e9675758cfba46780ec7bde93212e0947cefbcfd37ea2c85df2dc")
        
        // 1. initial bridge call method
        let destination = EthereumAddress(hexString: "0x335bff21a8531dc23fe854bc31ac600b05cfe290")!
        let amount = EthereumQuantity(quantity: BigUInt(100000))
        let method = MethodWithdrawXrp(args: WithdrawXrpArgs(amount: amount, destination: destination))
        
        
        // 2. create Extrinsic
        // 2.1 nonce
        let nonce = try await api.accountNextIndex(address: senderPrivateKey.address)
        
        // 2.2 era
        let blockHash = try await api.chainGetFinalizedHead()
        let block = try await api.chainGetBlock(hash: blockHash)
        let mortal = Mortal(current: try UInt64(block.header.number.quantity))
        
        let tip = EthereumQuantity(quantity: BigUInt.zero)
        var extrinsic = SubmittableExtrinsic(signature: Signature(era: mortal.toMortalEra(), nonce: try EthereumQuantity(nonce), tip: tip), method: method)
        
        // 3. get sign info
        let runtimeVersion = try await api.stateGetRuntimeVersion(hash: blockHash)
        
        // 4. sign
        try extrinsic.sign(privateKey: senderPrivateKey, runtimeVersion: runtimeVersion, genensisHash: api.genesisHash, blockHash: blockHash)
        
        // 5. broadcast
        let extrinsicHash = try await api.authorSubmitExtrinsic(encodedData: extrinsic.toHex())
        print("KUSH DONE?")
        print(extrinsicHash)
        XCTAssertEqual(extrinsicHash.bytes.count, 32)
    }
    
    func testBridgeWithFeeProxy() async throws {
        // 0. initialized api
        let api = try Api(chain: .root)
        let senderPrivateKey = try EthereumPrivateKey(hexPrivateKey: "0xf2155a0a177e9675758cfba46780ec7bde93212e0947cefbcfd37ea2c85df2dc")
        
        let url = getPublicProviderUrl(network: NetworkName.root)
        let provider = getWeb3Provider(url: url, networkName: NetworkName.root)
        let web3 = Web3(provider: provider)
        
        // 1. initial fee proxy bridge call method
        let destination = EthereumAddress(hexString: "0x335bff21a8531dc23fe854bc31ac600b05cfe290")!
        let amount = EthereumQuantity(quantity: BigUInt(100000))
        
        var method = MethodFeeProxy(
            args: FeeProxyArgs(
                paymentAsset: BigUInt(ROOT_ID),
                maxPayment: BigUInt.zero,
                call: MethodWithdrawXrp(
                    args: WithdrawXrpArgs(
                        amount: amount,
                        destination: destination
                    )
                )
            )
        )
        
        
        // 2. create Extrinsic
        // 2.1 nonce
        let nonce = try await api.accountNextIndex(address: senderPrivateKey.address)
        
        // 2.2 era
        let blockHash = try await api.chainGetFinalizedHead()
        let block = try await api.chainGetBlock(hash: blockHash)
        let mortal = Mortal(current: try UInt64(block.header.number.quantity))
        
        // 2.3 tip
        let tip = EthereumQuantity(quantity: BigUInt.zero)
        var extrinsic = SubmittableExtrinsic(
            signature: Signature(
                signer: senderPrivateKey.address,
                era: mortal.toMortalEra(),
                nonce: try EthereumQuantity(nonce),
                tip: tip
            ),
            method: method
        )
        
        // 3. fee calculate
        // 3.1 gas simulate
        let runtimeDispatchInfo = try await api.stateCallTransactionPayment(extrinsic: extrinsic)

        // 3.2 fee calculate XRP > TRN
        let maxPayment = try web3.eth.getAmountsIn(gasCostInXRP: Int(runtimeDispatchInfo.partialFee), feeAssetID: ROOT_ID).wait()
        method.args.maxPayment = BigUInt((Double(maxPayment) * 1.05).rounded(.toNearestOrAwayFromZero))
        extrinsic.method = method
        
        // 4. get sign info
        let runtimeVersion = try await api.stateGetRuntimeVersion(hash: blockHash)
        
        // 5. sign
        try extrinsic.sign(privateKey: senderPrivateKey, runtimeVersion: runtimeVersion, genensisHash: api.genesisHash, blockHash: blockHash)
        
        // 6. broadcast
        let extrinsicHash = try await api.authorSubmitExtrinsic(encodedData: extrinsic.toHex())
        print("KUSH DONE!?")
        print(extrinsicHash)
        XCTAssertEqual(extrinsicHash.bytes.count, 32)
    }
}
