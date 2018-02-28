pragma solidity ^0.4.8;

contract Tender {
    address public owner;       
    uint public startTime;      
    uint public endTime;        

    bool public canceled;                                   
    address public lowestBidder;                            
    mapping(address => uint256) public fundsByBidder;       

    event LogBid(address bidder, uint bid, address lowestBidder, uint lowestBid);       
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();

    function Tender(address _owner, uint _startTime, uint _endTime) public {
        require(_startTime <= _endTime);        
        require(_startTime > block.number);
        require(_owner != 0);

        owner = _owner;
        startTime = _startTime;
        endTime = _endTime;
    }

    function getLowestBid() public constant returns (uint) {
        return fundsByBidder[lowestBidder];
    }

    function placeBid() public payable onlyAfterStart onlyBeforeEnd onlyNotCanceled onlyNotOwner returns (bool success) {
        require(msg.value != 0);

        uint newBid = msg.value;
        
        require(newBid < lowestBid);

        uint lowestBid = fundsByBidder[lowestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (msg.sender != lowestBidder) {
            lowestBidder = msg.sender;
            lowestBid = newBid;            
            
        }else{
            lowestBid = newBid;
        }


        LogBid(msg.sender, newBid, lowestBidder, lowestBid);
        return true;
    }

    function cancelAuction() public onlyOwner onlyBeforeEnd onlyNotCanceled returns (bool success) {
        canceled = true;
        LogCanceled();
        return true;
    }

    function withdraw() public onlyEndedOrCanceled returns (bool success) {
        require(this.balance > 0);
        
        address withdrawalAccount;
        uint withdrawalAmount;
        
        if(msg.sender == owner){
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[lowestBidder];

        }else if(msg.sender == lowestBidder){
            revert();
        }else{
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];
        }
        
        require(withdrawalAmount != 0);

        fundsByBidder[withdrawalAccount] = 0;

        // send the funds
        require(msg.sender.send(withdrawalAmount));

        LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotOwner {
        require(msg.sender != owner);
        _;
    }

    modifier onlyAfterStart {
        require(now > startTime);
        _;
    }

    modifier onlyBeforeEnd {
        require(now < endTime);
        _;
    }

    modifier onlyNotCanceled {
        require(!canceled);
        _;
    }

    modifier onlyEndedOrCanceled {
        require(now > endTime && canceled);
        _;
    }
}
