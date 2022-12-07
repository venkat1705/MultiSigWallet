//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;
import "./Registry.sol";

contract MultiSigWallet is ControlAccess{
    uint public transactionCount;
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
    }
    Transaction[] public validtransactions;
    mapping(uint256=>Transaction) public transactions;
    mapping(uint=>mapping(address=>bool)) public approved;

    modifier onlyOwner(address owner){
        require(isOwner[owner] == true,"only Owner");
        _;
    }

   modifier approveTransaction(uint _txId,address owner){
       require(approved[_txId][owner] == false,"Transaction aready Approved");
       _;
   }

   modifier transactionExecuted(uint _txId){
       require(transactions[_txId].executed == false,"Transacion already executed");
       _;
   }
    

    constructor(address[] memory _owners){
        admin = msg.sender;
        require(_owners.length >=3,"There must be Atleast 3 initial Signatures");
        for(uint i;i<_owners.length;i++){
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        uint num = owners.length * 60;
        requiredOwners = num / 100;
    }

    receive() external payable{
        if(msg.value > 0){
            emit Deposit(msg.sender,msg.value);
        }
    }

    function submitTransaction(address _to,uint _value,bytes calldata _data) external onlyOwner(msg.sender) returns(uint transactionId){
        transactionId = transactionCount;
        transactions[transactionCount] = Transaction({
            to:_to,
            value:_value,
            data:_data,
            executed:false
        });

        transactionCount += 1;
        emit Submit(transactionId);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId) public onlyOwner(msg.sender) approveTransaction(transactionId,msg.sender) notzeroAddress(transactions[transactionId].to){
        approved[transactionId][msg.sender] = true;
        emit Approved(msg.sender,transactionId);

        executeTransaction(transactionId);
    }

    function executeTransaction(uint transactionId) public onlyOwner(msg.sender) transactionExecuted(transactionId) {
        uint count = 0;
        bool requiredSignaturesmet;

        for(uint i;i<owners.length;i++){
            if(approved[transactionId][owners[i]]){
                count += 1;
            }
            if(count >=requiredOwners){
                requiredSignaturesmet = true;
            }
        }
        if(requiredSignaturesmet){
            Transaction storage transaction = transactions[transactionId];
            transaction.executed = true;

            (bool success, ) = transaction.to.call{value:transaction.value}(transaction.data);

            if(success){
                validtransactions.push(transaction);
                emit Executed(transactionId);
            }
            emit ExecutionFailed(transactionId);
            transaction.executed = false;
        }
    }

    function revokeTransaction(uint transactionId) external onlyOwner(msg.sender) approveTransaction(transactionId,msg.sender) transactionExecuted(transactionId) notzeroAddress(transactions[transactionId].to){
        approved[transactionId][msg.sender] = false;
        emit RevokeAccess(msg.sender,transactionId);
    }

    function getOwners() external view returns(address[] memory){
        return owners;
    }

    function getValidTransactions() external view returns(Transaction[] memory){
        return validtransactions;
    }

    function getApprovedSignatures() external view returns(uint){
        return requiredOwners;
    }

}
