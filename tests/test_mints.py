from itertools import count
from brownie import Wei, reverts
import brownie

def test_option(web3, dai,mim, whale, chain, interface, accounts, mim_oracle, Pegged, PeggedERC20):
    creator = accounts[0]
    pegged = creator.deploy(Pegged, creator, creator, dai)

    with brownie.reverts("Invalid ID"):
        pegged.settle(0, {"from": creator})

    print("creating new option")
    unpegged_price = 0.8*1e8
    expiry = 1640995200 #1 jan 2022
    pegged.newOption(dai, expiry, 1, mim_oracle, unpegged_price, {"from": creator})

    peg_details = pegged.options(0)
    print(peg_details)
    peg = PeggedERC20.at(peg_details[0])
    unpeg = PeggedERC20.at(peg_details[1])
    
    
    assert pegged.isUnPegged(0) == False

    dai.approve(pegged, 2**256-1, {'from': whale})
    amount = 10_000 * 1e18
    dai_before = dai.balanceOf(whale)
    pegged.mint(0, amount, {'from': whale})

    assert dai_before -dai.balanceOf(whale) == amount

    assert peg.balanceOf(whale) == amount
    assert unpeg.balanceOf(whale) == amount

    with brownie.reverts("NotSettled"):
        pegged.collect(0, {"from": whale})

    chain.sleep(2*30*12*60*60)
    chain.mine(1)
    pegged.settle(0, {"from": whale})
    pegged.collect(0, {"from": whale})

    assert peg.balanceOf(whale) == 0
    assert unpeg.balanceOf(whale) == amount 
    assert dai_before == dai.balanceOf(whale)