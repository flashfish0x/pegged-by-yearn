// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/Chainlink/AggregatorV3Interface.sol";

import "./PeggedERC20.sol";

 enum Settlement{ NOTSETTLED, PEGGED, UNPEGGED }

struct Option{
    PeggedERC20 peg;
    PeggedERC20 nopeg;
    address oracle;
    uint32 expiry;
    uint16 fee; //0-1000 basis points
    Settlement settlementStatus;
    uint256 unpeggedPrice;

}

contract Pegged is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public creator; //address that can create insurance
    address public treasury;
    address public collateral;
    Option[] public options;

    modifier onlyTrusted(){
        require(msg.sender == owner() || msg.sender == creator, "!Trusted");
        _;
    }

    constructor (
        address _creator,
        address _treasury,
        address _collateral
        ) public Ownable(){
        creator = _creator;
        treasury = _treasury;
        collateral = _collateral;
    }

    // A new option is created by the controllers on the protocol. Either creator or owner. 
    // Specify the base asset, the expiry in unix time, the fee on settlement, the oracle, and the price at which we consider peg broken
    function newOption(address want, uint32 _expiry, uint16 _fee, address _oracle, uint256 _unpeggedPrice) public onlyTrusted returns(uint256 id){
        require(_expiry > now, "Already Expired");

        //todo add to name the details and expiry
        PeggedERC20 yes = new PeggedERC20("KEEPPEG", "KEEPPEG", want, options.length);
        PeggedERC20 no = new PeggedERC20("LOSEPEG", "LOSEPEG", want, options.length);

        options.push(Option(
            {
                peg: yes,
                nopeg: no,
                oracle: _oracle,
                expiry: _expiry,
                fee: _fee,
                settlementStatus: Settlement.NOTSETTLED,
                unpeggedPrice: _unpeggedPrice
            }
        ));
        return options.length -1;
    }

    //we can mint and burn at any time provided we have the correct balance 
    function mint(uint256 id, uint256 amount) public {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        require(id < options.length, "Invalid ID");
        Option memory op = options[id];
        op.peg.mint(msg.sender, amount);
        op.nopeg.mint(msg.sender, amount);
    }

    function burn(uint256 id, uint256 amount) public {
        require(id < options.length, "Invalid ID");
        Option memory op = options[id];
        op.peg.burn(msg.sender, amount);
        op.nopeg.burn(msg.sender, amount);
        IERC20(collateral).safeTransfer(msg.sender, amount);
    }

    // we can settle early if the peg is broken. or after expiry if the peg is still strong
    function settle(uint256 id) public returns (Settlement){
        require(id < options.length, "Invalid ID");
        Option storage op = options[id]; //must be storage
        require(op.settlementStatus == Settlement.NOTSETTLED, "AlreadySettled");
        if(isUnPegged(id)){
            op.settlementStatus = Settlement.UNPEGGED;
            
        }else if(op.expiry < now){
            op.settlementStatus = Settlement.PEGGED;
        }

        return op.settlementStatus;        
    }

    //function for collecting payout. if the market is settled then burn the tokens related to the settlement
    function collect(uint256 id) public returns (uint256 amount){
        require(id < options.length, "Invalid ID");
        Option memory op = options[id];
        require(op.settlementStatus != Settlement.NOTSETTLED, "NotSettled");
        uint256 amount;
        if(op.settlementStatus == Settlement.PEGGED){
            amount = op.peg.balanceOf(msg.sender);
            if(amount > 0){
                op.peg.burn(msg.sender, amount);
            }
        }else{
            amount = op.nopeg.balanceOf(msg.sender);
            if(amount > 0){
                op.nopeg.burn(msg.sender, amount);
            }
        }

        if(amount > 0){
            //calculate fee
            uint256 fee = amount.mul(op.fee).div(1000);
            IERC20(collateral).safeTransfer(treasury, fee);
            IERC20(collateral).safeTransfer(msg.sender, amount.sub(fee));
        }

    }


    // check oracle and curve pool balance
    function isUnPegged(uint256 id) public view returns (bool){
        return AggregatorV3Interface(options[id].oracle).latestAnswer() < options[id].unpeggedPrice;
    }

    

}