// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./IERC20Token.sol"; // Import the ERC20 interface for token handling

contract Bookstore {
    uint internal productsLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Book {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        uint sold;
        uint likes;
    }

    mapping (uint => Book) internal books;

    event BookCreated(
        address indexed owner,
        string name,
        string image,
        string description,
        string location,
        uint price,
        uint sold,
        uint likes
    );

    event BookPurchased(
        address indexed buyer,
        address indexed seller,
        uint bookIndex,
        uint price
    );

    event BookLiked(address indexed liker, uint bookIndex);

    event BookDeleted(address indexed owner, uint bookIndex);

    function writeBook(
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _location,
        uint _price
    ) public {
        require(bytes(_name).length > 0, "Name field cannot be empty");
        require(bytes(_image).length > 0, "Image field cannot be empty");
        require(bytes(_description).length > 0, "Description field cannot be empty");
        require(bytes(_location).length > 0, "Location field cannot be empty");
        require(_price > 0, "Price field must be greater than zero");
        require(_price <= 10 ether, "Price is too high for this book");

        uint _sold = 0;
        uint _likes = 0;

        books[productsLength] = Book({
            owner: payable(msg.sender),
            name: _name,
            image: _image,
            description: _description,
            location: _location,
            price: _price,
            sold: _sold,
            likes: _likes
        });

        emit BookCreated(
            msg.sender,
            _name,
            _image,
            _description,
            _location,
            _price,
            _sold,
            _likes
        );

        productsLength++;
    }

    function readBook(uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        string memory,
        uint,
        uint,
        uint
    ) {
        require(_index < productsLength, "Invalid book index");
        Book storage book_ = books[_index];
        return (
            book_.owner,
            book_.name,
            book_.image,
            book_.description,
            book_.location,
            book_.price,
            book_.sold,
            book_.likes
        );
    }

    function deleteBookId(uint _index) public {
        require(_index < productsLength, "Invalid book index");
        require(msg.sender == books[_index].owner, "You are not the owner");
        
        // Delete the book by overwriting it with the last book in the mapping
        books[_index] = books[productsLength - 1];
        delete books[productsLength - 1];
        productsLength--;

        emit BookDeleted(msg.sender, _index);
    }

    function likeBook(uint _index) public {
        require(_index < productsLength, "Invalid book index");
        require(msg.sender != books[_index].owner, "Owner of books cannot like");
        
        books[_index].likes++;
        emit BookLiked(msg.sender, _index);
    }

    function buyBook(uint _index) public payable {
        require(_index < productsLength, "Invalid book index");
        Book storage book = books[_index];
        require(book.owner != address(0), "Book not found");
        require(msg.sender != book.owner, "You cannot buy your own book");
        require(msg.value >= book.price, "Insufficient Ether sent");

        // Transfer funds to the book owner
        (bool success, ) = book.owner.call{value: book.price}("");
        require(success, "Transfer failed");

        book.sold++;

        emit BookPurchased(
            msg.sender,
            book.owner,
            _index,
            book.price
        );
    }

    function getProductsLength() public view returns (uint) {
        return productsLength;
    }

    // Fallback function to reject incoming Ether
    receive() external payable {
        revert("This contract does not accept Ether directly.");
    }
}
