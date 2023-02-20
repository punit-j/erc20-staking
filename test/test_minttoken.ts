import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("XWeowms - mintTokens", function () {

    var xWeowms: Contract;
    var eRC20: Contract;

    beforeEach(async function () {
        const ERC20 = await ethers.getContractFactory("ERC20");
        eRC20 = await ERC20.deploy();
        await eRC20.deployed();
        const XWeowms = await ethers.getContractFactory("XWeowms");
        xWeowms = await XWeowms.deploy();
        await xWeowms.initialize(eRC20.address)
        await xWeowms.deployed();
    });

    it("Happy Flow for MintTokens", async function () {
        const accs = await ethers.getSigners();
        const [deployer] = await ethers.getSigners();
        const deployer2 = accs[2]

        await eRC20.mint(deployer.address,1000000000000)
        await eRC20.approve(xWeowms.address,1000000000)
        await xWeowms.mintToken(deployer.address,1000000)

        // minted tokens should be 96% of 1000000
        expect(await xWeowms.balanceOf(deployer.address)).to.equal(999360)
        // remaining tokens should be 1000000000000 - 282 * 1000000
        expect(await eRC20.balanceOf(deployer.address)).to.equal(999718000000)

        await eRC20.connect(deployer2).mint(deployer2.address,1000000000000)
        await eRC20.connect(deployer2).approve(xWeowms.address,1000000000)
        await xWeowms.connect(deployer2).mintToken(deployer2.address,1000000)

        expect(await xWeowms.connect(deployer2).balanceOf(deployer2.address)).to.equal(979365)
        
        expect(await eRC20.balanceOf(deployer2.address)).to.equal(999718000000)

        // increated due to 4% received by minting of deployer2
        expect(await xWeowms.balanceOf(deployer.address)).to.equal(1019520)

    });

});     



