//
//  ContentView.swift
//  BitcoinSwift
//
//  Created by Enrique Souza Soares on 10/02/2024.
//

import SwiftUI
import HdWalletKit
import Foundation
import BitcoinCore
import HsCryptoKit

struct ContentView: View {
    
    func getSeed()->String{
        // let words = ["piece", "hunt", "scene", "agent", "subject", "clever", "expand", "maze", "drastic", "flash", "local", "usage"]
        
        let stringWords = "liquid brand gaze spare someone toe cause nuclear rug west wash mask"
        
        let words = stringWords.split(separator: " ").map { String($0)}
        
        guard let seed = Mnemonic.seed(mnemonic: words) else {
            print("==! Can't create Seed!")
            return ""
        }
        
        print("==> Seed: \(seed.hs.hex)")
        
        return seed.hs.hex
    }
    
    func getPrivateKey() throws -> HDPrivateKey? {
        let seedString = getSeed()
        
        guard let seedData = Data(hexString: seedString) else {
            print("Invalid seed hex string.")
            return nil
        }
        
        let hdWallet = HDWallet(seed: seedData, coinType: 0, xPrivKey: HDExtendedKeyVersion.xprv.rawValue)
        
        do {
            let privateKey = try hdWallet.privateKey(account: 0, index: 0, chain: .external)
            return privateKey
        } catch {
            print("Failed to derive private key:", error)
            throw error // or return nil if you prefer not to throw here
        }
    }
    
    func getPubKeyString () ->  String {
        
        do {
            if let privateKey = try getPrivateKey(){
                let pubKey = privateKey.publicKey().raw.hs.hexString
                return pubKey
            }
        } catch {
            print("cant get the private key")
        }
        
        return ""
    }
    
    func getPubKeyRaw () ->  Data {
        
        do {
            if let privateKey = try getPrivateKey(){
                let pubKey = privateKey.publicKey().raw
                return pubKey
            }
        } catch {
            print("cant get the private key")
        }
        return Data()
    }
    
    func getHdPubKey () ->  HDPublicKey? {
        
        do {
            if let privateKey = try getPrivateKey(){
                let pubKey = privateKey.publicKey()
                return pubKey
            }
        } catch {
            print("cant get the private key")
        }
        
        return nil
    }
    
    // Pay to Public Key Hash -> P2PKH
    func getAddress() -> String {
        
        // Example data - replace with actual values
        let rawPublicKeyData: Data = getPubKeyRaw ()/* Your raw public key data */
        let account: Int = 0 // The account number from the HD path
        let index: Int = 0 // The index number from the HD path
        let external: Bool = true // true if external (receiving), false if internal (change)

        do {
            let publicKey = try PublicKey(withAccount: account, index: index, external: external, hdPublicKeyData: rawPublicKeyData)
            let addressConverter = Base58AddressConverter(addressVersion: 0x00, addressScriptVersion: 0x05)
            
            let address = try addressConverter.convert(publicKey: publicKey, type: .p2pkh)
                
            print("Generated address with Base58AddressConverter: \(address.stringValue)")
        } catch {
            print("Failed to initialize PublicKey: \(error)")
        }
        
        let pubkey = getPubKeyString().replacingOccurrences(of: "0x", with: "")
        guard let publicKeyData = Data(hexString: pubkey) else {
            print("Invalid seed hex string. \(pubkey)")
            return ""
        }
    
        // 1. SHA-256 hashing
        // 2. RIPEMD-160 hashing
        let ripemd160Hash = Crypto.ripeMd160Sha256(publicKeyData)
        
        // 3. Adding network byte (0x00 for Bitcoin mainnet)
        let networkByte: Data = Data([0x00])
        let versionedPayload = networkByte + ripemd160Hash
        
        // 4. Double SHA-256 for checksum
        let checksum = Crypto.doubleSha256(versionedPayload).prefix(4)
        
        // 5. Concatenate versioned payload with checksum
        let finalPayload = versionedPayload + checksum
        
        // 6. Base58Check encoding
        let address = Base58.encode(finalPayload)
        
        print("Legacy Address (P2PKH) by hand (manual generation): \(address)")
        
        return address
    }
                
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("PubKey: " + getPubKeyString())
            Spacer()
            Text("BTC Address: " + getAddress())
            
        }
        .padding()
    }
}
extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}


#Preview {
    ContentView()
}
