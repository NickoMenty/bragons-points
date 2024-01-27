const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

let SignatureVerification, SignatureVerificationAddress, SignatureVerificationInstance

const R = "0xaa7ea37e2508a8ae58e252c44c939fc7dc850835f9dad1fdc4f91fd00992951f"
const S = "0x0cf79b0a99be111cd5abffefc8477a1fea121e1d9902585f353d7fd033d30126"
const V = "28"

async function VerifySignature() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    SignatureVerification = await deployments.get("SignatureVerification")
    SignatureVerificationAddress = SignatureVerification.address
    SignatureVerificationInstance = await ethers.getContractAt(
        "SignatureVerification",
        SignatureVerificationAddress,
        signer,
    )
    console.log(`checking....`)
    const Tx = await SignatureVerificationInstance.verifySignature(R,S,V)
    console.log(Tx)
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

VerifySignature()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
