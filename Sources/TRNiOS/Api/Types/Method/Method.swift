
import Foundation
import BigInt
import Web3

public protocol Method {
    var callIndex: [UInt8] { get }
    func toU8a() throws -> [UInt8]
}

public struct MethodFeeProxy: Method {
    public let callIndex: [UInt8] = Data(hex: "1f00").bytes
    public var args: FeeProxyArgs

    public init(args: FeeProxyArgs) {
        self.args = args
    }
    
    public func toU8a() throws -> [UInt8] {
        var u8a = callIndex
        u8a.append(contentsOf: bnToU8a(bn: args.paymentAsset, bitLength: 32))
        u8a.append(contentsOf: bnToU8a(bn: args.maxPayment, bitLength: 128))
        u8a.append(contentsOf: try args.call.toU8a())
        return u8a
    }
}

public struct FeeProxyArgs {
    public let paymentAsset: BigUInt
    public var maxPayment: BigUInt
    public let call: Method
    
    public init(paymentAsset: BigUInt, maxPayment: BigUInt, call: Method) {
        self.paymentAsset = paymentAsset
        self.maxPayment = maxPayment
        self.call = call
    }
}
