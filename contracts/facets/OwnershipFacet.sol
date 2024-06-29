pragma solidity ^0.8.24;

contract OwnershipFacet {
    bytes32 constant OWNERSHIP_STORAGE_POSITION = keccak256("diamond.standard.ownership.storage");

    struct OwnershipStorage {
        address owner;
    }

    function initializeOwner(address _newOwner) external {
        OwnershipStorage storage os = ownershipStorage();
        require(os.owner == address(0), "Owner already set");
        os.owner = _newOwner;
    }

    function setOwner(address _newOwner) internal onlyOwner {
        OwnershipStorage storage os = ownershipStorage();
        os.owner = _newOwner;
    }

    function owner() external view returns (address) {
        return ownershipStorage().owner;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        setOwner(_newOwner);
    }

    function ownershipStorage() internal pure returns (OwnershipStorage storage os) {
        bytes32 position = OWNERSHIP_STORAGE_POSITION;
        assembly {
            os.slot := position
        }
    }

    modifier onlyOwner() {
        require(msg.sender == ownershipStorage().owner, "Only the owner can call this function");
        _;
    }

    function getSelectorsOwnership() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = OwnershipFacet.owner.selector;
        selectors[1] = OwnershipFacet.transferOwnership.selector;
        selectors[2] = OwnershipFacet.initializeOwner.selector;
        return selectors;
    }
}
