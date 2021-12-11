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

    #we create a new option on mim losing the peg and hitting a price of 0.8 on chainlink by 1 jan 2022
    #only creator or owner can create a new option. it can be on any chainlink oracled asset losing peg
    pegged.newOption(mim, expiry, 1, mim_oracle, unpegged_price, {"from": creator})

    peg_details = pegged.options(0)
    print(peg_details)

    #there is two erc20s. One for peg and one for unpeg
    peg = PeggedERC20.at(peg_details[0])
    unpeg = PeggedERC20.at(peg_details[1])

    #this is the first option created so marketId is 0
    assert peg.marketId() == 0
    #no peg tokens have been minted yet
    assert peg.totalSupply() == 0
    
    #as price is above $0.8 mim is not unpegged
    assert pegged.isUnPegged(0) == False

    #our whale decides to mint dai into equal parts peg and nopeg
    dai.approve(pegged, 2**256-1, {'from': whale})
    amount = 10_000 * 1e18
    dai_before = dai.balanceOf(whale)
    pegged.mint(0, amount, {'from': whale})

    assert dai_before -dai.balanceOf(whale) == amount
    assert peg.balanceOf(whale) == amount
    assert unpeg.balanceOf(whale) == amount

    #the whale can also burn equal parts peg and unpeg for dai back
    pegged.burn(0, amount/2, {"from": whale})
    assert peg.balanceOf(whale) == amount / 2
    assert unpeg.balanceOf(whale) == amount / 2
    assert dai_before -dai.balanceOf(whale) == amount / 2 

    #if we try and collect before the market is settled we get a revert
    with brownie.reverts("NotSettled"):
        pegged.collect(0, {"from": whale})

    #now we sleep until after expiry
    chain.sleep(2*30*12*60*60)
    chain.mine(1)
    #at this point we can settle the market and collect out peg winnings
    pegged.settle(0, {"from": whale})
    pegged.collect(0, {"from": whale})

    #our peg erc20 has now been burnt for dai and the unpeg stays in balance as it is now worthless
    assert peg.balanceOf(whale) == 0
    assert unpeg.balanceOf(whale) == amount / 2

    #the whale has slightly less dai than before because some fee went to treasury
    assert dai_before > dai.balanceOf(whale)
    assert dai_before == dai.balanceOf(whale) + dai.balanceOf(creator)

    #now we mint one that is already broken peg to show it works
    unpegged_price = 1.2*1e8
    expiry = 1672531200 #1 jan 2023
    pegged.newOption(mim, expiry, 1, mim_oracle, unpegged_price, {"from": creator})
    peg_details = pegged.options(1)
    peg = PeggedERC20.at(peg_details[0])
    unpeg = PeggedERC20.at(peg_details[1])

    #this is the second option created so marketId is 1
    assert peg.marketId() == 1
    amount = 10_000 * 1e18
    dai_before = dai.balanceOf(whale)
    treasury_before = dai.balanceOf(creator)
    pegged.mint(1, amount, {'from': whale})

    #as price is below $1.2 mim is unpegged
    assert pegged.isUnPegged(1) == True

    assert dai_before -dai.balanceOf(whale) == amount
    assert peg.balanceOf(whale) == amount
    assert unpeg.balanceOf(whale) == amount

    pegged.settle(1, {"from": whale})
    pegged.collect(1, {"from": whale})

    #this time unpeg balance should be 0
    assert peg.balanceOf(whale) == amount
    assert unpeg.balanceOf(whale) == 0

    #the whale has slightly less dai than before because some fee went to treasury
    assert dai_before > dai.balanceOf(whale)
    assert dai_before == dai.balanceOf(whale) + dai.balanceOf(creator) - treasury_before

    
