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
    
    public func toU8a() throws -> [UInt8] {
        let amountU8a = try compactToU8a(args.value.quantity)
        // Pre-allocate array with exact size
        var u8a = [UInt8](repeating: 0, count: 2 + 20 + amountU8a.count)
        
        // Copy each part to the pre-allocated array
        u8a.replaceSubrange(0..<2, with: callIndex)
        u8a.replaceSubrange(2..<22, with: args.dest.rawAddress)
        u8a.replaceSubrange(22..<(22 + amountU8a.count), with: amountU8a)
        
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
