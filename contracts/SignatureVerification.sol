// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignatureVerification {

    error OnlyOwnerError();
    error TaskNumberDoesNotExistError();
    error UserAlreadyCompletedTaskError();
    error InvalidSignatureError();
    error SignatureAlreadyUsedError();

    address immutable i_owner;
    uint256 public taskCount;
    mapping(uint256 => uint256) public taskToPrize;
    mapping(address => mapping(uint256 => bool)) public userTaskCompleted;
    mapping(bytes32 => bool) public usedSignatures;
    mapping(address => uint256) public userPrizeBalance;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert OnlyOwnerError();
        }
        _;
    }

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

            userPrizeBalance[msg.sender] += taskToPrize[_taskNumber];

            usedSignatures[_hashedMessage] = true;
        } else {
            revert InvalidSignatureError();
        }
    }

    function readOwner() public view returns(address) {
        return i_owner;
    }

    function userBalance(address _user) public view returns(uint256) {
        return userPrizeBalance[_user];
    }

    
}
