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
    public let callIndex: [UInt8] = Data(hex: "0608").bytes
    public var args: AssetsTransferArgs
    
    public init(args: AssetsTransferArgs) {
        self.args = args
    }
    
    public func toU8a() throws -> [UInt8] {
        var u8a = callIndex
        u8a += try compactToU8a(args.id.quantity)
        u8a += args.target.rawAddress
        u8a += try compactToU8a(args.amount.quantity)
        
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
