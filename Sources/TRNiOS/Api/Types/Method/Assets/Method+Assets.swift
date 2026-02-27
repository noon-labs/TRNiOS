//
//  Method+Assets.swift
//  TRNiOS
//
//  Created by 한상범 on 2/19/25.
//

import Foundation
import BigInt
import Web3

/// For transferring tokens (XRP supported, ROOT not supported)
public struct MethodAssetsTransfer: Method {
    public let callIndex: [UInt8] = [UInt8](Data(hex: "0608"))
    public var args: AssetsTransferArgs
    
    public init(args: AssetsTransferArgs) {
        self.args = args
    }
    
    public func toU8a() throws -> [UInt8] {
        // Get compact encoded amount first to know final size
        let amountU8a = try compactToU8a(args.amount.quantity)
        
        // Pre-allocate array with exact size (2 + 4 + 20 + amountSize)
        var u8a = [UInt8](repeating: 0, count: 26 + amountU8a.count)
        
        // Copy each part to pre-allocated array
        // callIndex (2 bytes)
        u8a.replaceSubrange(0..<2, with: callIndex)
        
        // assetId (4 bytes) - using u32ToU8a instead of compact encoding
        u8a.replaceSubrange(2..<6, with: bnToU8a(bn: args.id.quantity, bitLength: 32))
        
        // target address (20 bytes)
        u8a.replaceSubrange(6..<26, with: args.target.rawAddress)
        
        // amount (variable size)
        u8a.replaceSubrange(26..<(26 + amountU8a.count), with: amountU8a)
        
        return u8a
    }
}

public struct AssetsTransferArgs {
    public let id: EthereumQuantity
    public let target: EthereumAddress
    public let amount: EthereumQuantity
    
    public init(id: EthereumQuantity,
                target: EthereumAddress,
                amount: EthereumQuantity) {
        self.id = id
        self.target = target
        self.amount = amount
    }
}
