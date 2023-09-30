import Web3 from 'web3';
import { newKitFromWeb3 } from '@celo/contractkit';
import BigNumber from 'bignumber.js';
import marketplaceAbi from '../contract/marketplace.abi.json';
import erc20Abi from '../contract/erc20.abi.json';

const ERC20_DECIMALS = 18;
const MPContractAddress = '0x7dC72F4b4fcAF4DE2999bEe707500697E7fBD19d';
const cUSDContractAddress = '0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1';

let kit;
let contract;
let books = [];

//Connects wallet to gets the account and initializes the contract
const connectCeloWallet = async function () {
  if (window.celo) {
    try {
      notification('⚠️ Please approve this DApp to use it.');
      await window.celo.enable();
      notificationOff();
      const web3 = new Web3(window.celo);
      kit = newKitFromWeb3(web3);

      const accounts = await kit.web3.eth.getAccounts();
      kit.defaultAccount = accounts[0];

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress);
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
  } else {
    notification('⚠️ Please install the CeloExtensionWallet.');
  }
};

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress);

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount });
  return result;
}

const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount);
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2);
  document.querySelector('#balance').textContent = cUSDBalance;
};

// an async function used to get books.
const getBooks = async function () {
  const _productsLength = await contract.methods.getProductsLength().call();
  const _products = [];

  //  function that loops through the books.
  for (let i = 0; i < _productsLength; i++) {
    let _product = new Promise(async (resolve, reject) => {
      let p = await contract.methods.readBook(i).call();
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        location: p[4],
        price: new BigNumber(p[5]),
        sold: p[6],
        likes: p[7],
      });
    });
    _products.push(_product);
  }
  books = await Promise.all(_products);
  renderBooks();
};

function renderBooks() {
  document.getElementById('marketplace').innerHTML = '';
  if (books) {
    books.forEach((_book) => {
      if (_book.owner != '0x0000000000000000000000000000000000000000') {
        const newDiv = document.createElement('div');
        newDiv.className = 'col-md-4';
        newDiv.innerHTML = productTemplate(_book);
        document.getElementById('marketplace').appendChild(newDiv);
      }
    });
  } else {
    console.log('array is empty');
  }
}

function productTemplate(_book) {
  return `
  <div class="card mb-4">
          <img class="card-img-top" src="${
            _book.image
          }" alt="..." style="height : 200px;">
           <div class="position-absolute  top-0 end-2 bg-danger mt-4 px-2 py-1 rounded" style="cursor : pointer;">
             <i class="bi bi-trash-fill deleteBtn" style="color : white;" id="${
               _book.index
             }"></i>
             </div>
             <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
               ${_book.sold} Sold
             </div>
       <div class="card-body text-left p-3 position-relative">
             <div class="translate-middle-y position-absolute top-0 end-0"  id="${
               _book.index
             }">
             ${identiconTemplate(_book.owner)}
             </div>
             <p class="card-title  fw-bold mt-2 text-uppercase">${
               _book.name
             }</p>
             <i class="bi bi-heart-fill like" style="color : red ; cursor : pointer; font-size: 20px; " id="${
               _book.index
             }"> ${
    _book.likes == 0
      ? ''
      : `<b><span class="card-text">${_book.likes}</span></b>`
  }
             </i></br>
              <a class="btn btn-md btn-success viewBook" id="${
                _book.index
              }" style="width:100%;">View book Details</a>
             </div>
         </div>
  `;
}
// function that create a html template.
function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL();

  return `
    <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
      <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
          target="_blank">
          <img src="${icon}" width="48" alt="${_address}">
      </a>
    </div>
    `;
}

// create a notification bar
function notification(_text) {
  document.querySelector('.alert').style.display = 'block';
  document.querySelector('#notification').textContent = _text;
}

// function to turn off notification bar.
function notificationOff() {
  document.querySelector('.alert').style.display = 'none';
}

window.addEventListener('load', async () => {
  notification('⌛ Loading...');
  await connectCeloWallet();
  await getBalance();
  await getBooks();
  notificationOff();
});

// function used to list a books on the blockchain.
document
  .querySelector('#newProductBtn')
  .addEventListener('click', async (e) => {
    const newProductName = document.getElementById("newProductName");
    const newImgUrl = document.getElementById("newImgUrl");
    const newPrice = document.getElementById("newPrice");

  //   document.getElementById("newProductBtn").addEventListener("click", function () {
      // Validate the price as a valid number
      const price = parseFloat(newPrice.value);
      if (isNaN(price) || price <= 0) {
        alert("Please enter a valid positive number for the price.");
        return;
      }

      // Validate the image URL format
      const imageUrlRegex = /\.(jpeg|jpg|gif|png|bmp)$/i;
      if (!imageUrlRegex.test(newImgUrl.value)) {
        alert("Please enter a valid image URL.");
        return;
      }
    // collecting form parameters
    const params = [
      document.getElementById('newProductName').value,
      document.getElementById('newImgUrl').value,
      document.getElementById('newProductDescription').value,
      document.getElementById('newLocation').value,
      new BigNumber(document.getElementById('newPrice').value)
        .shiftedBy(ERC20_DECIMALS)
        .toString(),
    ];
    notification(`⌛ Adding "${params[0]}"...`);
    try {
      const result = await contract.methods
        .writeBook(...params)
        .send({ from: kit.defaultAccount });
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notification(`🎉 You successfully added "${params[0]}".`);
    getBooks();
  });

document.querySelector('#marketplace').addEventListener('click', async (e) => {
  //checks if there is a class name called deleteBtn
  if (e.target.className.includes('deleteBtn')) {
    const index = e.target.id;

    notification('⌛ Please wait...');
    // calls the delete fucntion on the smart contract
    try {
      const result = await contract.methods
        .deleteBookId(index)
        .send({ from: kit.defaultAccount });
      notification(`You have deleted an event successfully`);
      getBooks();
      getBalance();
    } catch (error) {
      notification(`⚠️ you are not the owner of this event`);
    }
    notificationOff();
  }
  if (e.target.className.includes('like')) {
    const index = e.target.id;

    notification('⌛ Please wait...');
    // calls the likes fucntion on the smart contract
    try {
      const result = await contract.methods
        .likeBook(index)
        .send({ from: kit.defaultAccount });
      notification(`thanks`);
      getBooks();
      getBalance();
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notificationOff();
  }
})
document.querySelector('#addModal1').addEventListener('click', async (e) => {
  if (e.target.className.includes('buyBtn')) {
    const index = e.target.id;
    notification('⌛ Waiting for payment approval...');

    try {
      await approve(books[index].price);
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }

    notification(`⌛ Awaiting payment for "${books[index].name}"...`);

    // calls the buy fucntion on the smart contract
    try {
      const result = await contract.methods
        .buyBook(index)
        .send({ from: kit.defaultAccount });
      notification(`🎉 You successfully bought "${books[index].name}".`);
      getBooks();
      getBalance();
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }

    notificationOff();
  }
});

// implements various functionalities
document.querySelector('#marketplace').addEventListener('click', async (e) => {
  if (e.target.className.includes('viewBook')) {
    const _id = e.target.id;
    let books;

    try {
      books = await contract.methods.readBook(_id).call();
      let myModal = new bootstrap.Modal(document.getElementById('addModal1'), {
        backdrop: 'static',
        keyboard: false,
      });
      myModal.show();

      // shows book details on a modal
      document.getElementById('modalHeader').innerHTML = `
<div class="card">
<img class="card-img-top"
src="${books[2]}"
alt="image pic" style={{width: "100%", objectFit: "cover"}} />
<div class="card-body">
  <p class="card-title fs-6 fw-bold mt-2 text-uppercase">${books[1]}</p>
  <p  style="font-size : 12px;">
    <span style="display : block;" class="text-uppercase fw-bold">Description: </span>
    <span class="">${books[3]}</span>
   </p>
   <p class="card-text mt-2" style="font-size : 12px;">
        <span style="display : block;" class="text-uppercase fw-bold">Location: </span>
        <span >${books[4]}</span>
   </p>

<div class="d-grid gap-2">
        <a class="btn btn-lg text-white bg-success buyBtn fs-6 p-3"
        id=${_id}
        >
          Buy for ${new BigNumber(books[5])
            .shiftedBy(-ERC20_DECIMALS)
            .toFixed(2)} cUSD
        </a>
  </div>
</div>
</div>

`;
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notificationOff();
  }
});
