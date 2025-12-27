const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Secure Vault System", () => {
    let authManager, vault, owner, recipient;

    beforeEach(async () => {
        [owner, recipient] = await ethers.getSigners();
        const AuthorizationManager = await ethers.getContractFactory("AuthorizationManager");
        authManager = await AuthorizationManager.deploy();
        await authManager.deployed();
        const SecureVault = await ethers.getContractFactory("SecureVault");
        vault = await SecureVault.deploy(authManager.address);
        await vault.deployed();
    });

    it("Should accept deposits", async () => {
        const amount = ethers.utils.parseEther("1.0");
        await owner.sendTransaction({ to: vault.address, value: amount });
        const balance = await vault.getVaultBalance();
        expect(balance).to.equal(amount);
    });

    it("Should allow authorized withdrawals", async () => {
        const amount = ethers.utils.parseEther("1.0");
        await owner.sendTransaction({ to: vault.address, value: amount });
        const authId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("auth1"));
        const chainId = (await ethers.provider.getNetwork()).chainId;
        const messageHash = ethers.utils.keccak256(
            ethers.utils.solidityPack(
                ["address", "address", "uint256", "bytes32", "uint256"],
                [vault.address, recipient.address, amount, authId, chainId]
            )
        );
        const signature = await owner.signMessage(ethers.utils.arrayify(messageHash));
        await vault.withdraw(recipient.address, amount, authId, signature);
        const finalBalance = await vault.getVaultBalance();
        expect(finalBalance).to.equal(0);
    });

    it("Should reject reused authorizations", async () => {
        const amount = ethers.utils.parseEther("1.0");
        await owner.sendTransaction({ to: vault.address, value: amount });
        const authId = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("auth2"));
        const chainId = (await ethers.provider.getNetwork()).chainId;
        const messageHash = ethers.utils.keccak256(
            ethers.utils.solidityPack(
                ["address", "address", "uint256", "bytes32", "uint256"],
                [vault.address, recipient.address, amount, authId, chainId]
            )
        );
        const signature = await owner.signMessage(ethers.utils.arrayify(messageHash));
        await vault.withdraw(recipient.address, amount, authId, signature);
        await expect(
            vault.withdraw(recipient.address, amount, authId, signature)
        ).to.be.revertedWith("Authorization already used");
    });
});
