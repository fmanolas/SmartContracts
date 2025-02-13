//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Consumer{
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function deposit() public payable {

    }
}


contract SmartWallet {

    address payable public  owner;

    mapping(address=>uint) public allowance;
    mapping(address=>bool) public isAllowedToSend;

    mapping(address=>bool) public guardians;
    address payable nextOwner;

    mapping(address=>mapping(address=>bool)) nextOwnerGuardianVoted;
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset=3;

    constructor(){
        owner=payable(msg.sender);
    }

    function setGuardian(address _guardian,bool _isGuardian) public {
        require(msg.sender==owner,"You are not the owner,aborting");
        guardians[_guardian]=_isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public{
        require(guardians[msg.sender],"You are not a guardian of this wallet,aborting");
        require(nextOwnerGuardianVoted[_newOwner][msg.sender]==false,"You have already voted!");
        if(_newOwner!=nextOwner){
            nextOwner=_newOwner;
            guardiansResetCount=0;
        }
        guardiansResetCount++;

        if(guardiansResetCount>=confirmationsFromGuardiansForReset){
            owner=_newOwner;
            nextOwner=payable(address(0));
        }
    }

    function setAllowance(address _for,uint256 _ammount) public {
        require(msg.sender==owner,"You are not the owner aborting");
        allowance[_for]=_ammount;
        if(_ammount>0){
            isAllowedToSend[_for]=true;
        }else{
            isAllowedToSend[_for]= false;
        }
    }

    function transfer(address payable _to,uint _ammount,bytes memory _payload) public returns(bytes memory){
        require(msg.sender==owner,"You are not the owner,aborting!");
        if(msg.sender==owner){
            require(allowance[msg.sender]>=_ammount,"Not enough balance");
            require(isAllowedToSend[msg.sender],"You are not allowed to send anything from this smart contract");

            allowance[msg.sender]-=_ammount;
        }
        (bool success,bytes memory returnData)=_to.call{value:_ammount}(_payload);
        require(success,"Call was not successful and as a result, aborting!");
        return returnData;
    }

    receive() external payable { }
}