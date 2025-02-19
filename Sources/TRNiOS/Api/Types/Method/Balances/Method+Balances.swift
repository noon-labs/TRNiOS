//
//  Method+Balances.swift
//  TRNiOS
//
//  Created by 한상범 on 2/19/25.
//

import Foundation
import BigInt
import Web3

/// For transferring ROOT
public struct MethodBalancesTransfer: Method {
    public let callIndex: [UInt8] = Data(hex: "0507").bytes
    public var args: BalancesTransferArgs
    
    public init(args: BalancesTransferArgs) {
        self.args = args
    }
    
    public func toU8a() -> [UInt8] {
        var u8a = callIndex
        u8a += args.dest.rawAddress
        u8a += bnToU8a(bn: args.value.quantity, bitLength: 128)
        
        return u8a
    }
}

public struct BalancesTransferArgs {
    public let dest: EthereumAddress
    public let value: EthereumQuantity
    
    public init(dest: EthereumAddress,
                value: EthereumQuantity) {
        self.dest = dest
        self.value = value
    }
}
