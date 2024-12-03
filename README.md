# **MyFirst NFT Marketplace**

**MyFirst NFT Marketplace** is a smart contract-based application built using **Solidity** and the **Foundry** toolkit. It provides a decentralized platform for creating, buying, selling, and auctioning NFTs. Designed with a focus on efficiency and security, this project leverages the powerful features of Foundry to streamline development and testing.

---

## **Features**

This NFT marketplace supports the following functionalities:  

- **Mint:** Create new NFTs with ease.  
- **Buy:** Instantly purchase available NFTs.  
- **Sale:** List NFTs for sale with a defined price.  
- **Auction:** Start an auction to sell NFTs to the highest bidder.  
- **Bid:** Place bids during an auction.  
- **Cancel Auction:** Cancel active auctions and retain ownership of the NFT.  
- **Stop Auction:** End an auction early, settling it with the current highest bidder.  

---

## **Built With**

The project uses **Foundry**, a modular toolkit for Ethereum application development written in Rust. Foundry consists of:  

- **Forge:** A testing framework for Ethereum smart contracts, similar to Truffle and Hardhat.  
- **Cast:** A versatile command-line tool for interacting with EVM contracts, sending transactions, and retrieving chain data.  
- **Anvil:** A local Ethereum development node, equivalent to Ganache or Hardhat Network.  
- **Chisel:** A fast Solidity REPL for rapid testing and exploration.

---

## **Getting Started**

### Prerequisites

Ensure you have the following installed:
- **Foundry**: Install via [Foundry Book](https://book.getfoundry.sh/getting-started/installation.html).  
- **Rust**: Required for Foundry. Download from [rust-lang.org](https://www.rust-lang.org/).  
- **Node.js** and **npm**: For tooling setup.

---

## **Usage**

### Build the Project

```bash
forge build
```

### Run Tests

```bash
forge test
```

### Format Code

```bash
forge fmt
```

### Generate Gas Snapshots

```bash
forge snapshot
```

### Start Local Node with Anvil

```bash
anvil
```

### Deploy Contracts

Replace `<your_rpc_url>` and `<your_private_key>` with your details:

```bash
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Use Cast

Explore Foundry’s versatile command-line tool:

```bash
cast <subcommand>
```

### Get Help

```bash
forge --help
anvil --help
cast --help
```

---

## **Documentation**

For detailed documentation on Foundry, visit [Foundry Book](https://book.getfoundry.sh/).

---

## **Contributing**

Contributions are welcome! To contribute:  

1. Fork the repository.  
2. Create a new branch (`git checkout -b feature-name`).  
3. Commit your changes (`git commit -m 'Add feature'`).  
4. Push to the branch (`git push origin feature-name`).  
5. Open a Pull Request.  

---

