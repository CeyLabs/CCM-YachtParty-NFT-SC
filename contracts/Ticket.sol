// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC20/IERC20.sol";

contract Ticket is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Constants
    uint8 public constant MAX_PHYSICAL_SUPPLY = 50;
    uint256 public ETH_PRICE_PER_TOKEN = 0.03 ether;
    uint256 public ETH_PRICE_PER_TOKEN_DISCOUNTED = 0.0225 ether;
    uint256 public USD_PRICE_PER_TOKEN = 100 * 10 ** 6;
    uint256 public USD_PRICE_PER_TOKEN_DISCOUNTED = 75 * 10 ** 6;

    bool public isPublicSaleActive = false;
    string private _baseTokenURI;

    enum PaymentAsset { ETH, USDT, USDC }
    enum TicketType { Virtual, Physical }

    // tokenId => TicketType
    mapping(uint256 => TicketType) public tokenTicketType;

    uint256[] private virtualTokenIds;
    uint256[] private physicalTokenIds;

    mapping(address => bool) private whitelist;
    mapping(address => bool) private discountList;

    mapping(PaymentAsset => IERC20) private ERC20Token;

    constructor(
        address _usdcAddress,
        address _usdtAddress
    ) ERC721("Ceylon Halving Yacht Party NFT", "CCMHYP") {
        ERC20Token[PaymentAsset.USDT] = IERC20(_usdtAddress);
        ERC20Token[PaymentAsset.USDC] = IERC20(_usdcAddress);
    }

    // Set new eth mint price
    function setPrice(uint256 _ethPricePerToken) external onlyOwner {
        ETH_PRICE_PER_TOKEN = _ethPricePerToken;
    }

    function setWhitelist(
        address[] calldata addresses,
        bool isWhitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = isWhitelisted;
        }
    }

    function setDiscountList(
        address[] calldata addresses,
        bool isDiscounted
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            discountList[addresses[i]] = isDiscounted;
        }
    }

    // Check if an address is included in whitelist
    function isAddressWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    // Check if an address is included in discount list
    function isAddressDiscounted(address addr) external view returns (bool) {
        return discountList[addr];
    }

    // To check the type of a given tokenId
    function ticketTypeOf(uint256 tokenId) public view returns (TicketType) {
        return tokenTicketType[tokenId];
    }

    // Event to be triggered upon token mint
    event TokenMinted(
        uint256 indexed tokenId,
        address recipient,
        bool isPhysicalToken,
        bool isWhitelisted,
        bool isDiscounted,
        bool isPublicMint,
        PaymentAsset mintAsset
    );

    // Public Mint
    function mintToken(PaymentAsset mintAsset, bool isPhysical) public payable {
        require(isPublicSaleActive, "Sale is not active");

        bool isDiscounted = discountList[msg.sender];
        bool isWhitelisted = whitelist[msg.sender];

        bool isETHPayment = mintAsset == PaymentAsset.ETH;

        uint256 ethPaymentRequired;
        uint256 usdPaymentRequired;

        uint256 nextTokenId = totalSupply();

        // Figure out the amounts need to be paid
        if(isPhysical) {
            require(isWhitelisted, "Not whitelisted");
            require(physicalTokenIds.length < MAX_PHYSICAL_SUPPLY, "Physical tickets are sold out");

            if(isETHPayment) {
                ethPaymentRequired = isDiscounted ? ETH_PRICE_PER_TOKEN_DISCOUNTED : ETH_PRICE_PER_TOKEN;
            } else {
                usdPaymentRequired = isDiscounted ? USD_PRICE_PER_TOKEN_DISCOUNTED : USD_PRICE_PER_TOKEN;
            }

            tokenTicketType[nextTokenId] = TicketType.Physical;
            physicalTokenIds.push(nextTokenId);
        } else {
            // Defaulting to virtual type settings
            if(isETHPayment) {
                ethPaymentRequired = ETH_PRICE_PER_TOKEN_DISCOUNTED;
            } else {
                usdPaymentRequired = USD_PRICE_PER_TOKEN_DISCOUNTED;
            }

            tokenTicketType[nextTokenId] = TicketType.Virtual;
            virtualTokenIds.push(nextTokenId);
        }

        // Take payments
        if(isETHPayment) {
            require(ethPaymentRequired <= msg.value, "Ether value sent is not correct");
        } else {
            require(
                ERC20Token[mintAsset].transferFrom(
                    msg.sender,
                    address(this),
                    usdPaymentRequired
                ),
                "Stablecoin transfer failed"
            );
        }
        
        _safeMint(msg.sender, nextTokenId);
        emit TokenMinted(nextTokenId, msg.sender, isPhysical, isWhitelisted, isDiscounted, true, mintAsset);
    }

    // Pre-mint n number of tokens into a given wallet
    function reserveTo(uint256 n, address to, bool isPhysical) public onlyOwner {
        uint ts = totalSupply();
        for (uint i = 0; i < n; i++) {
            uint tokenId = ts + i;

            if(isPhysical) {
                tokenTicketType[tokenId] = TicketType.Physical;
                physicalTokenIds.push(tokenId);
            } else {
                tokenTicketType[tokenId] = TicketType.Virtual;
                virtualTokenIds.push(tokenId);
            }
            _safeMint(to, tokenId);
            emit TokenMinted(tokenId, to, isPhysical, false, false, false, PaymentAsset.ETH);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Toggle the sale state
    function togglePublicSaleState() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    // Withdraw USDC balance in the contract
    function withdraw(PaymentAsset withdrawAsset) public onlyOwner {
        bool isETHPayment = withdrawAsset == PaymentAsset.ETH;
        if(isETHPayment) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 token = ERC20Token[withdrawAsset];
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    function getVirtualTokenIds() public view returns (uint[] memory) {
        return virtualTokenIds;
    }

    function getPhysicalTokenIds() public view returns (uint[] memory) {
        return physicalTokenIds;
    }
}
