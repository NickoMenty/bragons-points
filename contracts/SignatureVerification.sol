// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

error OnlyOwnerError();
error TaskNumberDoesNotExistError();
error UserAlreadyCompletedTaskError();
error InvalidSignatureError();
error SignatureAlreadyUsedError();
error RefereeIsUserError();

contract SignatureVerification is Ownable{

    address immutable private i_owner;
    uint256 public taskCount;
    mapping(uint256 => uint256) private taskToPrize;
    mapping(address => mapping(uint256 => bool)) private userTaskCompleted;
    mapping(bytes32 => bool) private usedSignatures;
    mapping(address => uint256) private userPrizeBalance;
    mapping(address => address) private userReferee;
    mapping(address => bool) private userSetReferee;

    constructor() {
        i_owner = msg.sender;
        taskCount = 0;
    }

    function addTask(uint256 _prize) public onlyOwner {
        taskCount++;
        taskToPrize[taskCount] = _prize;
    }

    function setPrizeForTask(uint256 _taskNumber, uint256 _prize) public onlyOwner {
        if (_taskNumber > taskCount) {
            revert TaskNumberDoesNotExistError();
        }
        taskToPrize[_taskNumber] = _prize;
    }

    function setReferee(address _referee) public {
        if (_referee == msg.sender) {
            revert RefereeIsUserError(); 
        }
        if (userSetReferee[msg.sender]) {
            revert RefereeIsUserError(); 
        }
        userReferee[msg.sender] = _referee;
        userSetReferee[msg.sender] = true;
    }

    function verifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s, uint256 _taskNumber) public {
        if (_taskNumber > taskCount) {
            revert TaskNumberDoesNotExistError();
        }
        if (userTaskCompleted[msg.sender][_taskNumber]) {
            revert UserAlreadyCompletedTaskError();
        }
        if (usedSignatures[_hashedMessage]) {
            revert SignatureAlreadyUsedError();
        }

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address recoveredSigner = ecrecover(prefixedHashMessage, _v, _r, _s);

        if (i_owner == recoveredSigner) {
            userTaskCompleted[msg.sender][_taskNumber] = true;

            uint256 prize = taskToPrize[_taskNumber];
            userPrizeBalance[msg.sender] += prize;

            usedSignatures[_hashedMessage] = true;

            address referee = userReferee[msg.sender];
            if (referee != address(0)) {
                uint256 refBonus = prize / 10;
                uint256 userBonus = prize / 50; 
                userPrizeBalance[referee] += refBonus;
                userPrizeBalance[msg.sender] += userBonus;
            }
        } else {
            revert InvalidSignatureError();
        }
    }


    function getUserBalance(address _user) public view returns(uint256) {
        return userPrizeBalance[_user];
    }

    function getUserReferee(address _user) public view returns (address) {
        return userReferee[_user];
    }

    function getUserCompletedTasks(address _user, uint256 _task) public view returns (bool) {
        return userTaskCompleted[_user][_task];
    }
    
    function getTaskToPrize(uint256 _task) public view returns (uint256) {
        return taskToPrize[_task];
    }
}
