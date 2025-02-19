//
//  Method+XrplBridge.swift
//  TRNiOS
//
//  Created by 한상범 on 2/19/25.
//

import Foundation
import BigInt
import Web3

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
