// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0 ;
contract Auction{
    address payable public auctioneer;
    uint public st_block;//start time
    uint public et_block;//end time

    enum Auc_State {Started, Running, Ended, Cancelled}
    Auc_State auctionState;

    uint public highestPayableBid;
    uint  bidInc;
    uint256 _bidID = 0 ;
    bool  bidSelected = false;
    address payable SelectedBidder;
    uint256 public totalBidders;

    struct BidInfo {
        uint256 BidId;
        address payable bidder;
        uint256 bidAmount;
    }

    BidInfo public SelectedID;

    BidInfo[] _bidInfo;

    mapping(uint256 => BidInfo) bidArray;



    mapping(address => uint256) public bids;   

    constructor(){
        auctioneer = payable(msg.sender);
        auctionState = Auc_State.Running;
        st_block =  block.number;
        et_block = st_block + 240;
        bidInc = 1 ether;
    }

    modifier notOwner(){
        require(msg.sender != auctioneer,"Owner cannot bid");
        _;
    }

    modifier OwnerOnly(){
        require(msg.sender == auctioneer,"Only Owner can use this Function");
        _;
    }

    modifier started(){
        require(block.number>st_block);
        _;
    }

    modifier beforeEnding(){
        require(block.number<et_block);
        _;
    }

    modifier isbidSelected(){
        require(bidSelected = true);
        _;
    }


    function cancelAuc() public OwnerOnly{
        auctionState = Auc_State.Cancelled;
    }

    function endAuc() public OwnerOnly{
        auctionState = Auc_State.Ended;
    }

    function bid() payable public notOwner started beforeEnding{
        require ( auctionState == Auc_State.Running ) ;
        require ( msg.value >= 1 ether ) ;
                    

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid>=highestPayableBid,"Bid more than highest payable bid");
        bids[msg.sender] =  currentBid;
        _bidID++;
        totalBidders = _bidID;
        bidArray[_bidID]= BidInfo(_bidID,payable(msg.sender),msg.value); 
        highestPayableBid=currentBid+bidInc;
    }


    function bidInfo(uint256 bidId) public view OwnerOnly returns(uint256 _BidId, address _bidder,uint256 bidAmount){
        return (bidArray[bidId].BidId, bidArray[bidId].bidder, bidArray[bidId].bidAmount);
    }

    function selectBid(uint256 bId) public OwnerOnly {
        SelectedID = bidArray[bId];
        SelectedBidder = SelectedID.bidder;
        bidSelected = true;
    }


    function finalizedAuc() public isbidSelected {
        require(auctionState == Auc_State.Cancelled || auctionState == Auc_State.Ended || block.number>et_block);
        require (msg.sender == auctioneer || bids[msg.sender] > 0);

        address payable receiver;
        uint value;

        if(auctionState==Auc_State.Cancelled){
            receiver = payable(msg.sender);
            value = bids[msg.sender]; 
        }else{
            if(msg.sender == auctioneer){
                receiver = auctioneer;
                value = SelectedID.bidAmount;
            }
            else{
                if(msg.sender == SelectedBidder ){
                    receiver = SelectedBidder;
                    value = bids[SelectedBidder]-highestPayableBid;
                }
                else{
                    receiver = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
            bids[msg.sender]=0;
            receiver.transfer(value);
        }
    }


}

