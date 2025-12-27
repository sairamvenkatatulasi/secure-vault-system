// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuthorizationManager {
    mapping(bytes32 => bool) private usedAuthorizations;
    address private owner;

    event AuthorizationConsumed(bytes32 indexed authId, address indexed vault, address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes memory signature
    ) external returns (bool) {
        require(!usedAuthorizations[authId], "Authorization already used");
        
        bytes32 messageHash = keccak256(abi.encodePacked(
            vault,
            recipient,
            amount,
            authId,
            block.chainid
        ));
        
        bytes32 ethSignedHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        
        address recoveredAddress = recoverSigner(ethSignedHash, signature);
        require(recoveredAddress == owner, "Invalid authorization signature");
        
        usedAuthorizations[authId] = true;
        emit AuthorizationConsumed(authId, vault, recipient, amount);
        
        return true;
    }

    function recoverSigner(bytes32 hash, bytes memory signature) private pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        return ecrecover(hash, v, r, s);
    }

    function isAuthorizationUsed(bytes32 authId) external view returns (bool) {
        return usedAuthorizations[authId];
    }
}
