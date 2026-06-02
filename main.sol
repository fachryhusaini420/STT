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

