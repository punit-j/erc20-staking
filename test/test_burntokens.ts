import { expect } from "chai"
import { Contract } from "ethers";
import { ethers } from "hardhat"

describe("XWeowms - burnTokens", function () {

    var xWeowms: Contract
    var eRC20: Contract

    beforeEach(async function () {
        const ERC20 = await ethers.getContractFactory("ERC20")
        eRC20 = await ERC20.deploy()
        await eRC20.deployed()
        const XWeowms = await ethers.getContractFactory("XWeowms")
        xWeowms = await XWeowms.deploy()
        await xWeowms.initialize(eRC20.address)
        await xWeowms.deployed()
    });

    it("Happy Flow for BurnTokens", async function () {
        const [deployer] = await ethers.getSigners();

        await eRC20.mint(deployer.address,1000000000000)
        await eRC20.approve(xWeowms.address,1000000000)
        await xWeowms.mintToken(deployer.address,1000000)

        // minted tokens should be 96% of 1000000
        expect(await xWeowms.balanceOf(deployer.address)).to.equal(999360)
        // remaining tokens should be 1000000000000 - 282 * 1000000
        expect(await eRC20.balanceOf(deployer.address)).to.equal(999718000000)

        await xWeowms.burnToken(deployer.address,999360)

        // burned all tokens
        expect(await xWeowms.balanceOf(deployer.address)).to.equal(0)
        // Token balance should increase
        expect(await eRC20.balanceOf(deployer.address)).to.equal(999887091712)       
    });

    it("Check Happy Flow for MintTokens for multiple accounts", async function () {
        const accs = await ethers.getSigners();
        const [deployer] = await ethers.getSigners();
        const deployer2 = accs[2]

        await eRC20.mint(deployer.address,1000000000000)
        await eRC20.approve(xWeowms.address,1000000000)
        await xWeowms.mintToken(deployer.address,1000000)

        // minted tokens should be 96% of 1000000 plus 4%
        expect(await xWeowms.balanceOf(deployer.address)).to.equal(999360)
        // remaining tokens should be 1000000000000 - 282 * 1000000
        expect(await eRC20.balanceOf(deployer.address)).to.equal(999718000000)

        await eRC20.connect(deployer2).mint(deployer2.address,1000000000000)
        await eRC20.connect(deployer2).approve(xWeowms.address,1000000000)
        await xWeowms.connect(deployer2).mintToken(deployer2.address,1000000)
        expect(await xWeowms.connect(deployer2).balanceOf(deployer2.address)).to.equal(979365)
        expect(await eRC20.balanceOf(deployer2.address)).to.equal(999718000000)

        // balance increased in deployer1 due to 4 % given by minting of deployer2 tokens
        expect(await xWeowms.balanceOf(deployer.address)).to.equal(1019520)
        
        // burned all tokens 
        await xWeowms.burnToken(deployer.address,999360)

        // Still some balance left because 
        expect(await xWeowms.balanceOf(deployer.address)).to.equal(28229)

        // Token balance should increase
        expect(await eRC20.balanceOf(deployer.address)).to.equal(999887091712)
    });

});     



