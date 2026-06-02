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
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public nonces;

    // ─── constructor ──────────────────────────────────────────────────────────

    /// @param initialRecipient Receives the full fixed supply at deploy time.
    constructor(address initialRecipient) {
        if (initialRecipient == address(0)) revert SPTU_ZeroAddress();

        _initialChainId = block.chainid;
        _initialDomainSeparator = _buildDomainSeparator(block.chainid);

        _mint(initialRecipient, MAX_SUPPLY);
    }

    // ─── views ────────────────────────────────────────────────────────────────

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (block.chainid == _initialChainId) return _initialDomainSeparator;
        return _buildDomainSeparator(block.chainid);
    }

    // ─── ERC20 core ───────────────────────────────────────────────────────────

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        if (allowed != type(uint256).max) {
            if (allowed < amount) revert SPTU_InsufficientAllowance();
            unchecked {
                _allowances[from][msg.sender] = allowed - amount;
            }
            emit Approval(from, msg.sender, _allowances[from][msg.sender]);
        }

        _transfer(from, to, amount);
        return true;
    }

    // ─── permit (EIP-2612) ────────────────────────────────────────────────────

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (owner == address(0) || spender == address(0)) revert SPTU_ZeroAddress();
        if (block.timestamp > deadline) revert SPTU_Expired();

        uint256 nonce = nonces[owner];

        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TYPEHASH,
            owner,
