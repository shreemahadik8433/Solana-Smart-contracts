// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 ;

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a); 
      return a - b; 
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

interface AInterface{
  function transfer(address receiver, uint numTokens) external returns (bool) ;
  function transferFrom(address owner, address buyer, uint numTokens) external returns (bool);
  function balanceOf(address inputAddress) external view returns (uint);
}

contract BToken {

    string public constant name = "BToken"; 
    string public constant symbol = "BTK"; 
    uint8 public constant decimals = 18;   

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);
    
    mapping(address => StakeInfo) public stakeInfos;


    struct StakeInfo {        
        uint256 amount; 
        uint256 claimed;       
    }

    modifier onlyOwner  {
        require (msg.sender == ownerCon);
        _;
    }

    modifier noReentry() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier timestampNotSet() {
        require(timestampSet == false, "The time stamp has already been set.");
        _;
    }

     modifier timestampIsSet() {
        require(timestampSet == true, "Please set the time stamp first, then try again.");
        _;
    }

    mapping(address => uint256) balances; 
  
    mapping(address => mapping (address => uint256)) allowed; 

    uint256 totalSupply_;
    uint256 total;
    address ownerCon;
    uint256 _100 = 100;
    uint256 _10_percent;
    uint256 _15_percent;
    uint256 _20_percent;

    bool internal locked;
    
    uint256 public initialTimestamp;
    bool public timestampSet;
    uint256 public timePeriod;

    mapping(address => uint256) public alreadyWithdrawn;
    mapping(address => bool) public addressStaked;
    mapping(address => uint256) public claimed;
    
    uint256 public contractBalance;


    event tokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);

    using SafeMath for uint256;


    AInterface tokenA;

    constructor(AInterface A_tokenAddress){  
        totalSupply_ =  1000 * (10 ** decimals);
        total = totalSupply_;
        tokenA = A_tokenAddress;
        ownerCon= msg.sender;
        timestampSet = false;
        locked = false;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }

    function balanceOf(address inputAddress) public view returns (uint) {
        return balances[inputAddress];
    }
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender], "Not Sufficient Balance");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens); 
        return true;
    }


    function approve(address approved_addr, uint numTokens) public returns (bool) {
        allowed[msg.sender][approved_addr] = numTokens;
        emit Approval(msg.sender, approved_addr, numTokens);
        return true;
    }


    function allowance(address owner, address token_manger) public view returns (uint) {
        return allowed[owner][token_manger];
    }



    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }


    function stake(uint256 _timePeriodInSeconds,uint256 _amount) public payable timestampNotSet noReentry  returns (bool) {
        uint256 balance_A = tokenA.balanceOf(msg.sender);
        require( _timePeriodInSeconds>=86400, "Minimum period of staking is one day");
        require(balance_A >= _amount, "Not enough tokens in your wallet, please try lesser amount");
        
        tokenA.transferFrom(msg.sender,address(this),_amount);
        stakeInfos[msg.sender] = StakeInfo({
            amount: _amount,
            claimed: 0 });

        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
        timestampSet = true;
        
        claimed[msg.sender] == 0;
        addressStaked[msg.sender] = true;
        emit Staked( msg.sender, _amount);  
        return true;
    }

    function un_stake() public timestampIsSet noReentry returns (bool) {
        require(addressStaked[msg.sender] == true, "You are not participated");
        require(timePeriod < block.timestamp , "Stake Time is not over yet");
        require (claimed[msg.sender] == 0, "Already claimed");
        
        if ( block.timestamp.sub(timePeriod) == 86400 || block.timestamp.sub(timePeriod) < 1296000){
            _10_percent = (stakeInfos[msg.sender].amount/_100) * 10 ;
            balances[msg.sender]=_10_percent;
            tokenA.transfer(msg.sender, stakeInfos[msg.sender].amount);
            stakeInfos[msg.sender].claimed=stakeInfos[msg.sender].claimed.add( balances[msg.sender]);
            stakeInfos[msg.sender].amount=stakeInfos[msg.sender].amount.sub(stakeInfos[msg.sender].claimed);
             claimed[msg.sender] = balances[msg.sender];
             totalSupply_ -= balances[msg.sender];
             emit Claimed( msg.sender, _10_percent);
             return true;
          
        }
        else if( block.timestamp.sub(timePeriod) == 1296000 || block.timestamp.sub(timePeriod) < 2592000){
            _15_percent = (stakeInfos[msg.sender].amount/_100) * 15 ;
            balances[msg.sender]=_15_percent;
            tokenA.transfer(msg.sender, stakeInfos[msg.sender].amount);
            stakeInfos[msg.sender].claimed=stakeInfos[msg.sender].claimed.add( balances[msg.sender]);
            stakeInfos[msg.sender].amount=stakeInfos[msg.sender].amount.sub(stakeInfos[msg.sender].claimed);
             claimed[msg.sender] = balances[msg.sender];
             totalSupply_ -= balances[msg.sender];
             emit Claimed( msg.sender, _15_percent);
             return true;
        }
        else {
            _20_percent = (stakeInfos[msg.sender].amount/_100) * 20 ;
            balances[msg.sender]=_20_percent;
            tokenA.transfer(msg.sender, stakeInfos[msg.sender].amount);
            stakeInfos[msg.sender].claimed=stakeInfos[msg.sender].claimed.add( balances[msg.sender]);
            stakeInfos[msg.sender].amount=stakeInfos[msg.sender].amount.sub(stakeInfos[msg.sender].claimed);
             claimed[msg.sender] = balances[msg.sender];
             totalSupply_ -= balances[msg.sender];
             emit Claimed( msg.sender,_20_percent);
             return true;
        }
    }
}


