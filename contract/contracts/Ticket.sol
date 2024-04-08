// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/IERC20.sol";

contract Ticket is ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 50;
    uint256 public ETH_PRICE_PER_TOKEN = 0.03 ether;
    uint256 public ETH_PRICE_PER_TOKEN_DISCOUNTED = 0.0225 ether;
    uint256 public USD_PRICE_PER_TOKEN = 100 * 10 ** 6;
    uint256 public USD_PRICE_PER_TOKEN_DISCOUNTED = 75 * 10 ** 6;
    IERC20 public usdc;
    IERC20 public usdt;

    mapping(address => bool) private _allowList;
    mapping(address => bool) private _discountList;

    constructor(
        address _usdcAddress,
        address _usdtAddress
    ) ERC721("Ticket", "TICKET") {
        usdc = IERC20(_usdcAddress);
        usdt = IERC20(_usdtAddress);
    }

    // USDC ETH SEPOLA ->	0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
    // USDT ETH SEPOLA ->	0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0

    // Toggle whitelist allow status
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    // Set new eth mint price
    function setPrice(uint256 _ethPricePerToken) external onlyOwner {
        ETH_PRICE_PER_TOKEN = _ethPricePerToken;
    }

    function setAllowList(
        address[] calldata addresses,
        bool isAllowed
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = isAllowed;
        }
    }

    function setDiscountList(
        address[] calldata addresses,
        bool isDiscounted
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _discountList[addresses[i]] = isDiscounted;
        }
    }

    // Check if an address is included in allowed list
    function isAddressAllowed(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    // Check if an address is included in discount list
    function isAddressDiscounted(address addr) external view returns (bool) {
        return _discountList[addr];
    }

    // Discounted Mint
    function mintDiscountedWithETH() external payable {
        uint256 ts = totalSupply();
        require(_discountList[msg.sender], "Address not allowed to mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            ETH_PRICE_PER_TOKEN_DISCOUNTED <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, ts);
    }

    function mintDiscountedWithUSDC() external {
        uint256 ts = totalSupply();
        require(_discountList[msg.sender], "Address not allowed to mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            usdc.transferFrom(
                msg.sender,
                address(this),
                USD_PRICE_PER_TOKEN_DISCOUNTED
            ),
            "USDC transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    function mintDiscountedWithUSDT() external {
        uint256 ts = totalSupply();
        require(_discountList[msg.sender], "Address not allowed to mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            usdt.transferFrom(
                msg.sender,
                address(this),
                USD_PRICE_PER_TOKEN_DISCOUNTED
            ),
            "USDT transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    //Whitelist Mint
    function mintAllowedWithETH() external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            ETH_PRICE_PER_TOKEN <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, ts);
    }

    function mintAllowedWithUSDC() external {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            usdc.transferFrom(msg.sender, address(this), USD_PRICE_PER_TOKEN),
            "USDC transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    function mintAllowedWithUSDT() external {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            usdt.transferFrom(msg.sender, address(this), USD_PRICE_PER_TOKEN),
            "USDT transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    // Pre-mint n number of tokens into the owner's wallet
    function reserve(uint256 n) public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // Toggle the sale state
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    // Public mint with ETH
    function mintWithETH() public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            ETH_PRICE_PER_TOKEN <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, ts);
    }

    // Public mint with USDC
    function mintWithUSDC() external {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        uint256 totalCost = USD_PRICE_PER_TOKEN;
        require(
            usdc.transferFrom(msg.sender, address(this), totalCost),
            "USDC transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    // Public mint with USDT
    function mintWithUSDT() external {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        uint256 totalCost = USD_PRICE_PER_TOKEN;
        require(
            usdt.transferFrom(msg.sender, address(this), totalCost),
            "USDT transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    // Mint a token to a given address
    function mintToAddress(address to) public onlyOwner {
        uint256 ts = totalSupply();
        require(ts + 1 <= MAX_SUPPLY, "Minting would exceed max supply");

        _safeMint(to, ts);
    }

    // Withdraw ETH balance in the contract
    function withdrawETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Withdraw USDC balance in the contract
    function withdrawUSDC() public onlyOwner {
        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    }

    // Withdraw USDT balance in the contract
    function withdrawUSDT() public onlyOwner {
        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
    }
}