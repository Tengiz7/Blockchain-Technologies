// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Splitwise {
    struct MoneyRequest {
        address from;
        address to;
        uint256 amount;
        bool paid;
    }

    MoneyRequest[] public moneyRequests;

    function submitMoneyRequest(address to, uint256 amount) public returns (uint256) {
        require(amount > 0, "Require more than 0");
        uint256 requestId = moneyRequests.length;
        moneyRequests.push(MoneyRequest(msg.sender, to, amount, false));
        return requestId;
    }

    function payForRequestedAmount(uint256 requestId) public payable {
        require(requestId < moneyRequests.length, "Invalid request ID");
        MoneyRequest storage request = moneyRequests[requestId];
        require(!request.paid, "Request already paid amount");
        uint256 amountToPay = request.amount;
        require(msg.value >= amountToPay, "Not enough");
        request.paid = true;
        payable(request.to).transfer(amountToPay);
    }

    function getAllMoneyRequests() public view returns (MoneyRequest[] memory)  {
        return moneyRequests;
    }

    function splitTheBill(uint256 totalAmount, address[] memory addresses) public {
        require(totalAmount % addresses.length == 0);
        for (uint i = 0; i < addresses.length; i++){
            submitMoneyRequest(addresses[i], totalAmount/addresses.length);
        }
    }

    function rejectMoneyRequest(uint256 id) public {
        require(id <= moneyRequests.length, "Require valid id");
        require(moneyRequests[id].to == msg.sender);
        moneyRequests[id].paid = true;
    }

    function cancelMoneyRequest(uint256 id) public {
        require(id <= moneyRequests.length, "Require valid id");
        require(moneyRequests[id].from == msg.sender);
        moneyRequests[id].paid = true;
    }

    function payToAddress(address recipient) public payable {
        uint256 totalAmountPaid = 0;

        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.from == recipient && !request.paid) {
                require(msg.value >= request.amount, "Insufficient payment");
                request.paid = true;
                totalAmountPaid += request.amount;
                payable(request.from).transfer(request.amount);
            }
        }
    }

    function payForAllTheRequests() public payable {
        uint256 totalAmountPaid = 0;

        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.to == msg.sender && !request.paid) {
                request.paid = true;
                totalAmountPaid += request.amount;
                payable(request.from).transfer(request.amount);
            }
        }

    }
    function isInArray(address[] memory addresses, address value) private pure returns (bool){
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == value) {
                return true;
            }
        }
        return false;
    }
    function getParticipatingAddresses() public view returns (address[] memory) {
        address[] memory addresses = new address[](moneyRequests.length * 2);
        uint256 count = 0;

        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (!isInArray(addresses, request.from)) {
                addresses[count] = request.from;
                count++;
            }
            if (!isInArray(addresses, request.to)) {
                addresses[count] = request.to;
                count++;
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = addresses[i];
        }

        return result;
    }

    function getSentRequests() public view returns (MoneyRequest[] memory) {
        uint256 count = 0;

        for (uint256 i = 0; i < moneyRequests.length; i++) {
            if (moneyRequests[i].from == msg.sender) {
                count++;
            }
        }
        MoneyRequest[] memory sentRequests = new MoneyRequest[](count);
        for (uint256 i = 0; i < moneyRequests.length; i++) {
            if (moneyRequests[i].from == msg.sender) {
                sentRequests[i] = moneyRequests[i];
            }
        }
        return sentRequests;
    }

    function getReceivedRequests() public view returns (MoneyRequest[] memory) {
        uint256 count = 0;

        for (uint256 i = 0; i < moneyRequests.length; i++) {
            if (moneyRequests[i].to == msg.sender) {
                count++;
            }
        }
        MoneyRequest[] memory receivedRequests = new MoneyRequest[](count);
        for (uint256 i = 0; i < moneyRequests.length; i++) {
            if (moneyRequests[i].to == msg.sender) {
                receivedRequests[i] = moneyRequests[i];
            }
        }
        return receivedRequests;
    }

    function getAllCreditors() public view returns (address[] memory) {
        address[] memory creditors = new address[](moneyRequests.length);
        uint256 count = 0;

        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.to == msg.sender && !request.paid) {
                bool exists = false;
                for (uint256 j = 0; j < count; j++) {
                    if (creditors[j] == request.from) {
                        exists = true;
                        break;
                    }
                }
                if (!exists) {
                    creditors[count] = request.from;
                    count++;
                }
            }
        }
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = creditors[i];
        }
        return result;
    }

    function getAllDebtors() public view returns (address[] memory) {
        address[] memory debtors = new address[](moneyRequests.length);
        uint256 count = 0;

        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.from == msg.sender && !request.paid) {
                bool exists = false;
                for (uint256 j = 0; j < count; j++) {
                    if (debtors[j] == request.to) {
                        exists = true;
                        break;
                    }
                }
                if (!exists) {
                    debtors[count] = request.to;
                    count++;
                }
            }
        }
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = debtors[i];
        }
        return result;
    }

    function getTotalAmountOwed() public view returns (uint256) {
        uint256 totalAmountOwed = 0;
        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.to == msg.sender && !request.paid) {
                totalAmountOwed += request.amount;
            }
        }
        return totalAmountOwed;
    }

    function getTotalAmountRequested() public view returns (uint256) {
        uint256 totalAmountRequested = 0;
        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.from == msg.sender && !request.paid) {
                totalAmountRequested += request.amount;
            }
        }
        return totalAmountRequested;
    }

    function getAmountOwedTo(address debtor) public view returns (uint256) {
        uint256 amountOwed = 0;
        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.to == msg.sender && request.from == debtor && !request.paid) {
                amountOwed += request.amount;
            }
        }
        return amountOwed;
    }

    function getAmountRequestedFrom(address creditor) public view returns (uint256) {
        uint256 amountRequested = 0;
        for (uint256 i = 0; i < moneyRequests.length; i++) {
            MoneyRequest storage request = moneyRequests[i];
            if (request.from == msg.sender && request.to == creditor && !request.paid) {
                amountRequested += request.amount;
            }
        }
        return amountRequested;
    }
}

