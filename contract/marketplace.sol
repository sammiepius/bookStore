// SPDX-License-Identifier: MIT  

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external payable returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Bookstore {
    uint internal productsLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1; 

 // Create a struct to store books details.
    struct Book {
    address payable owner;
    string name;
    string image;
    string description;
    string location;
    uint price;
    uint sold;
    uint rating_point;
    uint rated_by;
    }
//map used to store books.
    mapping (uint => Book) internal books;

//map used to store book rating.
    mapping(address => mapping(uint => bool)) private bookRating;

// Function that create a book.
    function writeBook(
     string memory _name,
     string memory _image,
     string memory _description,
     string memory _location,
     uint _price
    ) public {
        require(bytes(_name).length > 0, "name field cannot be empty");
        require(bytes(_image).length > 0, "image field cannot be empty");
        require(bytes(_description).length > 0, "description field cannot be empty");
        require(_price > 0, " price field must be at least 1 wei");
        uint _sold = 0;
    Book storage newBook = books[productsLength];
       newBook.owner = payable(msg.sender);
       newBook.name = _name;
       newBook.image = _image;
       newBook.description = _description;
       newBook.location = _location;
       newBook.price = _price;
       newBook.sold = _sold;

        productsLength++;
    }

// Function that get books using the books id.
    function readBook(uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        string memory,
        uint,
        uint,
        uint,
        uint

        ){
        Book storage book_ = books[_index];
        return (
            book_.owner,
            book_.name,
            book_.image,
            book_.description,
            book_.location,
            book_.price,
            book_.sold,
            book_.rating_point,
            book_.rated_by
        );
    }

// function that allow users to rate a book
    function rateBook (uint256 _index, uint256 _rate) public {
        require(!bookRating[msg.sender][_index], "You have already rate this book");
        require(_rate > 0 && _rate <= 5, "Rate need to be between 1 and 5");
        require(books[_index].owner != msg.sender, "Sorry you cannot rate your own book");
        Book storage book_ = books[_index];
        bookRating[msg.sender][_index] = true;
        book_.rating_point += _rate;
        book_.rated_by ++;
    }


    //Function to delete a book by the book owner using the book id . 
    function deleteBookId(uint _index) public {
        require(msg.sender == books[_index].owner, "you are not the owner");
        delete books[_index];
    }


    function buyBook(uint _index) public payable {
        require(IERC20Token(cUsdTokenAddress).balanceOf(msg.sender) >= books[_index].price, "Insufficient balance in cUSDT token");
        require(
             IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            books[_index].owner,
            books[_index].price
        ),
        "Transfer failed."
        );

        books[_index].sold++;
    }

//function to get length of book.
    function getProductsLength() public view returns (uint){
        return (productsLength);
    }

   
}