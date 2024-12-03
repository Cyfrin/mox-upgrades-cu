# SPDX-License-Identifier: MIT
# pragma version 0.4.0

number: public(uint256)

@external
def set_number(new_number: uint256):
    self.number = new_number

@external
def increment():
    self.number += 2

@external 
def decrement():
    self.number -= 1

@external
def version() -> uint256:
    return 2