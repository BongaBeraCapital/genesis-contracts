import pytest
from brownie import network, BeraTemplate, accounts, exceptions


class TestBeraTemplate():

    @pytest.fixture()
    def contract(self):
        if network.show_active() not in ["development", "dev"] or "fork" in network.show_active():
            pytest.skip("Only for local testing")
        output = BeraTemplate.deploy()
        return output

    def test_add(contract):
        assert 1 == 1