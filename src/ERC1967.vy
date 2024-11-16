"""
@ pragma version 0.4.0
@ title ERC1967 Proxy Contract
@ author Your Name
@ notice This contract implements an upgradeable proxy following EIP-1967
"""
# EIP-1967 storage slots
IMPLEMENTATION_SLOT: constant(bytes32) = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
ADMIN_SLOT: constant(bytes32) = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
BEACON_SLOT: constant(bytes32) = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50

# Events
event Upgraded:
    implementation: indexed(address)

event AdminChanged:
    previousAdmin: address
    newAdmin: address

@deploy
@payable
def __init__(implementation: address, admin: address, setup_data: Bytes[max_value(uint16)]):
    """
    @notice Initializes the proxy with an implementation and optional setup data
    @param implementation The initial implementation address
    @param admin The initial admin address
    @param setup_data The initialization data to be delegated to the implementation
    """
    self._set_implementation(implementation)
    self._set_admin(admin)
    
    # If there's setup data, delegate call to implementation
    if len(setup_data) > 0:
        success: bool = raw_call(
            implementation,
            setup_data,
            max_outsize=0,
            value=msg.value,
            is_delegate_call=True,
        )
        assert success, "Initialization failed"

@external
@payable
def __default__():
    """
    @notice Fallback function that delegates all calls to the implementation
    """
    implementation: address = self._get_implementation()
    assert implementation != empty(address), "Implementation not set"

    # Delegate call to the implementation
    raw_call(
        implementation,
        msg.data,
        max_outsize=max_value(uint16),
        value=msg.value,
        is_delegate_call=True,
        revert_on_failure=True
    )

@external
def upgrade_to(new_implementation: address):
    """
    @notice Upgrades the implementation to a new address
    @param new_implementation The new implementation address
    """
    assert msg.sender == self._get_admin(), "Only admin"
    self._set_implementation(new_implementation)
    log Upgraded(new_implementation)

@external
def upgrade_to_and_call(new_implementation: address, data: Bytes[max_value(uint16)], value: uint256 = 0):
    """
    @notice Upgrades the implementation and calls it with setup data
    @param new_implementation The new implementation address
    @param data The setup data to be passed to the new implementation
    @param value The value to be passed with the call
    """
    assert msg.sender == self._get_admin(), "Only admin"
    self._set_implementation(new_implementation)
    log Upgraded(new_implementation)
    
    if len(data) > 0:
        success: bool = raw_call(
            new_implementation,
            data,
            max_outsize=0,
            value=value,
            is_delegate_call=True
        )
        assert success, "Setup call failed"

@external
def change_admin(new_admin: address):
    """
    @notice Changes the admin address
    @param new_admin The new admin address
    """
    assert msg.sender == self._get_admin(), "Only admin"
    assert new_admin != empty(address), "New admin is zero address"
    old_admin: address = self._get_admin()
    self._set_admin(new_admin)
    log AdminChanged(old_admin, new_admin)

### Internal functions ###

@internal
@view
def _get_implementation() -> address:
    """
    @notice Gets the current implementation address from the storage slot
    """
    return self._get_address_slot(IMPLEMENTATION_SLOT)

@internal
def _set_implementation(new_implementation: address):
    """
    @notice Sets a new implementation address
    """
    assert new_implementation.is_contract, "New implementation is not a contract"
    self._set_address_slot(IMPLEMENTATION_SLOT, new_implementation)

@internal
@view
def _get_admin() -> address:
    """
    @notice Gets the current admin address from the storage slot
    """
    return self._get_address_slot(ADMIN_SLOT)

@internal
def _set_admin(new_admin: address):
    """
    @notice Sets a new admin address
    """
    self._set_address_slot(ADMIN_SLOT, new_admin)

@internal
@pure
def _get_address_slot(slot: bytes32) -> address:
    """
    @notice Helper to read an address from a storage slot
    """
    value: address = empty(address)
    raw_slot: bytes32 = slot
    assembly:
        value := sload(raw_slot)
    return value

@internal
@pure
def _set_address_slot(slot: bytes32, value: address):
    """
    @notice Helper to write an address to a storage slot
    """
    raw_slot: bytes32 = slot
    assembly:
        sstore(raw_slot, value)