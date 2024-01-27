const { ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

async function main() {
    // Your Infura project ID (or other provider URL)
    const providerUrl = process.env.SEPOLIA_RPC_URL;

    // Initialize provider using Ethers and Infura
    const provider = new ethers.JsonRpcProvider(providerUrl);

    // Private key of the account signing the data
    const privateKey = process.env.PRIVATE_KEY;

    // Wallet connected to provider
    const wallet = new ethers.Wallet(privateKey, provider);

    // Data to be signed
    const dataToSign = '12';
    const hashedDataToSign = ethers.solidityPackedKeccak256(["string"], [dataToSign]);

    // Generate the signature
    const signature = await wallet.signMessage(ethers.getBytes(hashedDataToSign));

    console.log(signature)
    // Split the signature into r, s, and v components
    const r = '0x' + signature.slice(2, 66);
    const s = '0x' + signature.slice(66, 130);
    const v = parseInt(signature.slice(130, 132), 16);

    // Print the signature components
    console.log(`message ${hashedDataToSign}`);
    console.log(`r: ${r}`);
    console.log(`s: ${s}`);
    console.log(`v: ${v}`);
    if (network.config.chainId == 31337) {
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
