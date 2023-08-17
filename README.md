# EtherHider
=======


#### About 

<p>
This is a contract factory that is capable of deploying a contract with bytecode and 
a salt. I wrote it thinking I would use it to precompute contract addresses off-chain 
that I could send Ether to and then retrieve later. But you could also use it to deploy 
just about anything. 
</p>

#### Usage

<p>
There are helper functions to compute contract addresses. So let's say you wanted to 
store some Ether at a contract address, and you do not want anyone to know that you own 
this Ether. Basically you just need to generate a salt, compute the address by 
calling `computeInitCode`, send the 
Ether to that address, and DON'T LOOSE THE SALT! When the day comes that you need to 
retrieve that ether, you simply run `retrieveEther` with that salt, which will deploy 
a contract at that address with the most minimal bytecode ever: 0x33ff, seriously, 
that's it! The contract will selfdestruct and the deployer contract will forward all 
the funds to you (the EOA that made the call, which must be the admin).
</p>

#### Warning: THIS IS REALLY BETA

<p>
There are some other features that are either not fully implemented, or not yet at all 
implemented. For example, you may notice ...
</p>

<pre>
bytes public destructLaterInitCode = '0x336000556010601160003960106000f3fe336000548103600b5780ff5b600080fd';
</pre>

<p>
This is bytecode for a contract that will not immediately self destruct, but can be 
destroyed later. The only thing it does is selfdestruct, and this is important:

**only if called by the deployer contract**!


Which you would do by calling `killChild` with that contract's address. Just be aware that 
this is really beta, if you use it.
</p>

#### TODO

- Python Tool to interact with contract and securely store salts in a local database 
- Helper/Wrapper functions to deploy the `destructLaterInitCode`