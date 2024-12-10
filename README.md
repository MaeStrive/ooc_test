# OOC
## 1.项目简介
### 项目结构
```arduino
.
├── contracts/                // 智能合约源代码
│   ├── ERC20.sol             // ERC20合约
│   ├── ERC721.sol            // ERC721合约
│   ├── FishermanNFT.sol      // 钓手NFT合约
│   ├── Staking.sol           // 鱼竿NFT合约
│   ├── FishingSpot.sol       // 鱼池合约(没用了)
│   ├── GMC.sol               // GMC合约
│   ├── IRC20.sol         
│   ├── IERC20Metadata.sol   
│   ├── IERC721.sol  
│   ├── IERC721Enumeable.sol    
│   ├── IERC721Metadata.sol   
│   ├── User.sol              // User合约
│   ├── Stake.sol             // Stake质押合约
│   └── OOC.sol               // OOC合约
├── scripts/                  // 部署脚本
├── test/                     // 测试用例
├── hardhat.config.js         // Hardhat 配置文件
├── noRjContracts             // 之前版本的合约,没啥用
├── old                       // 也是之前版本的合约,没啥用
├── docs/                     // 项目文档
├── test/                     // 使用chai测试合约的文件
└── README.md                 // 项目说明

```
## 2.环境要求
### 必需组件
- Node.js (v14.0.0+)
- npm (v6.0.0+)
- Hardhat (v2.0.0+)
- Solidity (^0.8.0)
- yarn（v1.22+）[可选]
### 推荐工具
- VSCode
- Solidity 插件
- Remix IDE
- MetaMask

## 2.项目启动
### 配置合约
在根目录下新建.env文件

```bash
OPTIMISM_CHAIN_URL=https://eth-sepolia.g.alchemy.com/v2/dkJ3yHIXaGTWlMmmnlJK9uIVAXV3kwfp  // 用于连接 Optimism 区块链的 RPC URL（当前示例中是 Sepolia 测试网的 URL）
PRIVATE_KEY=*****//填写你的私钥
ETHERSCAN_API_KEY=*******  //主网 Etherscan 的 API 密钥，用于验证和查看合约状态
ETHERSCAN_API_KEY_SEPOLIA=***** //epolia 测试网的 Etherscan API 密钥，用于测试环境中验证和交互
```
**注意提交时请不要提交此文件**

### 安装依赖
`npm install`
OR
`yarn`
### 编译合约
`yarn hardhat compile`
### 执行部署脚本(发布到测试网)
`yarn hardhat run scripts/run.js --network Sepolia`
### 执行task任务
1).首先在task文件夹下新建脚本文件

2).在hardhat.config.js 配置新建的文件

3).运行

`yarn hardhat [文件名] [构建函数传参(如果有的话)]`
### 验证合约
*需要在.env文件中填写API KEY*

`yarn hardhat verify --network Sepolia [合约地址] [构造函数传参(如果有的话)]`

**注意如果有传参的话 验证时的传参需要和部署时的传参一致！**
