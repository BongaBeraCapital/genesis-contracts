priv_key="e14da3742ff4ea474ff2ccab2c0d1587a0b57d520c1e9feaec7be5209ed4a337"

import pytest
from brownie import network, BeraTemplate, accounts, exceptions





def main():
    account = accounts.add(private_key=priv_key)
    bt = BeraTemplate.deploy({"from": account})
    return bt.address