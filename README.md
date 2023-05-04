# Blockchain

P2P smart contract

(a) A structure to store information of prosumers. The information must include a prosumer's ID (address), 
energy status (how much energy it needs to buy or sell), and balance (Ethers in smart wallet). You can also add more information as per requirements. 
Note that the data of buyers and sellers should not be stored separately, it should be stored in the same structure named prosumer". 
The data related to prosumers will only be stored in P2P smart contract. No more than one struct shall be used to store information.
(You can create queues for sellers and buyers (just their addresses not details). The queues will be used for the reference purpose only.)

(b) A function to register a new prosumer (add information of a new prosumer). Initially, only address of the user is added as its ID.

(c) Add functions to buy and sell energy.


Main smart contract

(a) Modifier function to make sure a prosumer is registered in the system before sending any request.

(b) Modifier function to ensure single registration of a prosumer (if an already registered prosumer request for the registration again, 
the function should send an error message saying the user is already registered).

(c) A modifier function to check whether a buyer has deposited sufficient funds (Ethers required to purchase the required amount of energy) 
to buy energy in the smart wallet.

(d) A public function to register a prosumer. A prosumer only calls this function to get registered (prosumer does not pass any value).
The function checks (using the modifier function) the prior registration of the prosumers. If prosumer is already registered, 
the error message is generated (by the modifier function) to show that prosumer is already registered; otherwise the address of the new
prosumer is sent to the P2P smart contract for storage (registration).

(e) A public function to enable a buyer to deposit some Ethers prior to energy buying request. The prosumer dose not pass any value to the function.

(f) A public function to accept prosumers' requests and check if a prosumer has sent an energy selling or buying request and pass the data to the P2P smart contract. 
A prosumer passes positive value if he is a seller and negative value if he is a buyer. For example, if a buyer needs 3 units of energy, he will send -3 as input. 
The negative sign shows that the buyer needs the energy. On the contrary, if a seller wants to 3 units of energy, it will send 3 as an input. 
The positive 3 shows that the user has surplus energy to sell.

(g) A public function to check the current energy status of a seller or buyer (the amount of energy a buyer wants to buy or a seller wants to sell). 
The function should not have any input arguments.

(h) A public function to check the balance of a prosumer. The function should not have any input arguments.

(i) A public function to withdraw the Ethers from smart wallets of prosumers. The function should not have any input arguments.
(Note: funds can be withdrawn for a prosumer if his energy status is greater than or equal to zero, which means the prosumer does not need to buy energy at the moment.)
