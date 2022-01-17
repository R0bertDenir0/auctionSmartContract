// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Auction {
    address payable public owner;
    //lorsque l'enchère démarre, on a le timestamp(15sec blocktime)
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBider;

    mapping(address=> uint)public bids;
    uint bidIncrement;

    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        //enchère avec une durée d'une semaine
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    modifier afterStart(){
    require(block.number >= startBlock);
    _;
    }

    modifier beforeEnd(){
    require(block.number <= endBlock);
    _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function min(uint a, uint b)pure internal returns(uint){
        if(a <= b){
            return a;
        }else {
            return b;
            }
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }


    function placeBid()public payable notOwner afterStart beforeEnd{
    require(auctionState == State.Running);
    require(msg.value >= 100);

    uint currentBid = bids[msg.sender] + msg.value;
    require(currentBid > highestBindingBid);

    bids[msg.sender] = currentBid;

    if(currentBid <= bids[highestBider]){
        highestBindingBid = min(currentBid + bidIncrement, bids[highestBider]);
    
    }else{
        highestBindingBid = min(currentBid, bids[highestBider] + bidIncrement);
        highestBider = payable(msg.sender);
        }
    }

    function finalizeAuction()public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;

        if(auctionState == State.Canceled) {//enchère annulée
            recipient = payable(msg.sender);
            value = bids[msg.sender];

        }else {//enchère finie(pas annulée)
            if(msg.sender == owner) {//le owner 
            recipient = owner;
            value = highestBindingBid;

        }else {//c'est un encherisseur
            if(msg.sender == highestBider){
            recipient == highestBider;
            value = bids[highestBider] - highestBindingBid;
            }else {//ni le owner ni le highestBider
            recipient = payable(msg.sender);
            value = bids[msg.sender];

        
                }
            }

        }
        recipient.transfer(value);
    }
}