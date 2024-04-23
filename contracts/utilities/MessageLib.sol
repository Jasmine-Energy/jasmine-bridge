// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

library MessageLib {
    enum MessageType {
        Debit,
        Credit,
        Retire,
        Withdraw
    }

    struct BridgeMessage {
        MessageType messageType;
        
    }
}
