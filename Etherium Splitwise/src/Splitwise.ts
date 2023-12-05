import {MoneyRequest} from "./models";
import {Contract, JsonRpcProvider, Wallet} from "ethers";
import * as fs from "fs";

export class Splitwise {

    private wallet: Wallet;
    private contract: Contract;
    constructor(private contractAddress: string, private signerKey: string) {
        const provider = new JsonRpcProvider('https://rpc.notadegen.com/eth/sepolia');
        this.wallet = new Wallet(signerKey,provider);
        const abi = fs.readFileSync('./contracts/_Splitwise_sol_Splitwise.abi', "utf-8");
        const binary = fs.readFileSync('./contracts/_Splitwise_sol_Splitwise.bin', "utf-8");

        this.contract = new Contract(contractAddress, abi, this.wallet);
    }

    // commands

    /*
        this method submits a money request, which should be saved on a blockchain.
        returns hash of submitted transaction
     */
    public async submitMoneyRequest(to: string, amount: bigint) : Promise<string> {
        return await this.contract.submitMoneyRequest(to, amount);
    }

    /*
        this method is similar to `submitMoneyRequest` but works on multiple addresses and total
        amount if split among those addresses.
        error should be raised if an amount is not evenly divisible on all addresses.
     */
    public async splitTheBill(totalAmount: string, addresses: string[]): Promise<string> {
        let amount = BigInt(totalAmount);

        if (amount % BigInt(addresses.length) != BigInt(0)){
            throw new Error("must be evenly divisible");
        }
        return await this.contract.splitTheBill(BigInt(totalAmount), addresses);
    }

    /*
        this method rejects a specific money request, if the request if sent to the signer.
        Money request should be removed from a storage after rejection.
        method accepts requestId as a parameter, contract should be generating unique request ID
        for each request
     */
    public async rejectMoneyRequest(requestId: bigint) : Promise<string> {
        return await this.contract.rejectMoneyRequest(requestId);
    }

    /*
        this method is mean to revoke your sent money request, Revoked MoneyRequest should also
        be deleted
     */
    public async cancelMoneyRequest(requestId: bigint) : Promise<string> {
        return await this.contract.cancelMoneyRequest(requestId);
    }

    /*
        transfers amount of wei to the requesting party, paid requests should also be deleted from a list of
        incoming and outcoming requests. You probably need to declare corresponding solidity function as payable
     */
    public async payForRequestedAmount(requestId: bigint) : Promise<string> {
        return await this.contract.payForRequestedAmount(requestId);
    }

    /*
        this method pays for a money request by address. if several requests are sent from that address,
        the method should pay from all of them.
     */
    public async payToAddress(address: string): Promise<string> {
        return await this.contract.payToAddress(address);
    }


    /*
        This method should pay from all the incoming requests for the signer.
     */
    public async payForAllTheRequests() : Promise<string> {
        return await this.contract.payForAllTheRequests();
    }

    // queries

    /*
        Fetch all the addresses which received or sent money requests througout the history of a smart contract
     */
    public async getParticipatingAddresses(): Promise<string[]> {
        return await this.contract.getParticipatingAddresses();
    }

    /*
        fetch requests sent by the signer
     */
    public async getSentRequests(): Promise<MoneyRequest[]>{
        const value =  await this.contract.getSentRequests();
        return value.map((request: any) => {
            return {
                requestId: request.id,
                from: request.from,
                to: request.to,
                amount: request.amount,
                paid: request.paid
            }
        });
    }

    /*
        fetch requests sent to the signer by other users.
     */
    public async getReceivedRequests(): Promise<MoneyRequest[]> {
        const value =  await this.contract.getReceivedRequests();
        return value.map((request: any) => {
            return {
                requestId: request.id,
                from: request.from,
                to: request.to,
                amount: request.amount,
                paid: request.paid
            }
        });
    }


    /*
        get all the addresses who have sent money requests to the signer. Payed or Rejected requests
        should not be returned
     */
    public async getAllCreditors(): Promise<string[]> {
        return await this.contract.getAllCreditors();
    }

    /*
        fetch all addresses to whom signer have sent the money requests. This method should return only active
        requests as well.
     */
    public async getAllDebtors(): Promise<string[]> {
        return await this.contract.getAllDebtors();
    }

    /*
        method fetches total amount owed by combining all the incomming active requests' amounts.
     */
    public async getTotalAmountOwed() : Promise<bigint> {
        return await this.contract.getTotalAmountOwed();
    }

    /*
        Fetches total amount requested by the signer from other users
     */
    public async getTotalAmountRequested() : Promise<bigint> {
        return await this.contract.getTotalAmountRequested();
    }

    /*
        gets total amount owed to specific address by signer
     */
    public async getAmountOwedTo(address: string): Promise<bigint> {
        return await this.contract.getAmountOwedTo(address);
    }

    /*
        gets total amount which signer requested from specific address.
     */
    public async getAmountRequestedFrom(address: string): Promise<bigint> {
        return await this.contract.getAmountRequestedFrom(address);
    }

}