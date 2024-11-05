const ethers = require('ethers');

const abi = [
  "function enter(uint256 amount)"
];

const iface = new ethers.utils.Interface(abi);
const data = iface.encodeFunctionData("enter", [ethers.utils.parseUnits("100", 18)]); // Replace "100" with the amount of SUSHI you want to deposit

console.log(data);