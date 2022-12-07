//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

contract ControlAccess{
    //events
    event Deposit(address indexed sender, uint val);
    event Submit(uint indexed txId);
    event Approved(address indexed sender,uint indexed txId);
    event Executed(uint indexed txId);
    event ExecutionFailed(uint indexed txId);
    event RevokeAccess(address indexed sender, uint indexed txId);
    event AddOwner(address indexed owner);
    event RemoveOwner(address indexed owner);
    event RequiredOwnersUpdate(uint requiredOwners);
    event TransferAdmin(address indexed admin);

    address public admin;
    address[] public owners;
    mapping(address=>bool) public isOwner;
    uint requiredOwners;

    modifier onlyAdmin(){
        require(msg.sender == admin, "Admin Only");
        _;
    }

    modifier notzeroAddress(address _addr){
        require(_addr != address(0), "The address is Not Valid");
        _;
    }

    modifier ownerExists(address owner){
        require(isOwner[owner] == true, "you are not Owner");
        _;
    }

    modifier ownerNotExists(address owner){
        require(isOwner[owner] == false, "This Owner already exists");
        _;
    }

    function addOwner(address owner) external onlyAdmin notzeroAddress(owner) ownerNotExists(owner){
        isOwner[owner] = true;
        owners.push(owner);

        emit AddOwner(owner);
        OwnersRequiredUpdate(owners);
    }

    function removeOwner(address owner) external onlyAdmin notzeroAddress(owner) ownerExists(owner){
        isOwner[owner] = false;
        for(uint i;i<owners.length-1;i++){
            if(owners[i] == owner){
                owners[i] = owners[owners.length - 1];
                break;
            }
            owners.pop();
        }
        OwnersRequiredUpdate(owners);
    }

    function OwnerTransfer(address from,address to) external onlyAdmin notzeroAddress(from) notzeroAddress(to) ownerExists(from) ownerNotExists(to){
        for(uint i;i<owners.length;i++){
            if(owners[i] == from){
                owners[i] = to;
                break;
            }
        }
        isOwner[from] = false;
        isOwner[to] = true;

        emit RemoveOwner(from);
        emit AddOwner(to);
    }

    function changeAdmin(address newAdmin) external onlyAdmin{
        admin = newAdmin;
        emit TransferAdmin(newAdmin);
    }

    function OwnersRequiredUpdate(address[] memory _owners) internal{
        uint num = _owners.length * 60;
        requiredOwners = num / 100;

        emit RequiredOwnersUpdate(requiredOwners);
    }

}
