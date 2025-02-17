
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

    public init(args: WithdrawXrpArgs) {
        self.args = args
    }
    
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
    
    public init(amount: EthereumQuantity, destination: EthereumAddress) {
        self.amount = amount
        self.destination = destination
    }
}

public struct MethodWithdraw: Method {
    public let callIndex: [UInt8] = Data(hex: "120f").bytes
    public var args: WithdrawArgs
    
    public init(args: WithdrawArgs) {
        self.args = args
    }
    
    public func toU8a() -> [UInt8] {
        var u8a = callIndex
        u8a += bnToU8a(bn: args.assetId.quantity, bitLength: 32)  // asset_id is u32
        u8a += bnToU8a(bn: args.amount.quantity, bitLength: 128)
        u8a += args.destination.rawAddress
        
        // Handle optional destination tag
        if let destinationTag = args.destinationTag {
            u8a += [0x01] // Some variant for Option
            u8a += bnToU8a(bn: destinationTag.quantity, bitLength: 32)
        } else {
            u8a += [0x00] // None variant for Option
        }
        
        return u8a
    }
}

public struct WithdrawArgs {
    public let assetId: EthereumQuantity
    public let amount: EthereumQuantity
    public let destination: EthereumAddress
    public let destinationTag: EthereumQuantity?
    
    public init(assetId: EthereumQuantity,
                amount: EthereumQuantity,
                destination: EthereumAddress,
                destinationTag: EthereumQuantity? = nil) {
        self.assetId = assetId
        self.amount = amount
        self.destination = destination
        self.destinationTag = destinationTag
    }
}

public struct MethodFeeProxy: Method {
    public let callIndex: [UInt8] = Data(hex: "1f00").bytes
    public var args: FeeProxyArgs

    public init(args: FeeProxyArgs) {
        self.args = args
    }
    
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
    public let call: Method
    
    public init(paymentAsset: BigUInt, maxPayment: BigUInt, call: Method) {
        self.paymentAsset = paymentAsset
        self.maxPayment = maxPayment
        self.call = call
    }
}
