// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/IERC20.sol";

contract Ticket is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public publicSaleActive = false;
    string private _baseURIextended;

    uint256[] virtualTokenIds;
    uint256[] physicalTokenIds;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 50;
    uint256 public ETH_PRICE_PER_TOKEN = 0.03 ether;
    uint256 public ETH_PRICE_PER_TOKEN_DISCOUNTED = 0.0225 ether;
    uint256 public USD_PRICE_PER_TOKEN = 100 * 10 ** 6;
    uint256 public USD_PRICE_PER_TOKEN_DISCOUNTED = 75 * 10 ** 6;

    mapping(address => bool) private _allowList;
    mapping(address => bool) private _discountList;

    mapping(string => IERC20) private _stablecoins;

    constructor(
        address _usdcAddress,
        address _usdtAddress
    ) ERC721("Ticket", "TICKET") {
        _stablecoins["usdt"] = IERC20(_usdtAddress);
        _stablecoins["usdc"] = IERC20(_usdcAddress);
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

    function enforceValidMintAsset(string memory mintAsset) internal pure returns (bool) {
        bool stablecoinPayment = mintAsset == "usdc" || mintAsset == "usdt";
        bool ethPayment = mintAsset == "eth";

        require(stablecoinPayment || ethPayment, "Invalid asset");

        return ethPayment;
    }

    // Discounted Mint
    function mintToken(string memory mintAsset, bool isDiscounted, bool isAllowed) external payable {
        bool ethPayment = enforceValidMintAsset(mintAsset);

        require(isDiscounted || isAllowed, "Must be allowed or discounted");

        uint256 ethPaymentRequired;
        uint256 usdPaymentRequired;

        // Figure out the amounts need to be paid
        if(isDiscounted) {
            require(_discountList[msg.sender], "Address not allowed to mint");

            if(ethPayment) {
                ethPaymentRequired = ETH_PRICE_PER_TOKEN_DISCOUNTED;
            } else {
                usdPaymentRequired = USD_PRICE_PER_TOKEN_DISCOUNTED;
            }
        } else {
            if(ethPayment) {
                ethPaymentRequired = ETH_PRICE_PER_TOKEN;
            } else {
                usdPaymentRequired = USD_PRICE_PER_TOKEN;
            }
        }

        // Take payments
        if(ethPayment) {
            require(ETH_PRICE_PER_TOKEN_DISCOUNTED <= msg.value, "Ether value sent is not correct");
        } else {
            require(
                _stablecoins[mintAsset].transferFrom(
                    msg.sender,
                    address(this),
                    USD_PRICE_PER_TOKEN_DISCOUNTED
                ),
                "Stablecoin transfer failed"
            );
        }

        if(isAllowed && isAllowListActive) {
            require(_allowList[msg.sender], "Address not allowed to mint");
        }

        uint256 ts = totalSupply();
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        _safeMint(msg.sender, ts);
    }

    // Public mint with USDC
    function mintTokenPublic(string memory mintAsset) external {
        bool ethPayment = enforceValidMintAsset(mintAsset);

        uint256 ts = totalSupply();
        require(publicSaleActive, "Public sale is not active");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        
        if(ethPayment) {

        } else {
            require(
                _stablecoins[mintAsset].transferFrom(msg.sender, address(this), USD_PRICE_PER_TOKEN),
                "USDC transfer failed"
            );
        }

        _safeMint(msg.sender, ts);
    }


    // Mint a token to a given address
    function mintToAddress(address to) public onlyOwner {
        uint256 ts = totalSupply();
        require(ts + 1 <= MAX_SUPPLY, "Minting would exceed max supply");

        _safeMint(to, ts);
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
        uint ts = totalSupply();
        require(ts + n <= MAX_SUPPLY, "Minting would exceed max supply");
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // Toggle the sale state
    function togglePublicSaleState() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    // Withdraw USDC balance in the contract
    function withdraw(string memory withdrawAsset) public onlyOwner {
        bool ethPayment = enforceValidMintAsset(withdrawAsset);

        if(ethPayment) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 stablecoin = _stablecoins[withdrawAsset];
            stablecoin.transfer(msg.sender, stablecoin.balanceOf(address(this)));
        }
    }
}