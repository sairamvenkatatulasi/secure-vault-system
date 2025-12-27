const hre = require("hardhat");

async function main() {
    console.log("Deploying Authorization Manager...");
    const AuthorizationManager = await hre.ethers.getContractFactory("AuthorizationManager");
    const authManager = await AuthorizationManager.deploy();
    await authManager.deployed();
    console.log("AuthorizationManager deployed to:", authManager.address);

    console.log("Deploying Secure Vault...");
    const SecureVault = await hre.ethers.getContractFactory("SecureVault");
    const vault = await SecureVault.deploy(authManager.address);
    await vault.deployed();
    console.log("SecureVault deployed to:", vault.address);

    console.log("\n=== Deployment Summary ===");
    console.log("AuthorizationManager:", authManager.address);
    console.log("SecureVault:", vault.address);
    console.log("Network:", (await hre.ethers.provider.getNetwork()).name);
    console.log("ChainId:", (await hre.ethers.provider.getNetwork()).chainId);

    return { authManager: authManager.address, vault: vault.address };
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
