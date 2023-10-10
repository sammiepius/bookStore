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

    /**
    * @dev The total number of books currently available in the bookstore.
    *      This variable keeps track of the number of books created in the bookstore contract.
    *      It is used to manage book indices and ensure uniqueness when creating new books.
    */
    uint internal productsLength = 0;
    
    /**
    * @dev The Ethereum address of the cUSD (or equivalent) token contract used for book purchases.
    *      This address is used to interact with the token contract for transferring funds during book purchases.
    *      Make sure this address is set correctly to the cUSD token contract deployed on the Ethereum network.
    */
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1; 

    /**
    * @dev Event emitted when a new book is created in the bookstore.
    * @param owner The Ethereum address of the book's owner (seller).
    * @param name The name of the book.
    * @param image The URL or reference to the book's image.
    * @param description A detailed description of the book.
    * @param location The location or origin of the book.
    * @param price The price of the book in wei (1 Ether = 1e18 wei).
    * @param sold The total number of copies of the book sold.
    * @param likes The number of likes or recommendations for the book.
    */
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

    /**
    * @dev Event emitted when a book is purchased from the bookstore.
    * @param buyer The Ethereum address of the book buyer.
    * @param seller The Ethereum address of the book seller.
    * @param bookIndex The index (ID) of the purchased book.
    * @param price The price of the purchased book in wei (1 Ether = 1e18 wei).
    */
    event BookPurchased(
        address indexed buyer,
        address indexed seller,
        uint bookIndex,
        uint price
    );

    /**
    * @dev Event emitted when a book is liked by a user.
    * @param liker The Ethereum address of the user who liked the book.
    * @param bookIndex The index (ID) of the liked book.
    */
    event BookLiked(address indexed liker, uint bookIndex);

    
    /**
     * @dev Event emitted when a book is deleted by its owner.
     * @param owner The Ethereum address of the book's owner (seller).
     * @param bookIndex The index (ID) of the deleted book.
     */
    event BookDeleted(address indexed owner, uint bookIndex);
    

    /**
    * @dev Represents a book with its attributes.
    * @param owner The Ethereum address of the book's owner (seller).
    * @param name The name of the book.
    * @param image The URL or reference to the book's image.
    * @param description A detailed description of the book.
    * @param location The location or origin of the book.
    * @param price The price of the book in wei (1 Ether = 1e18 wei).
    * @param sold The total number of copies of the book sold.
    * @param likes The number of likes or recommendations for the book.
    */
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


    /**
    * @dev A mapping that associates a unique index (ID) with each book in the bookstore.
    *      The index serves as an identifier for books and allows efficient retrieval and management.
    *      Each index maps to a corresponding Book struct, storing detailed information about the book.
    */
    mapping (uint => Book) internal books;


    /**
     * @dev Creates a new book in the bookstore.
     * @param _name The name of the book.
     * @param _image The image URL of the book.
     * @param _description The description of the book.
     * @param _location The location of the book.
     * @param _price The price of the book.
     */
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
        require(bytes(_location).length > 0, "location field cannot be empty");

        uint priceLimit = 10 ether;

        require(_price > 0, " price field must be at least 1 wei");
        require(_price < priceLimit, "Price is to high for this book");
        uint _sold = 0;
        uint _likes = 0;
    Book storage newBook = books[productsLength];
       newBook.owner = payable(msg.sender);
       newBook.name = _name;
       newBook.image = _image;
       newBook.description = _description;
       newBook.location = _location;
       newBook.price = _price;
       newBook.sold = _sold;
       newBook.likes = _likes;

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

    /**
     * @dev Retrieves book details by its index in the bookstore.
     * @param _index The index of the book.
     * @return Book details including owner, name, image, description, location, price, sold, and likes.
     */
    function readBook(uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        string memory,
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
            book_.likes
        );
    }

    /**
     * @dev Deletes a book from the bookstore by the book owner using the book index.
     * @param _index The index of the book to delete.
     */ 
    function deleteBookId(uint _index) public {
        require(_index < productsLength, "Invalid book index");
        require(msg.sender == books[_index].owner, "you are not the owner");
        books[_index].owner = payable(address(0));
        emit BookDeleted(msg.sender, _index);
    }

    /**
     * @dev Likes a book in the bookstore.
     * @param _index The index of the book to like.
     */
    function likeBook(uint _index) public {
        require(_index < productsLength, "Invalid book index");
        require(msg.sender != books[_index].owner, "Owner of books cannot like");
        emit BookLiked(msg.sender, _index);
        books[_index].likes++;
    }

    /**
     * @dev Buys a book in the bookstore.
     * @param _index The index of the book to buy.
     */
    function buyBook(uint _index) public payable {
        require(_index < productsLength, "Invalid book index");
        require(IERC20Token(cUsdTokenAddress).balanceOf(msg.sender) >= books[_index].price, "Insufficient balance in cUSD token");
        require(
             IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            books[_index].owner,
            books[_index].price
        ),
        "Transfer failed."
        );

        emit BookPurchased(
            msg.sender,
            books[_index].owner,
            _index,
            books[_index].price
        );

        books[_index].sold++;
    }

    /**
     * @dev Retrieves the total number of books in the bookstore.
     * @return The length of the books array.
     */
    function getProductsLength() public view returns (uint){
        return (productsLength);
    }

   
}
