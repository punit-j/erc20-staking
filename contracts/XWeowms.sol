// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./interfaces/IERC20.sol";
import "./Proxy.sol";

contract XWeowms is Storage, IERC20 {
    IERC20 public wUSDT;
    uint256 private constant PEGGED_AMOUNT = 282;
    uint256 public constant INITIAL_LIQUIDATION_INDEX = 100000;
    uint256 public liquidationIndex;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    bool private _isInitialised;

    /**
     * @dev Initialises contract with owner as deployer
     * @param _wUSDTAddress wUSDT token address
     */
    function initialize(address _wUSDTAddress) external {
        require(!_isInitialised);
        wUSDT = IERC20(_wUSDTAddress);
        _isInitialised = true;
        liquidationIndex = INITIAL_LIQUIDATION_INDEX;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return "xWeowns";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return "xWeowns";
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return wUSDT.decimals();
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return (_totalSupply * liquidationIndex) / 100000;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return (_balances[account] * liquidationIndex) / 100000;
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        _allowances[sender][msg.sender] = currentAllowance - amount;
        _transfer(sender, recipient, amount);

        return true;
    }

    function exactPeggedAmount() public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        uint256 valueLocked = wUSDT.balanceOf(address(this));
        uint256 peggedValue = valueLocked / currentSupply;
        return peggedValue;
    }

    /**
     * @dev mints token by locking users wUSDT
     */
    function mintToken(address recipient, uint256 amount)
        public
        returns (bool)
    {
        uint256 amountToLock = amount * PEGGED_AMOUNT;
        wUSDT.transferFrom(recipient, address(this), amountToLock);
        uint256 amountToMint = (amount * 96) / 100;
        _mint(recipient, amountToMint);
        _rebase();
        return true;
    }

    /**
     * @dev burns token and releases locked wUSDT with generating yield for other holders
     */
    function burnToken(address recipient, uint256 amount)
        public
        returns (bool)
    {
        require(msg.sender == recipient || _allowances[recipient][msg.sender] >= amount);
        uint256 amountToBurn = (amount * 60) / 100;
        _burn(recipient, amount);
        uint256 amountToRelease = amountToBurn * PEGGED_AMOUNT;
        wUSDT.transfer(recipient, amountToRelease);
        _rebase();
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0));
        require(recipient != address(0));

        uint256 amountScaled = (amount * 100000) / liquidationIndex;
        require(_balances[sender] >= amountScaled);

        _balances[sender] = _balances[sender] - amountScaled;
        _balances[recipient] += amountScaled;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0));

        uint256 amountToMint = (amount * 100000) / liquidationIndex;
        _totalSupply = _totalSupply + amountToMint;
        _balances[account] = _balances[account] + amountToMint;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0));
        uint256 amountToBurn = (amount * 100000) / liquidationIndex;

        require(_balances[account] >= amountToBurn);

        _balances[account] = _balances[account] - amountToBurn;
        _totalSupply = _totalSupply - amountToBurn;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev rebases balances of users according to the wUSDT locked
     * called after minting and burning token
     */
    function _rebase() internal {
        if (_totalSupply != 0) {
            uint256 realAmountLocked = wUSDT.balanceOf(address(this));
            uint256 intendedAmountLocked = _totalSupply * PEGGED_AMOUNT;
            liquidationIndex = (realAmountLocked * 100000) / intendedAmountLocked;
        }
    }
}
