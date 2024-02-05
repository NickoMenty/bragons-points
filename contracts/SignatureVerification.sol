// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

error OnlyOwnerError();
error TaskNumberDoesNotExistError();
error UserAlreadyCompletedTaskError();
error InvalidSignatureError();
error SignatureAlreadyUsedError();
error RefereeIsUserError();

enum YieldMode {
    AUTOMATIC,
    VOID,
    CLAIMABLE
}

enum GasMode {
    VOID,
    CLAIMABLE 
}

interface IBlast{
    // configure
    function configureContract(address contractAddress, YieldMode _yield, GasMode gasMode, address governor) external;
    function configure(YieldMode _yield, GasMode gasMode, address governor) external;

    // base configuration options
    function configureClaimableYield() external;
    function configureClaimableYieldOnBehalf(address contractAddress) external;
    function configureAutomaticYield() external;
    function configureAutomaticYieldOnBehalf(address contractAddress) external;
    function configureVoidYield() external;
    function configureVoidYieldOnBehalf(address contractAddress) external;
    function configureClaimableGas() external;
    function configureClaimableGasOnBehalf(address contractAddress) external;
    function configureVoidGas() external;
    function configureVoidGasOnBehalf(address contractAddress) external;
    function configureGovernor(address _governor) external;
    function configureGovernorOnBehalf(address _newGovernor, address contractAddress) external;

    // claim yield
    function claimYield(address contractAddress, address recipientOfYield, uint256 amount) external returns (uint256);
    function claimAllYield(address contractAddress, address recipientOfYield) external returns (uint256);

    // claim gas
    function claimAllGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGasAtMinClaimRate(address contractAddress, address recipientOfGas, uint256 minClaimRateBips) external returns (uint256);
    function claimMaxGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGas(address contractAddress, address recipientOfGas, uint256 gasToClaim, uint256 gasSecondsToConsume) external returns (uint256);

    // read functions
    function readClaimableYield(address contractAddress) external view returns (uint256);
    function readYieldConfiguration(address contractAddress) external view returns (uint8);
    function readGasParams(address contractAddress) external view returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode);
}

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
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
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

    /* Blast functions */
    function claimAllGas(address recipient) external onlyOwner{
		IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), recipient);
    }
    function claimMaxGas(address recipient) external onlyOwner{
		IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), recipient);
    }

    /* Blast view functions */
    function readClaimableYield() public view returns (uint256) {
        return IBlast(0x4300000000000000000000000000000000000002).readClaimableYield(address(this));
    }

    function readGasParams() public view returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
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
