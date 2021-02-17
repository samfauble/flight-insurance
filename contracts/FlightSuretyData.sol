pragma solidity ^0.6.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address payable private contractOwner;                                      // Account used to deploy contract
    bool public operational = true;                                    // Blocks all state changes throughout the contract if false

    struct Insuree {
        address insuree;
        uint256 amountInsured;
        uint256 credited;
    }
    mapping(address => Insuree) insurees;

    uint256 private airlineFund = 0;
    mapping(address => uint256) registeredAirlines;
    address[] public fundedAirlines;
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
        require(operational == true, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(address airline) external requireIsOperational {
        registeredAirlines[airline] = 0;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy() external payable requireIsOperational {
        require(msg.value > msg.sender.balance, "Insufficient funds");
        require(msg.value <= 1 ether, "Limit of 1 either for insurance");

        msg.sender.balance.sub(msg.value);
        airlineFund.add(msg.value);

        insurees[msg.sender].insuree = msg.sender;
        insurees[msg.sender].amountInsured = msg.value;
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(address[] memory passengers) external requireIsOperational {
        for(uint48 i = 0; i < passengers.length; i++) {
            
            address passenger = passengers[i];
            uint256 returnVal = 15;
            if(insurees[passenger].amountInsured > 0) {
                insurees[passenger].credited += (insurees[passenger].amountInsured.mul(returnVal / 10));
            }
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay() external requireIsOperational {
        require(insurees[msg.sender].credited > 0, "No credit found");
        uint256 toTransfer = insurees[msg.sender].credited;

        insurees[msg.sender].credited = 0;
        airlineFund.sub(toTransfer);
        msg.sender.transfer(toTransfer);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund() public payable requireIsOperational {
        require(registeredAirlines[msg.sender] >= 0, "Airline not registered");
        require(msg.value >= 10 ether, "At least 10 ether is required to participate.");
        
        msg.sender.balance.sub(msg.value);
        contractOwner.transfer(msg.value);

        airlineFund.add(msg.value);
        fundedAirlines.push(msg.sender);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() external  payable requireIsOperational {
        fund();
    }

    function isAirline(address airline) external view returns(bool) {
        if (registeredAirlines[airline] > 0) {
            return true;
        } else {
            return false;
        }
    }
}

