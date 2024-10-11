## 1.玩家状态合约

### 概述

该合约 `User` 管理游戏中的玩家数据，允许玩家升级、购买道具、切换钓鱼点等操作。它基于 `OpenZeppelin` 的 `AccessControl` 和 `Ownable` 合约，确保安全和权限控制。合约还集成了外部的 GMC 合约 (`IGMC`)，用于与游戏代币进行交互。

------

### 合约接口

#### `IGMC`

这是一个外部合约接口，用于与 GMC 代币进行交互。主要包含以下方法：

- `mint(address to, uint256 amount)`: 向指定地址铸造一定数量的 GMC。
- `balanceOf(address account)`: 获取指定地址的 GMC 余额。
- `transfer(address sender, address recipient, uint256 amount)`: 从指定发送者地址向接收者地址转移 GMC。

### 数据结构

#### `PlayerInfo`

该结构体存储玩家的基本信息：

- `fishingCount`: 当前钓鱼次数。
- `experience`: 玩家当前经验值。
- `level`: 玩家等级。
- `currentFishermanNFT`: 当前使用的渔夫 NFT ID。
- `currentRodNFT`: 当前使用的钓竿 NFT ID。
- `unlockedFishingSpots`: 一个布尔数组，表示玩家解锁的钓鱼点。
- `currentFishingSpot`: 当前选择的钓鱼点 ID。
- `fishPoolLevel`: 鱼池等级。
- `fishCount`: 各个星级鱼的数量。
- `interestRate`: 当前利率，可能用于计算某种奖励。
- `collectedGMC`: 玩家已收集的 GMC 代币数。
- `baitCount`: 玩家当前拥有的鱼饵数量。

### 状态变量

- `gmcContract`: 与 GMC 合约的实例。
- `_pendingOwner`: 即将成为新所有者的地址。
- `ADMIN_ROLE`: 管理员权限标识符，使用 `keccak256` 生成。
- `levelUpLimit`: 等级上限，默认值为 100。
- `experienceConfig`: 每一级所需的经验值数组。
- `baitPurchaseLimit`: 鱼饵购买上限，默认值为 99。
- `fishingCountLimit`: 钓鱼次数上限，默认值为 10。
- `baitPrice`: 鱼饵价格。

### 事件

- `PlayerAdded(address indexed playerAddress)`: 新玩家注册事件。
- `FishingCountDecreased(address indexed playerAddress, uint256 count)`: 钓鱼次数减少事件。
- `FishingCountRecovered(address indexed playerAddress, uint256 count)`: 钓鱼次数恢复事件。
- `PlayerLeveledUp(address indexed playerAddress, uint256 newLevel)`: 玩家升级事件。
- `ExperienceAdded(address indexed playerAddress, uint256 addedExp, uint256 newExp)`: 玩家经验增加事件。
- `FishermanChanged(address indexed playerAddress, uint256 newFishermanId)`: 玩家更换渔夫 NFT 事件。
- `RodChanged(address indexed playerAddress, uint256 newRodId)`: 玩家更换钓竿 NFT 事件。
- `FishingSpotSwitched(address indexed playerAddress, uint256 newSpotId)`: 玩家切换钓鱼点事件。
- `FishingSpotUnlocked(address indexed playerAddress, uint256 spotId)`: 玩家解锁新钓鱼点事件。
- `PlayerLevelUpdated(address indexed playerAddress, uint256 newLevel)`: 玩家等级更新事件。
- `FishPoolLevelUpdated(address indexed playerAddress, uint256 newLevel)`: 鱼池等级更新事件。
- `FishCountUpdated(address indexed playerAddress, uint256 star, uint256 newCount)`: 鱼的数量更新事件。
- `CollectedGMCUpdated(address indexed playerAddress, uint256 newAmount)`: 玩家已收集 GMC 数量更新事件。
- `BaitCountUpdated(address indexed playerAddress, uint256 newCount)`: 玩家鱼饵数量更新事件。
- `OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)`: 开始所有权转移事件。
- `ClaimGMC(address userAddress, uint256 count)`: 玩家领取 GMC 事件。

------

### 函数

#### 1. **管理员管理**

- `addAdmin(address newAdmin)`: 添加新的管理员，只有合约所有者可以调用。

  **返回值**: 无。

- `removeAdmin(address admin)`: 移除管理员，只有合约所有者可以调用。

  **返回值**: 无。

#### 2. **玩家管理**

- `addUser(address userAddress)`: 注册新玩家，只有管理员可以调用。

  **返回值**: 无。

- `getUser(address userAddress)`: 获取玩家信息，只有管理员可以调用。

  **返回值**: `PlayerInfo` 结构体，包含玩家的所有信息。

- `decreaseFishingCount(address userAddress, uint256 count)`: 减少玩家钓鱼次数，只有管理员可以调用。

  **返回值**: 无。

- `recoverFishingCount(address userAddress, uint256 count)`: 恢复玩家钓鱼次数，只有管理员可以调用。

  **返回值**: 无。

- `addExperience(address userAddress, uint256 exp)`: 增加玩家经验，并检查玩家是否可以升级，只有管理员可以调用。

  **返回值**: 无。

- `changeFisherman(address userAddress, uint256 fishermanId)`: 更换玩家的渔夫 NFT，只有管理员可以调用。

  **返回值**: 无。

- `changeRod(uint256 rodId, address userAddress)`: 更换玩家的钓竿 NFT，只有管理员可以调用。

  **返回值**: 无。

- `switchFishingSpot(uint256 spotId, address userAddress)`: 切换玩家的钓鱼点，只有管理员可以调用。

  **返回值**: 无。

- `unlockFishingSpot(address userAddress, uint256 spotId)`: 解锁玩家新的钓鱼点，只有管理员可以调用。

  **返回值**: 无。

#### 3. **玩家状态修改与查看**

- `getPlayerLevel(address playerAddress)`: 获取玩家当前等级。

  **返回值**: `uint256` 玩家当前等级。

- `setPlayerLevel(address playerAddress, uint256 newLevel)`: 设置玩家等级，只有管理员可以调用。

  **返回值**: 无。

- `getFishPoolLevel(address playerAddress)`: 获取玩家的鱼池等级。

  **返回值**: `uint256` 玩家鱼池等级。

- `setFishPoolLevel(address playerAddress, uint256 newLevel)`: 设置玩家鱼池等级，只有管理员可以调用。

  **返回值**: 无。

- `getFishCount(address playerAddress)`: 获取玩家的各星级鱼的数量。

  **返回值**: `uint256[10]` 包含每个星级鱼的数量。

- `setFishCount(address playerAddress, uint256 star, uint256 newCount)`: 设置玩家某个星级鱼的数量，只有管理员可以调用。

  **返回值**: 无。

- `getCollectedGMC(address playerAddress)`: 获取玩家已收集的 GMC 数量。

  **返回值**: `uint256` 玩家已收集的 GMC 数量。

- `setCollectedGMC(address playerAddress, uint256 newAmount)`: 设置玩家已收集的 GMC 数量，只有管理员可以调用。

  **返回值**: 无。

- `getBaitCount(address playerAddress)`: 获取玩家当前拥有的鱼饵数量。

  **返回值**: `uint256` 玩家当前鱼饵数量。

- `setBaitCount(address playerAddress, uint256 newCount)`: 设置玩家鱼饵数量，只有管理员可以调用。

  **返回值**: 无。

#### 4. **GMC 合约交互**

- `getGMCBalance(address userAddress)`: 获取玩家的 GMC 余额。

  **返回值**: `uint256` 玩家 GMC 余额。

- `claimGMC(address userAddress, uint256 count)`: 玩家领取 GMC，只有管理员可以调用。

  **返回值**: 无。

- `buyBaits(address userAddress, uint256 count)`: 玩家购买鱼饵，只有管理员可以调用。

  **返回值**: 无。

------

### 权限与安全

- **合约所有者 (Owner)**: 合约的所有者具有最高权限，可以转让所有权、管理管理员。
- **管理员 (Admin)**: 管理员具有较大的权限，可以注册玩家、修改玩家状态、处理钓鱼和经验等操作。

------

### 使用场景

1. **玩家注册**: 当新玩家加入游戏时，管理员调用 `addUser` 方法进行玩家注册。
2. **玩家钓鱼**: 玩家钓鱼后，管理员调用 `decreaseFishingCount` 方法减少钓鱼次数，或使用 `recoverFishingCount` 恢复钓鱼次数。
3. **玩家升级**: 玩家获得经验后，管理员调用 `addExperience` 增加经验，并自动处理升级逻辑。
4. **道具管理**: 玩家可以更换渔夫或钓竿 NFT，或通过购买增加鱼饵数量。
5. **GMC 领取**: 玩家可以通过管理员触发 `claimGMC` 领取他们的 GMC 代币。

## 2.渔场合约

### 概述

合约 `FishingSpot` 用于管理游戏中的钓鱼点。管理员可以添加、更新钓鱼点的配置，获取钓鱼点信息。合约基于 `OpenZeppelin` 的 `Ownable` 和 `AccessControl` 合约，确保安全性和权限管理。

------

### 数据结构

#### `SpotConfig`

该结构体存储每个钓鱼点的配置：

- `starLevel`: 钓鱼点的星级。
- `fishList`: 钓鱼点提供的鱼类列表。
- `entryLevel`: 进入该钓鱼点所需的等级。

### 状态变量

- `ADMIN_ROLE`: 管理员权限的标识符，使用 `keccak256` 生成。
- `spotConfigs`: 钓鱼点配置的映射，键为钓鱼点 ID。
- `spotIds`: 所有钓鱼点 ID 的数组。

### 事件

- `FishingSpotAdded(uint256 indexed spotId, uint8 starLevel, uint8 entryLevel)`: 钓鱼点添加事件。
- `FishingSpotUpdated(uint256 indexed spotId, uint8 starLevel, uint8 entryLevel)`: 钓鱼点更新事件。

------

### 函数

#### 1. **管理员管理**

- `addAdmin(address newAdmin)`: 添加新的管理员，只有合约所有者可以调用。

  **返回值**: 无。

- `removeAdmin(address admin)`: 移除管理员，只有合约所有者可以调用。

  **返回值**: 无。

- `renounceAdmin()`: 放弃管理员角色。

  **返回值**: 无。

#### 2. **钓鱼点管理**

- `addFishingSpot(uint256 spotId, uint8 starLevel, uint256[] memory fishList, uint8 entryLevel)`: 添加新的钓鱼点，只有管理员可以调用。

  **参数**:

  - `spotId`: 钓鱼点的唯一标识符。
  - `starLevel`: 钓鱼点的星级。
  - `fishList`: 钓鱼点所提供的鱼类 ID 列表。
  - `entryLevel`: 进入该钓鱼点所需的等级。

  **返回值**: `bool` 表示操作是否成功。

- `updateFishingSpot(uint256 spotId, uint8 starLevel, uint256[] memory fishList, uint8 entryLevel)`: 更新现有钓鱼点的配置，只有管理员可以调用。

  **参数**:

  - `spotId`: 钓鱼点的唯一标识符。
  - `starLevel`: 新的星级。
  - `fishList`: 新的鱼类 ID 列表。
  - `entryLevel`: 新的进入等级。

  **返回值**: `bool` 表示操作是否成功。

- `getFishingSpotConfig(uint256 spotId)`: 获取指定钓鱼点的配置。

  **参数**:

  - `spotId`: 钓鱼点的唯一标识符。

  **返回值**: `SpotConfig` 结构体，包含该钓鱼点的详细配置。

- `getAllFishingSpotIds()`: 获取所有钓鱼点的 ID 列表。

  **返回值**: `uint256[]` 包含所有钓鱼点的 ID。

------

### 权限与安全

- **合约所有者 (Owner)**: 合约的所有者具有最高权限，可以管理管理员的角色。
- **管理员 (Admin)**: 管理员具有管理钓鱼点的权限，可以添加、更新钓鱼点的配置。

------

### 使用场景

1. **钓鱼点添加**: 当需要增加新的钓鱼点时，管理员调用 `addFishingSpot` 方法。
2. **钓鱼点更新**: 管理员可以通过 `updateFishingSpot` 方法更新现有钓鱼点的配置。
3. **获取钓鱼点信息**: 管理员或任何用户可以调用 `getFishingSpotConfig` 获取特定钓鱼点的详细信息。
4. **查看所有钓鱼点**: 使用 `getAllFishingSpotIds` 方法，可以获取当前所有钓鱼点的 ID 列表。

## 3.钓手NFT合约

### 概述

合约 `FishermanNFT` 是一个基于 ERC721 标准的非同质化代币 (NFT) 合约，允许用户铸造、交易和管理钓手 NFT。该合约集成了权限管理和列出/购买功能，确保安全性和灵活性。

### 数据结构

#### `Listing`

该结构体用于存储 NFT 的上架信息：

- `seller`: 卖家地址。
- `price`: 上架价格。

### 状态变量

- `mintPrice`: 铸造钓手 NFT 的价格。
- `maxSupplies`: 各类钓手 NFT 的最大供应量。
- `mintedSupplies`: 已铸造各类钓手 NFT 的数量。
- `fishermanTypes`: 各 NFT 类型的映射。
- `_tokenURIs`: 存储每个 NFT 的元数据 URI。
- `listings`: NFT 上架信息的映射。

### 事件

- `FishermanMinted(address indexed to, uint256 indexed tokenId)`: 钓手 NFT 被铸造时触发。
- `AdminAdded(address indexed newAdmin)`: 新管理员添加时触发。
- `AdminRemoved(address indexed removedAdmin)`: 管理员被移除时触发。
- `ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price)`: NFT 上架时触发。
- `ItemSold(uint256 indexed tokenId, address indexed buyer, uint256 price)`: NFT 售出时触发。
- `MetadataUpdate(uint256 _tokenId)`: NFT 元数据更新时触发。

### 函数

#### 1. 铸造功能

- `mintFisherman()`: 用户支付一定金额铸造钓手 NFT。

  **返回值**: `uint256` 新铸造的钓手 NFT ID。

- `freeMintFisherman(address playAddress)`: 管理员为指定地址铸造钓手 NFT。

  **返回值**: `uint256` 新铸造的钓手 NFT ID。

#### 2. 市场功能

- `listItem(uint256 tokenId, uint256 price)`: 用户将 NFT 上架出售。

  **参数**:

  - `tokenId`: 要上架的 NFT ID。
  - `price`: 上架价格。

  **返回值**: 无。

- `buyItem(uint256 tokenId)`: 用户购买上架的 NFT。

  **参数**:

  - `tokenId`: 要购买的 NFT ID。

  **返回值**: 无。

- `cancelListing(uint256 tokenId)`: 用户取消 NFT 的上架。

  **参数**:

  - `tokenId`: 要取消上架的 NFT ID。

  **返回值**: 无。

#### 3. 管理功能

- `setBaseTokenURI(string memory newBaseTokenURI)`: 管理员设置基础 URI。

  **参数**:

  - `newBaseTokenURI`: 新的基础 URI。

  **返回值**: 无。

- `setMintPrice(uint256 newMintPrice)`: 管理员设置铸造价格。

  **参数**:

  - `newMintPrice`: 新的铸造价格。

  **返回值**: 无。

#### 4. 查询功能

- `totalSupply()`: 查询总供应量。

  **返回值**: `uint256` 当前 NFT 的总数量。

- `tokenOfOwnerByIndex(address owner, uint256 index)`: 根据索引获取某个地址拥有的 NFT ID。

  **返回值**: `uint256` 拥有的 NFT ID。

- `tokenByIndex(uint256 index)`: 根据全局索引获取 NFT ID。

  **返回值**: `uint256` NFT ID。

#### 5. 其他功能

- `withdraw()`: 合约所有者提取合约余额。

  **返回值**: 无。

- `random()`: 生成伪随机数，用于钓手类型的确定。

### 权限与安全

- **合约所有者 (Owner)**: 合约的所有者具有最高权限，可以管理合约和资金。
- **管理员 (Admin)**: 具备管理铸造和设置基础 URI 等权限。

### 使用场景

1. **铸造钓手 NFT**: 用户通过 `mintFisherman` 或 `freeMintFisherman` 函数铸造钓手 NFT。
2. **市场交易**: 用户可以通过 `listItem` 上架 NFT，使用 `buyItem` 购买 NFT。
3. **管理功能**: 管理员可以设置铸造价格和基础 URI，管理 NFT 的流通和信息。

### 注意事项

- 确保遵循合约的权限管理和安全性要求，以防止不当操作。
- 进行市场交易时，请仔细检查 NFT 的上架信息和价格。

## 4.鱼竿NFT合约

### 概述

合约 `FishingRodNFT` 是一个基于 ERC721 标准的非同质化代币 (NFT) 合约，允许用户铸造、交易和管理鱼竿 NFT。合约集成了权限管理、市场功能和元数据管理，确保了安全性和灵活性。

### 数据结构

#### `Listing`

用于存储 NFT 上架信息：

- `seller`: 卖家地址。
- `price`: 上架价格。

#### `RodAttributes`

用于存储鱼竿的属性：

- `image`: 鱼竿图像。
- `qteCount`: 数量。
- `innerValue`: 内部值。
- `outerValue`: 外部值。
- `comboValue`: 组合值。
- `name`: 鱼竿名称。
- `skillName`: 技能名称。
- `skillValue`: 技能值。
- `qteSkill`: 数量技能。
- `rodId`: 鱼竿 ID。

### 状态变量

- `_name`: 代币名称。
- `_symbol`: 代币符号。
- `_tokenIds`: 当前铸造的 NFT ID 计数器。
- `_ownedTokens`: 存储用户拥有的 NFT ID。
- `_ownedTokensIndex`: 存储每个 NFT 在用户拥有的 NFT 列表中的索引。
- `_allTokens`: 所有 NFT ID 数组。
- `_allTokensIndex`: 存储每个 NFT 在 `_allTokens` 数组中的位置。
- `ADMIN_ROLE`: 管理员角色。
- `_baseTokenURI`: 基础 URI。
- `mintPrice`: 鱼竿 NFT 铸造价格。
- `mintedSupplies`: 各类型鱼竿已铸造数量。
- `rodTypes`: 映射 NFT ID 到鱼竿类型。

### 事件

- `RodMinted(address indexed to, uint256 indexed tokenId)`: 鱼竿 NFT 被铸造时触发。
- `RodAttributesUpdated(uint256 indexed tokenId)`: 鱼竿属性更新时触发。
- `AdminAdded(address indexed newAdmin)`: 新管理员添加时触发。
- `AdminRemoved(address indexed removedAdmin)`: 管理员被移除时触发。
- `ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price)`: NFT 上架时触发。
- `ItemSold(uint256 indexed tokenId, address indexed buyer, uint256 price)`: NFT 售出时触发。

### 函数

#### 1. 铸造功能

- `mintRod()`: 用户支付铸造价格铸造鱼竿 NFT。

  **返回值**: `uint256` 新铸造的鱼竿 NFT ID。

- `freeMintRod(address playAddress)`: 管理员为指定地址铸造鱼竿 NFT。

  **返回值**: `uint256` 新铸造的鱼竿 NFT ID。

#### 2. 市场功能

- `listItem(uint256 tokenId, uint256 price)`: 用户将 NFT 上架出售。

  **参数**:

  - `tokenId`: 要上架的 NFT ID。
  - `price`: 上架价格。

  **返回值**: 无。

- `buyItem(uint256 tokenId)`: 用户购买上架的 NFT。

  **参数**:

  - `tokenId`: 要购买的 NFT ID。

  **返回值**: 无。

- `cancelListing(uint256 tokenId)`: 用户取消 NFT 的上架。

  **参数**:

  - `tokenId`: 要取消上架的 NFT ID。

  **返回值**: 无。

#### 3. 管理功能

- `setBaseTokenURI(string memory newBaseTokenURI)`: 管理员设置基础 URI。

  **参数**:

  - `newBaseTokenURI`: 新的基础 URI。

  **返回值**: 无。

- `setMintPrice(uint256 newMintPrice)`: 管理员设置铸造价格。

  **参数**:

  - `newMintPrice`: 新的铸造价格。

  **返回值**: 无。

#### 4. 查询功能

- `totalSupply()`: 查询总供应量。

  **返回值**: `uint256` 当前 NFT 的总数量。

- `tokenOfOwnerByIndex(address owner, uint256 index)`: 根据索引获取某个地址拥有的 NFT ID。

  **返回值**: `uint256` 拥有的 NFT ID。

- `tokenByIndex(uint256 index)`: 根据全局索引获取 NFT ID。

  **返回值**: `uint256` NFT ID。

#### 5. 其他功能

- `withdraw()`: 合约所有者提取合约余额。

  **返回值**: 无。

### 权限与安全

- **合约所有者 (Owner)**: 具有最高权限，可以管理合约和资金。
- **管理员 (Admin)**: 具备管理铸造、设置基础 URI 等权限。

### 使用场景

1. **铸造鱼竿 NFT**: 用户通过 `mintRod` 或 `freeMintRod` 函数铸造鱼竿 NFT。
2. **市场交易**: 用户可以通过 `listItem` 上架 NFT，使用 `buyItem` 购买 NFT。
3. **管理功能**: 管理员可以设置铸造价格和基础 URI，管理 NFT 的流通和信息。

### 注意事项

- 确保遵循合约的权限管理和安全性要求，以防止不当操作。
- 在进行市场交易时，请仔细检查 NFT 的上架信息和价格。

## 5.GMC合约

### 概述

合约 `GMC` 是一个基于 ERC20 标准的代币合约，具备管理功能，允许合约所有者和指定管理员进行代币的铸造和转移。该合约集成了权限管理，以确保只有授权的账户能够执行特定操作。

### 状态变量

- `_admins`: 存储管理员地址的映射。
- `initialSupply`: 初始供应量。

### 事件

- `AdminAdded(address indexed account)`: 新管理员添加时触发。
- `AdminRemoved(address indexed account)`: 管理员移除时触发。

### 函数

#### 1. 构造函数

- `constructor(uint256 initialSupply)`: 初始化合约并铸造初始代币供应量给合约所有者。

  **参数**:

  - `initialSupply`: 初始供应量。

#### 2. 管理员功能

- `addAdmin(address account)`: 合约所有者添加新的管理员。

  **参数**:

  - `account`: 要添加为管理员的地址。

  **返回值**: 无。

- `removeAdmin(address account)`: 合约所有者移除管理员。

  **参数**:

  - `account`: 要移除的管理员地址。

  **返回值**: 无。

- `isAdmin(address account)`: 查询指定地址是否为管理员。

  **参数**:

  - `account`: 要查询的地址。

  **返回值**: `bool` 是否为管理员。

#### 3. 代币功能

- `mint(address to, uint256 amount)`: 由管理员铸造新的代币。

  **参数**:

  - `to`: 接收代币的地址。
  - `amount`: 要铸造的代币数量。

  **返回值**: 无。

- `transfer(address from, address to, uint256 amount)`: 由管理员执行代币转移。

  **参数**:

  - `from`: 代币发送者地址。
  - `to`: 代币接收者地址。
  - `amount`: 转移的代币数量。

  **返回值**: 无。

#### 4. 其他功能

- `decimals()`: 返回代币的精度。

  **返回值**: `uint8` 代币小数位数（18位）。

- `transferOwnership(address newOwner)`: 合约所有者转移合约所有权。

  **参数**:

  - `newOwner`: 新的合约所有者地址。

  **返回值**: 无。

### 权限与安全

- **合约所有者 (Owner)**: 具有最高权限，可以管理合约、添加或移除管理员、铸造代币和转移合约所有权。
- **管理员 (Admin)**: 具备铸造代币和转移代币的权限，但不能管理合约所有权。

### 使用场景

1. **铸造代币**: 管理员可以通过 `mint` 函数为指定地址铸造新代币。
2. **代币转移**: 管理员可以通过 `transfer` 函数执行代币的转移操作。
3. **管理员管理**: 合约所有者可以添加或移除管理员，以控制谁有权执行特定操作。

### 注意事项

- 在添加或移除管理员时，请确保操作的安全性，避免不必要的权限提升。
- 管理员的铸造和转移功能需要谨慎使用，以防止滥用。