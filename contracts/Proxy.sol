pragma solidity 0.8.11;

abstract contract Storage {
    address public implementation;
    address public owner = msg.sender;
}

contract Proxy is Storage {
    function setImplemention(address _impl) public {
        require(msg.sender == owner);
        implementation = _impl;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    fallback() external {
        (, bytes memory result) = address(implementation).delegatecall(
            msg.data
        );
        return2(result);
    }

    receive() external payable {
        (, bytes memory result) = address(implementation).delegatecall(
            msg.data
        );
        return2(result);
    }
}
