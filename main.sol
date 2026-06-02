// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SphereTrackUtilToken
/// @notice codename: signal shards / utility drift
/// @dev Fixed-supply ERC20 utility token with EIP-2612 permit.
///      No minting, no admin. Designed for mainnet deployment.

contract SphereTrackUtilToken {
    // ─── ERC20 errors ─────────────────────────────────────────────────────────

    error SPTU_InsufficientBalance();
    error SPTU_InsufficientAllowance();
    error SPTU_ZeroAddress();
    error SPTU_Expired();
    error SPTU_BadSig();
    error SPTU_BadNonce();

    // ─── ERC20 events ─────────────────────────────────────────────────────────

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ─── token metadata ───────────────────────────────────────────────────────

    string public constant name = "SphereTrack Utility";
    string public constant symbol = "SPTU";
    uint8 public constant decimals = 18;

    uint256 public constant MAX_SUPPLY = 500_000_000 * 10 ** uint256(decimals);

    // ─── EIP-2612 permit ──────────────────────────────────────────────────────

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant _EIP712_VERSION_HASH = keccak256("1");
    bytes32 private constant _EIP712_NAME_HASH = keccak256(bytes(name));

    uint256 private immutable _initialChainId;
    bytes32 private immutable _initialDomainSeparator;

    // ─── state ────────────────────────────────────────────────────────────────

    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
