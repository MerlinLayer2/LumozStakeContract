const { expect} = require('chai');
const { ethers } = require("hardhat");


describe("Test LumozStake Contract", function () {
    async function deployFixture() {
        const [owner, addr1] = await ethers.getSigners();

        const erc20CapAmount = BigInt("1000000000000000000000000000"); // 1e27 1G
        const approveAmount = BigInt("1000000000000000000000000"); //1e24 1M
        const stakeAmount = BigInt("1000000000000000000") //1e18 1

        const ERC20TokenWrapped = await ethers.getContractFactory("ERC20TokenWrapped", owner);
        const Merl = await ERC20TokenWrapped.deploy("MERL", "MERL", 18, erc20CapAmount);

        const LumozStakeContract = await ethers.getContractFactory("LumozStake", owner);
        const LumozStake = await LumozStakeContract.deploy();
        await LumozStake.initialize(owner, Merl);

        return {owner, addr1, Merl, LumozStake: LumozStake, approveAmount, stakeAmount};
    }

    describe('deployment', function () {
        it('should set the right owner', async function () {
            const {LumozStake, owner} = await deployFixture();
            expect(await LumozStake.owner()).to.equal(owner.address);
        });
    });

    describe('stake', function () {
        it('should stake merl successful', async function () {
            const {Merl, LumozStake, owner, approveAmount, stakeAmount} = await deployFixture();

            await Merl.connect(owner).approve(LumozStake, approveAmount);
            await Merl.connect(owner).mint(owner, stakeAmount);

            const stakeMerlHash = await LumozStake.connect(owner).stake(stakeAmount);
            stakeMerlHash.wait()

            let stake = await LumozStake.connect(owner).accountToStake(owner.address)
            let amount = stake[1];
            console.log("stake, amount = ", stake, amount);

            expect(BigInt(amount)).to.equal(stakeAmount);
        });
    });

    describe('unstake', function () {
        it('should unstake merl successful', async function () {
            const {Merl, LumozStake, owner, approveAmount, stakeAmount} = await deployFixture();

            await Merl.connect(owner).approve(LumozStake, approveAmount);
            await Merl.connect(owner).mint(owner, stakeAmount);

            await LumozStake.connect(owner).stake(stakeAmount);
            const beforeBalance = await Merl.connect(owner).balanceOf(owner.address);
            console.log("beforeBalance = ", beforeBalance);

            const unstakeMerlHash = await LumozStake.connect(owner).unstake(stakeAmount, false);
            unstakeMerlHash.wait()
            const afterBalance = await Merl.connect(owner).balanceOf(owner.address);
            console.log("afterBalance = ", afterBalance)

            expect(BigInt(beforeBalance)).to.equal(BigInt(afterBalance)-stakeAmount);
        });
    });
})
