// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23;

struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
    bool allowed;
}

library SigUtils {
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // computes the hash of a permit
    function getStructHash(Permit memory _permit, bytes32 permitTypeHash) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(permitTypeHash, _permit.owner, _permit.spender, _permit.value, _permit.nonce, _permit.deadline)
        );
    }

    function getDaiStructHash(Permit memory _permit, bytes32 permitTypeHash) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(permitTypeHash, _permit.owner, _permit.spender, _permit.nonce, _permit.deadline, _permit.allowed)
        );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory _permit, bytes32 domainSeparator) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, getStructHash(_permit, PERMIT_TYPEHASH)));
    }

    function getTypedDaiDataHashWithPermitTypeHash(
        Permit memory _permit,
        bytes32 domainSeparator,
        bytes32 permitTypeHash
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, getDaiStructHash(_permit, permitTypeHash)));
    }
}
