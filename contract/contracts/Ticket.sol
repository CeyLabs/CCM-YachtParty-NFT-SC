// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/IERC20.sol";

contract Ticket is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public publicSaleActive = false;
    string private _baseTokenURI;

    // 0 for virtual, 1 for physical
    mapping(uint256 => uint256) public tokenTicketTypes;

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
        _stablecoins["USDT"] = IERC20(_usdtAddress);
        _stablecoins["USDC"] = IERC20(_usdcAddress);
    }

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

    function enforceValidMintAsset(string memory mintAsset) private pure returns (bool) {
        bool stablecoinPayment = keccak256(bytes(mintAsset)) == keccak256(bytes("USDC")) || keccak256(bytes(mintAsset)) == keccak256(bytes("USDT"));
        bool ethPayment = keccak256(bytes(mintAsset)) == keccak256(bytes("ETH"));

        require(stablecoinPayment || ethPayment, "Invalid asset");

        return ethPayment;
    }

    function ticketTypeOf(uint256 tokenId) public view returns (string memory) {
        if(tokenTicketTypes[tokenId] == 0) {
            return "Virtual";
        } else {
            return "Physical";
        }
    } 

    // Discounted Mint
    function mintToken(string memory mintAsset, bool isDiscounted, bool isAllowed, bool isPublic, bool isVirtual) public payable {
        require(publicSaleActive, "Sale is not active");

        bool ethPayment = enforceValidMintAsset(mintAsset);

        require(isDiscounted || isAllowed || isPublic, "Must be allowed, discounted or public");

        uint256 ethPaymentRequired;
        uint256 usdPaymentRequired;

        uint256 ts = totalSupply();

        // Figure out the amounts need to be paid
        if(isVirtual) {
            tokenTicketTypes[ts] = 0;

            if(isDiscounted) {
                require(_discountList[msg.sender], "Address not allowed to mint");
            }

            if(ethPayment) {
                ethPaymentRequired = ETH_PRICE_PER_TOKEN_DISCOUNTED;
            } else {
                usdPaymentRequired = USD_PRICE_PER_TOKEN_DISCOUNTED;
            }
        } else {
            require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");

            tokenTicketTypes[ts] = 1;

            if(ethPayment) {
                ethPaymentRequired = ETH_PRICE_PER_TOKEN;
            } else {
                usdPaymentRequired = USD_PRICE_PER_TOKEN;
            }
        }

        // Take payments
        if(ethPayment) {
            require(ethPaymentRequired <= msg.value, "Ether value sent is not correct");
        } else {
            require(
                _stablecoins[mintAsset].transferFrom(
                    msg.sender,
                    address(this),
                    usdPaymentRequired
                ),
                "Stablecoin transfer failed"
            );
        }

        if(isAllowed && isAllowListActive) {
            require(_allowList[msg.sender], "Address not allowed to mint");
        }
        
        _safeMint(msg.sender, ts);
    }

    // Pre-mint n number of tokens into the owner's wallet
    function mintToAddress(uint256 n, bool isVirtual) public onlyOwner {
        uint ts = totalSupply();
        for (uint i = 0; i < n; i++) {
            uint tokenId = ts + i;
            if (isVirtual) {
                tokenTicketTypes[tokenId] = 0;
            } else {
                tokenTicketTypes[tokenId] = 1;
            }
            _safeMint(msg.sender, tokenId);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
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