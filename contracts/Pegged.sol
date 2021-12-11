// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PeggedERC20.sol";

struct Option{
    PeggedERC20 peg;
    PeggedERC20 nopeg;
    address oracle;
    uint32 expiry;
    uint16 fee; //0-1000 basis points

}

contract Pegged is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public creator; //address that can create insurance
    address public immutable erc20Implementation;
    address public treasury;
    address public collateral;
    Option[] public options;

    modifier onlyTrusted(){
        require(msg.sender == owner() || msg.sender == creator, "!Trusted");
        _;
    }

    constructor (
        address _erc20Implementation,
        address _creator,
        address _treasury,
        address _collateral
        ) public Ownable(){
        erc20Implementation = _erc20Implementation;
        creator = _creator;
        treasury = _treasury;
        collateral = _collateral;
    }

    function newOption(address pool, address want, uint32 _expiry, uint16 _fee, address _oracle) public onlyTrusted returns(uint256 id){
        PeggedERC20 yes = new PeggedERC20("KEEPPEG", "", pool, want);
        PeggedERC20 no = new PeggedERC20("LOSEPEG", "", pool, want);

        options.push(Option(
            {
                peg: yes,
                nopeg: no,
                oracle: _oracle,
                expiry: _expiry,
                fee: _fee
            }
        ));
        return options.length -1;
    }

    function mint(uint256 id, uint256 amount) public {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        require(id < options.length, "Invalid ID");
        Option memory op = options[id];
        op.peg.mint(msg.sender, amount);
        op.nopeg.mint(msg.sender, amount);
    }

    

}