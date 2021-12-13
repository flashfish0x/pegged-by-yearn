// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Two Erc20 - yes and no peg
contract PeggedERC20 is ERC20, Ownable{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address immutable public want;
    uint256 immutable public marketId;

    constructor (string memory name, string memory symbol, address _want, uint256 _marketId) public ERC20(name, symbol) Ownable(){
        want = _want;
        marketId = _marketId;
    }

    function mint(address _address, uint256 _amount) public onlyOwner{
        _mint(_address, _amount);
    }

    function burn(address _address, uint256 _amount) public onlyOwner{
        _burn(_address, _amount);
    }

}