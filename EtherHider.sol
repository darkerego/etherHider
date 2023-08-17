/**
 *Submitted for verification at Etherscan.io on 2023-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EtherHiderDeployer {
    // bytes constant destructOriginInitCode = hex"73000000000000000000000000000000000000000030ff";
    bytes dieSelector = '0x41c0e1b5';
    bytes destructToSenderInitCode =   '0x33ff';
    bytes32 public defaultSalt = 0x0000000000000000000000000000000000000000000000000000000000000000; // it's not a key, you script kiddy retards
    bytes destructLaterInitCode = '0x336000556010601160003960106000f3fe336000548103600b5780ff5b600080fd';
    address public immutable admin;
    address private thisAddress;

    bytes32 FAILED_DEPLOY = 'Deployment failed!!!';
    event ContractCreated(address indexed contractAddress);

    receive() external payable {}
    fallback() external payable{}

    constructor() {
        admin = msg.sender;
    }

    function authenticate() private view {
        require(msg.sender == admin, "!admin");
    }

    modifier protected {
        authenticate();
        _;
    }

    function deploy(bytes memory bytecode, bytes32 salt) public protected returns (address) {
        address addr;
        /*

        */
        // Assembly block to call the CREATE2 opcode
        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
            /*if iszero(extcodesize(addr)) {
                revert(0, 0)
            }*/
        }
        emit ContractCreated(addr);
        return addr;
    }

    // Function to compute the address of the contract that would be deployed using CREATE2
    function computeAddress(bytes memory initCode, bytes32 salt) public view returns (address) {
        bytes32 codeHash = keccak256(initCode);
        bytes32 rawAddress = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                codeHash
            )
        );

        return address(bytes20(rawAddress << 96));
    }

    function deployInitCode(bytes32 salt) internal returns(address) {
        return deploy(destructToSenderInitCode, salt);
    }

    function computeInitCode(bytes32 salt) public view returns(address) {
        return computeAddress(destructToSenderInitCode, salt);
    }

    function killChild(address childAddress) external protected {
         executeCall(childAddress, 0, dieSelector);
    }

    function balanceOf(address) public view returns(uint bal) {
        assembly {
            bal := balance(calldataload(0x04))
        }
    }

    function codeSize(address _addr) public view returns (uint size) {
         /*
         Return >0 if it's a contract
         */

        assembly { size := extcodesize(_addr) }
    }

    function forwardEther(address destination, uint amount) public payable protected {
        executeCall(destination, amount, "");
    }

    function executeCall(
        /*
            @dev: Function to executeCall a transaction with arbitrary parameters. Handles
            all withdrawals, etc. Can be used for token transfers, eth transfers,
            or anything else.
        */
        address recipient,
        uint256 _value,
        bytes memory data
        ) internal returns(bytes memory) {
       assembly {
            let ptr := mload(0x40)
            let success_ := call(gas(), recipient, _value, add(data, 0x20), mload(data), 0x00, 0x00)
            let success := eq(success_, 0x1)
            let retSz := returndatasize()
            let retData := mload(0x40)

            returndatacopy(mload(0x40), 0 , returndatasize())
            if iszero(success) {
                revert(retData, retSz)}
            return(retData, retSz) // return the result from memory
            }
        }


    function staticCall(address target, bytes memory callData) internal view returns (bool success, bytes memory data) {
        assembly {
            let size := mload(callData) // Get the data size
            let ptr := add(callData, 0x20) // Skip the length field

            success := staticcall(
                gas(),        // Gas limit
                target,       // Target address
                ptr,          // Input data pointer
                size,         // Input data size
                add(ptr, size), // Output data pointer
                0             // Output data size, will be updated later
            )

            let retSize := returndatasize()
            data := mload(0x40) // Fetch the free memory pointer
            mstore(0x40, add(data, add(retSize, 0x20))) // Adjust the free memory pointer
            mstore(data, retSize) // Store the return data size
            returndatacopy(add(data, 0x20), 0, retSize) // Copy the return data
        }
    }

    function parseRetdata(bytes memory _returnData) internal pure returns (string memory) {
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function thisBalance() public view returns(uint b) {
        assembly {
            b := selfbalance()
        }
    }


    function withdraw(address tokenAddress) public protected returns(bytes32){
        /*
          Allow the owner to withdraw tokens/eth sent to this address.
        */
        if (tokenAddress == address(0)) {
            require(thisBalance() > 0, "!balance");
            return bytes32(executeCall(admin, thisBalance(), ""));
        } else {
            bytes memory data = encodeBalanceOf(address(this));
            (bool success, bytes memory balanceData) = staticCall(tokenAddress, data);(tokenAddress, data);
            if (success) {
                uint bal = uint(bytes32(balanceData));
                return(bytes32(executeCall(tokenAddress, 0, encodeTransfer(admin, bal))));
            } else {
                revert("Static call Failed");
        }
        }
    }

    function encodeTransfer(address dest, uint256 amount) public pure returns(bytes memory){
        return abi.encodeWithSignature(
                "transfer(address,uint256)",
                dest,
                amount
            );
    }

    function encodeBalanceOf(address dest) public pure returns(bytes memory){
        return abi.encodeWithSignature(
                "balanceOf(address)",
                dest
            );
    }

    function encodeCallHelper(string memory fnargs) public pure returns(bytes memory) {
        return abi.encodeWithSignature(fnargs);
    }


    function retrieveEther(bytes32 salt) public protected returns(address deadAddress) {
        address targetAddress = computeAddress(destructToSenderInitCode, salt);
        require(targetAddress.balance > 0, "No ether stored there!");
        deadAddress =  deployInitCode(salt);
        forwardEther(admin, address(this).balance);
    }
}