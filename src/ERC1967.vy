# pragma version 0.4.1
"""
@title ERC1967 Proxy Contract
@author Your Name
@notice This contract implements an upgradeable proxy following EIP-1967
"""
# EIP-1967 storage slots
_gap_0: uint256[24440054405305269366569402256811496959409073762505157381672968839269610695612]
implementation: public(address)# @ 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
_gap_1: uint256[57515418674210777583064340759886350581885744927316125368323712657003024561478]
admin: public(address)# @ 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103

# Events
event Upgraded:
    implementation: indexed(address)

event AdminChanged:
    previousAdmin: address
    newAdmin: address

@deploy
@payable
def __init__(implementation: address, admin: address):
    """
    @notice Initializes the proxy with an implementation and optional setup data
    @param implementation The initial implementation address
    @param admin The initial admin address
    """
    self.implementation = implementation
    self.admin = admin

@external
def __default__() -> uint256:
    """
    @notice Fallback function that delegates all calls to the implementation
    """
    assert self.implementation != empty(address), "Implementation not set"

    # Delegate call to the implementation
    result: uint256 = convert(raw_call(
        self.implementation,
        msg.data,
        max_outsize=32,
        is_delegate_call=True,
        revert_on_failure=True
    ), uint256)
    return result

@external
def upgrade_to(new_implementation: address):
    """
    @notice Upgrades the implementation to a new address
    @param new_implementation The new implementation address
    """
    assert msg.sender == self.admin, "Only admin"
    self.implementation = new_implementation
    log Upgraded(new_implementation)

@external
def change_admin(new_admin: address):
    """
    @notice Changes the admin address
    @param new_admin The new admin address
    """
    assert msg.sender == self.admin, "Only admin"
    assert new_admin != empty(address), "New admin is zero address"
    old_admin: address = self.admin
    self.admin = new_admin
    log AdminChanged(old_admin, new_admin)
