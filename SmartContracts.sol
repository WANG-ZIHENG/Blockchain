// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// P2P smart contract
contract P2P {

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    //(a) 
    // A structure to store information of prosumers.
    struct Prosumer {
        int energyStatus; // energy status
        uint balance; // balance (Ethers in smart wallet)
    }

    // A mapping to store information of energy consumers.
    mapping(address => Prosumer) public prosumers; 

    // This modifier restricts the function to be called only by the contract owner
    modifier onlyOwner() {
        // Check if the function caller is the owner
        require(msg.sender == _owner, "Caller is not the owner");
        // If the caller is the owner, execute the function body
        _;
    }

    // This function gets the energy status of a Prosumer by prosumer's address
    function getEnergyStatus(address _prosumer) public view returns (int) {
        return prosumers[_prosumer].energyStatus;
    }

    // This function sets the energy status of a Prosumer, needs to input prosumer's address and energy status
    function setEnergyStatus(address _prosumer, int _newEnergyStatus) public onlyOwner {
        prosumers[_prosumer].energyStatus = _newEnergyStatus;
    }

    // This function gets the balance of a Prosumer by prosumer's address
    function getBalance(address _prosumer) public view returns (uint) {
        return prosumers[_prosumer].balance;
    }

    // This function sets the balance of a Prosumer, needs to input prosumer's address and energy status
    function setBalance(address _prosumer, uint _newBalance) public onlyOwner {
        prosumers[_prosumer].balance = _newBalance;
    }

    // This function allows a Prosumer to transfer Ether to another Ethereum address, needs to inputs recipient' address and amount
    function transfer(address payable recipient, uint256 amount) public {
        require(
            prosumers[msg.sender].balance >= amount,
            "Insufficient balance"
        );   
        require(recipient != address(0), "Invalid recipient address"); 
        bool success = recipient.send(amount); 
        require(success, "Transfer failed"); 
    }

    // (b) 
    // // This function allows a Prosumer to register their Ethereum address in the smart contract by address
    function registerProsumer(address _address) public {
        require(
            prosumers[_address].balance == 0,
            "Prosumer already registered"
        );
        prosumers[_address].balance = 0; // Initialize the Prosumer's balance to zero in the smart contract
    }

    // (c) 
    // Add functions to buy and sell energy.
    function buyEnergy(address seller, int amount) public payable {
        require(
            amount <= prosumers[seller].energyStatus,
            "Not enough energy available for purchase"
        );
        require(

            msg.value == uint(amount) * 1 ether,
            "Incorrect amount of Ether sent"
        );
        // Update the balance and energy status of the seller and buyer.
        prosumers[seller].balance += msg.value;
        prosumers[seller].energyStatus -= amount;
        prosumers[msg.sender].balance -= msg.value;
        prosumers[msg.sender].energyStatus += amount;
    }


    function sellEnergy(address buyer, int amount) public {
        require(
            amount <= prosumers[msg.sender].energyStatus,
            "Not enough energy available for sale"
        );
        require(
            prosumers[buyer].balance >= uint(amount) * 1 ether,
            "Buyer does not have enough Ether"
        );
        // Update the balance and energy status of the seller and buyer.
        prosumers[buyer].balance -= uint(amount) * 1 ether;
        prosumers[buyer].energyStatus += amount;
        prosumers[msg.sender].balance += uint(amount) * 1 ether;
        prosumers[msg.sender].energyStatus -= amount;
    }
}

// Main smart contract
contract Main {
    P2P private p2pContract; // The instance of the P2P contract.

    constructor(address _p2pContractAddress) {
        p2pContract = P2P(_p2pContractAddress);
    }

    mapping(address => bool) internal user; // Mapping to keep track of registered users

    int internal total_energy; // Total energy of the system

    mapping(address => int256) internal order; // Mapping to keep track of orders made by each user

    address[] internal markets; // Array to store the addresses of all markets in the system

    // (a) 
    // Modifier function to make sure a prosumer is registered in the system before sending any request.
    modifier isRegisteredProsumer() {
        require(user[msg.sender], "Prosumer is not registered");
        _;
    }
    // (b)
    // Modifier function to ensure single registration of a prosumer 
    modifier isNotRegisteredProsumer() {
        require(!user[msg.sender], "Prosumer is already registered");
        _;
    }

    // (c)
    // Modifier function to check whether a buyer has deposited sufficient funds
    modifier hasEnoughBalance(int energyAmount) {
        require(
            p2pContract.getBalance(msg.sender) >= uint(energyAmount) * 1 ether,
            "Not enough balance to purchase energy"
        );
        _;
    }
    // (d)
    // A public function to register a prosumer.
    function register() public isNotRegisteredProsumer {
        p2pContract.registerProsumer(msg.sender); 
        user[msg.sender] = true; 
    }

    // (e) 
    // A public function to enable a buyer to deposit some Ethers prior to energy buying request. 
    function deposit() public payable isRegisteredProsumer {
        uint balance = p2pContract.getBalance(msg.sender); 
        balance += msg.value; 
        p2pContract.setBalance(msg.sender, balance); 
    }

    // (f) 
    function sendEnergyRequest(int energyAmount) public isRegisteredProsumer {
        require(energyAmount != 0, "Energy amount cannot be zero");
        // Incentive
        int energyAmount_ = energyAmount;
        
        // There is a 2% discount for energy recharges or expenditures over 10.
        if (energyAmount > 10 || energyAmount < -10) {
            energyAmount = (energyAmount * 80) / 100;
        }
        // Otherwise, there is a 1% discount for single energy recharges or expenditures over 5.
        else if (energyAmount > 5 || energyAmount < -5) {
            energyAmount = (energyAmount * 90) / 100;
        }
        

        // If the order quantity is low, increasing liquidity can offer discounts. Liquidity will be limited to a maximum of 10.
    
        // more sellers 
        if (total_energy > 10  && energyAmount<0) {
            energyAmount = (energyAmount * 90) / 100;
        }// more buyer
        else if (total_energy < -10  && energyAmount > 0) {
            energyAmount = (energyAmount * 90) / 100;
        }


        if (energyAmount < 0) {
            // A request to purchase energy.
            uint energyAmountuint = uint(-energyAmount);
            uint balance = p2pContract.getBalance(msg.sender);
            balance -= energyAmountuint * 1 ether;
            p2pContract.setBalance(msg.sender, balance);
        } else {
            // A request to sell energy.
            uint energyAmountuint = uint(energyAmount);
            int EnergyStatus = p2pContract.getEnergyStatus(msg.sender);
            EnergyStatus -= int(energyAmountuint * 1 ether);
            p2pContract.setEnergyStatus(msg.sender, EnergyStatus);
        }
        matchorder(msg.sender, energyAmount_); // Match the order with other orders.
    }

    // (g)
    //  Retrieve the current energy status of the seller or buyer.
    function getEnergyStatus() public view isRegisteredProsumer returns (int) {
        return p2pContract.getEnergyStatus(msg.sender);
    }

    // (h)
    // Retrieve the current balance of the seller or buyer.
    function getBalance() public view isRegisteredProsumer returns (uint) {
        return p2pContract.getBalance(msg.sender);
    }

    // (i) 
    // A public function to withdraw the Ethers from smart wallets of prosumers. 
    function withdraw() public isRegisteredProsumer {
        require(
            p2pContract.getBalance(msg.sender) > 0,
            "Energy status is less than zero"
        );
        uint balance = p2pContract.getBalance(msg.sender);
        require(balance > 0, "Insufficient funds"); 
        p2pContract.transfer(payable(msg.sender), balance); 
    }

    // An internal function to add an order to the market. It adds the order to the order mapping,
    // pushes the address of the order to the markets array, and updates the total energy of the market.
    function addorder(address _addr, int256 _amount) internal {
        order[_addr] = _amount; 
        markets.push(_addr); 
        total_energy += _amount; 
    }

    // An internal function to remove an order from the market. It updates the balances and energy status of the involved parties,
    // removes the order from the order mapping if it is completely filled, and updates the total energy of the market.
    // It handles both buy and sell orders and can supply orders to the market if necessary.
    function removeorder(address _addr, int256 _amount) internal {
        uint index = 0; // Initialize the index variable.

        if (_amount > 0) {
            // Process buy orders
            if (total_energy + _amount > 0) {      
                for (uint i = 0; i < markets.length; i++) {   
                    uint rest_ = uint(   
                        p2pContract.getEnergyStatus(markets[index]) 
                    );
                    int buy_ = -order[markets[index]];   
                    uint buy_uint = uint(buy_); 
                    p2pContract.setEnergyStatus(  
                        markets[index],
                        int(buy_uint + rest_)
                    );
                }
                delete markets; // Clear the markets array.

                uint rest = p2pContract.getBalance(_addr);  
                uint t_ = uint(-total_energy); 
                p2pContract.setBalance(_addr, t_ + rest); 
                order[_addr] = (_amount + total_energy);  
                markets.push(_addr); 
                total_energy = _amount + total_energy; 
            } else {
                // supply some buy orders
                uint rest = p2pContract.getBalance(_addr); 
                uint amount_uint = uint(_amount); 
                p2pContract.setBalance(_addr, amount_uint + rest);  

                while (index < markets.length && _amount > 0) { 
                    if (order[markets[index]] + _amount > 0) {  
                        _amount += order[markets[index]];      
                        total_energy -= order[markets[index]];   
                        uint rest_ = uint(                      
                            p2pContract.getEnergyStatus(markets[index])
                        );
                        int buy_ = -order[markets[index]];       
                        uint buy_uint = uint(buy_);
                        p2pContract.setEnergyStatus(
                            markets[index],
                            int(buy_uint + rest_)
                        );
                        delete order[markets[index]];
                    } else {
                        order[markets[index]] += _amount;
                        uint rest_ = uint(
                            p2pContract.getEnergyStatus(markets[index])
                        );
                        int buy_ = _amount;
                        uint buy_uint = uint(buy_);
                        p2pContract.setEnergyStatus(
                            markets[index],
                            int(buy_uint + rest_)
                        );
                        _amount = 0;
                    }
                    index++;
                }
            }
        } else {
            // deal with sell order
            if (total_energy + _amount < 0) {
                for (uint i = 0; i < markets.length; i++) {
                    uint rest_ = p2pContract.getBalance(markets[index]);
                    int buy_ = order[markets[index]];
                    uint buy_uint = uint(buy_);
                    p2pContract.setBalance(markets[index], buy_uint + rest_);
                }
                delete markets;

                uint rest = uint(p2pContract.getEnergyStatus(_addr));
                uint t_ = uint(total_energy);
                p2pContract.setEnergyStatus(_addr, int(t_ + rest));
                order[_addr] = (_amount + total_energy);
                markets.push(_addr);
                total_energy = _amount + total_energy;
            } else {
                // supply some seller order
                uint rest = uint(p2pContract.getEnergyStatus(_addr));
                uint amount_uint = uint(-_amount);
                p2pContract.setEnergyStatus(_addr, int(amount_uint + rest));

                while (index < markets.length && _amount < 0) {
                    if (order[markets[index]] + _amount < 0) {
                        _amount += order[markets[index]];
                        total_energy -= order[markets[index]];
                        uint rest_ = p2pContract.getBalance(markets[index]);
                        int buy_ = order[markets[index]];
                        uint buy_uint = uint(buy_);
                        p2pContract.setBalance(
                            markets[index],
                            buy_uint + rest_
                        );
                        delete order[markets[index]];
                    } else {
                        order[markets[index]] += _amount;
                        uint rest_ = p2pContract.getBalance(markets[index]);
                        int buy_ = -_amount;
                        uint buy_uint = uint(buy_);
                        p2pContract.setBalance(
                            markets[index],
                            buy_uint + rest_
                        );
                        _amount = 0;
                    }
                    index++;
                }
            }
        }
    }

    // A public function that matches buy and sell orders and updates the order book.
    function matchorder(address _addr, int _buynumber) internal {
        _buynumber = _buynumber * 1 ether;
        if (total_energy > 0) {
            if (_buynumber > 0) {
                addorder(_addr, _buynumber);
            } else {
                removeorder(_addr, _buynumber);
            }
        } else {
            if (_buynumber > 0) {
                removeorder(_addr, _buynumber);
            } else {
                addorder(_addr, _buynumber);
            }
        }
    }

    // A public function that returns the total energy of the smart contract.
    function getTotalEnergy() public view returns (int) {
        return total_energy;
    }
}