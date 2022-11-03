// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0 ;


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

contract AToken {

    string public constant name = "AToken"; 
    string public constant symbol = "ATK"; 
    uint8 public constant decimals = 18;   

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    modifier onlyOwner  {
        require (msg.sender == ownerCon);
        _;
    }

    mapping(address => uint256) balances; 
  
    mapping(address => mapping (address => uint256)) allowed; 

    uint256 totalSupply_;
    address ownerCon;
    mapping(address => bool) whiteList;


    using SafeMath for uint256;


    constructor() {  
	totalSupply_ = 1000 * (10 ** decimals);
	balances[msg.sender] =  totalSupply_/2; 
    totalSupply_ = totalSupply_.sub(balances[msg.sender]);
	ownerCon = msg.sender;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    // getter function

    function balanceOf(address inputAddress) public view returns (uint) {
        return balances[inputAddress];
    }
    // getter function 
    
    function transfer(address receiver, uint numTokens) public returns(bool){
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
    }// what allowance has been provided by token_owner to Token_manager



    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


