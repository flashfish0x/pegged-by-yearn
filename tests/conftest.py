import pytest
from brownie import Wei, config



@pytest.fixture
def mim_oracle(interface):
    yield interface.AggregatorV3Interface('0x7A364e8770418566e3eb2001A96116E6138Eb32F')

@pytest.fixture
def mim(interface):
    yield interface.ERC20('0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3')


@pytest.fixture
def whale(accounts,dai):
    #compounddai
    acc = accounts.at('0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643', force=True)

    assert dai.balanceOf(acc) > 0

    yield acc


@pytest.fixture
def dai(interface):
    yield interface.ERC20('0x6b175474e89094c44da98b954eedeac495271d0f')

@pytest.fixture
def usdc(interface):
    yield interface.ERC20('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48')