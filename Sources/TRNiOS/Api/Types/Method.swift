
import Foundation
import BigInt
import Web3

public protocol Method {
    var callIndex: [UInt8] { get }
    func toU8a() -> [UInt8]
}

public struct MethodWithdrawXrp: Method {
    public let callIndex: [UInt8] = Data(hex: "1203").bytes
    public var args: WithdrawXrpArgs

    public func toU8a() -> [UInt8] {
        var u8a = callIndex
        u8a += bnToU8a(bn: args.amount.quantity, bitLength: 128)
        u8a += args.destination.rawAddress
        return u8a
    }
}

public struct WithdrawXrpArgs {
    public let amount: EthereumQuantity
    public let destination: EthereumAddress
}

public struct MethodFeeProxy: Method {
    public let callIndex: [UInt8] = Data(hex: "1f00").bytes
    public var args: FeeProxyArgs

    public func toU8a() -> [UInt8] {
        var u8a = callIndex
        u8a.append(contentsOf: bnToU8a(bn: args.paymentAsset, bitLength: 32))
        u8a.append(contentsOf: bnToU8a(bn: args.maxPayment, bitLength: 128))
        u8a.append(contentsOf: args.call.toU8a())
        return u8a
    }
}

public struct FeeProxyArgs {
    public let paymentAsset: BigUInt
    public var maxPayment: BigUInt
    public let call: MethodWithdrawXrp
}
