// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PeggedERC20 is ERC20, Ownable{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address immutable pool;
    address immutable want;

    constructor (string memory name, string memory symbol, address _pool, address _want) public ERC20(name, symbol) Ownable(){
        pool = _pool;
        want = _want;

    }

    function mint(address _address, uint256 _amount) public onlyOwner{
        _mint(_address, _amount);
    }

}