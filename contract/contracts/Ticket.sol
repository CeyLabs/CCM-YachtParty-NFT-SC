// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; //for USDC/USDT mints

contract Ticket is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 50;
    uint256 public constant PRICE_PER_TOKEN = 0.03 ether;
    uint256 public constant PRICE_PER_TOKEN_USD = 1; // change to 100 * 1**6

    IERC20 public usdc;
    IERC20 public usdt;
    uint256 priceInWei = 1 * 10 ** 6;

    mapping(address => bool) private _allowList;

    constructor(
        address _usdcAddress,
        address _usdtAddress
    ) ERC721("Ticket", "TICKET") {
        usdc = IERC20(_usdcAddress);
        usdt = IERC20(_usdtAddress);
    }

    // USDC ETH SEPOLA ->	0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
    // USDC ETH SEPOLA ->	0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0

    //Whitelist
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(
        address[] calldata addresses,
        bool isAllowed
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = isAllowed;
        }
    }

    function isAddressAllowed(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    //Whitelist Mint
    function mintAllowListWithETH() external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to mint");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            PRICE_PER_TOKEN <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, ts);
    }

    function mintAllowListWithUSDC(uint8 numberOfTokens) external {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to mint");

        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        uint256 totalCost = PRICE_PER_TOKEN_USD * numberOfTokens;
        require(
            usdc.transferFrom(msg.sender, address(this), totalCost),
            "USDC transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    function mintAllowListWithUSDT(uint8 numberOfTokens) external {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to mint");

        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        uint256 totalCost = PRICE_PER_TOKEN_USD * numberOfTokens;
        require(
            usdt.transferFrom(msg.sender, address(this), totalCost),
            "USDT transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    // Public mint with ETH
    function mintWithETH() public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(
            PRICE_PER_TOKEN <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, ts);
    }

    // Public mint with USDC
    function mintWithUSDC() external {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        uint256 totalCost = PRICE_PER_TOKEN_USD;
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
        uint256 totalCost = PRICE_PER_TOKEN_USD;
        require(
            usdt.transferFrom(msg.sender, address(this), totalCost),
            "USDT transfer failed"
        );

        _safeMint(msg.sender, ts);
    }

    //Withdraw Balance
    function withdrawETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawUSDC() public onlyOwner {
        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    }

    function withdrawUSDT() public onlyOwner {
        usdt.transfer(msg.sender, usdt.balanceOf(address(this)));
    }
}
