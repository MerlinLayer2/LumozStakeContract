// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LumozStake is OwnableUpgradeable {
    string public constant version = "1.0.0";
    uint256 public constant ONE_MERL = 1e18;

    address public merlToken;
    uint256 public totalStakeAmount;
    mapping(address => uint256) public userStakeAmount;

    bool public paused;
    address public pauseAdmin;
    uint256 private _nonReentrantStatus;

    event Stake(
        address msgSender,
        address token,
        uint256 amount
    );

    event Unstake(
        address msgSender,
        address token,
        uint256 amount
    );

    event PauseAdminChanged(
        address adminSetter,
        address oldAddress,
        address newAddress
    );

    event PauseEvent(
        address pauseAdmin,
        bool paused
    );

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Illegal address");
        _;
    }

    modifier nonReentrant() {
        require(_nonReentrantStatus == 0, "ReentrancyGuard: reentrant call");
        _nonReentrantStatus = 1;
        _;
        _nonReentrantStatus = 0;
    }

    constructor() {
        _disableInitializers();
    }

    /**
    * @dev Initialization function
    *
    * - `_initialOwner`：the initial owner is set to the address provided by the deployer. This can
    *      later be changed with {transferOwnership}.
    * - `_signer`: the sign address when you want to rent.
    * - `_rentToken`: spend the rent token to rent.
    */
    function initialize(
        address _initialOwner,
        address _merlToken
    ) external
    onlyValidAddress(_initialOwner)
    onlyValidAddress(_merlToken) initializer {
        merlToken = _merlToken;
        __Ownable_init_unchained(_initialOwner);
    }

    /**
    * @dev Stake Merl: stake merl in contract. we can continuously stake the merl.
    *
    * - `_amount`: stake the merl amount, at least 1 merl.
    *
    * Firstly, we transfer the specified amount from sender to this contract.
    * Finally, we update account's amount and global total amount.
    */
    function stake(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount >= ONE_MERL, "at least 1 MERL");

        address account = msg.sender;
        IERC20(merlToken).transferFrom(account, address(this), _amount);

        userStakeAmount[account] += _amount;
        totalStakeAmount += _amount;

        emit Stake(account, merlToken, _amount);
    }

    //解质押，一次解除所有质押
    /**
    * @dev Unstake merl: unstake merl from contract.
    *
    * Firstly, we transfer the specified amount of merl to this account.
    * And then, we update account's merl and global total merl.
    */
    function unstake() external whenNotPaused nonReentrant {
        address account = msg.sender;
        uint256 amount = userStakeAmount[account];
        require(amount > 0, "account dost not stake");

        IERC20(merlToken).transfer(msg.sender, amount);

        userStakeAmount[account] = 0;
        totalStakeAmount -= amount;

        emit Unstake(account, merlToken, amount);
    }

    //Pause ...
    function setPauseAdmin(address _account) public onlyOwner {
        require(_account != address (0), "invalid _account");
        address oldPauseAdmin = pauseAdmin;
        pauseAdmin = _account;
        emit PauseAdminChanged(msg.sender, oldPauseAdmin, pauseAdmin);
    }

    modifier whenNotPaused() {
        require(!paused, "pause is on");
        _;
    }

    /**
    * @dev Pause the activity, only by pauseAdmin.
    */
    function pause() public whenNotPaused {
        require(msg.sender == pauseAdmin, "Illegal pause permissions");
        paused = true;
        emit PauseEvent(msg.sender, paused);
    }

    /**
    * @dev Unpause the activity, only by owner.
    */
    function unpause() public onlyOwner {
        paused = false;
        emit PauseEvent(msg.sender, paused);
    }
}