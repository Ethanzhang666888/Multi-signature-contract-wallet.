// Notes:
// 实现⼀个简单的多签合约钱包，合约包含的功能：
// 1\创建多签钱包时，确定所有的多签持有⼈和签名门槛
// 2\多签持有⼈可提交提案
// 3\其他多签⼈确认提案（使⽤交易的⽅式确认即可）
// 4\达到多签⻔槛、任何⼈都可以执⾏交易

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 创建一个多签钱包合约
contract MultiSigWallet {
    address[] public owners; // 钱包的所有者地址列表
    mapping(address => bool) public isOwner; // 检查地址是否为所有者的映射
    uint public requiredSignatures; // 执行提议所需的签名数量

    // 提议结构体，包含目标地址、价值、数据、确认数和执行状态
    struct Proposal {
        address to; // 资金转移的目标地址
        uint value; // 转移的金额
        bytes data; // 附加数据
        uint confirmations; // 收到的确认数
        bool executed; // 提议是否已执行
        mapping(address => bool) isConfirmed; // 检查每个地址是否已确认的映射
    }

    Proposal[] public proposals; // 存储所有提议的数组

    // 修饰符，限制只有所有者可以调用
    modifier onlyOwner() {
        require(isOwner[msg.sender],"Not an owner"); // 验证调用者是否为所有者
        _;
    }

    // 构造函数，初始化所有者和所需签名数
    constructor(address[] memory _owners, uint _requiredSignatures) {
        require(_owners.length > 0,"Owners required"); // 确保至少有一个所有者
        require(_requiredSignatures > 0 && _requiredSignatures <= _owners.length,"Invalid number of required signatures"); // 验证签名数量有效性

        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]],"Duplicate owner"); // 确保没有重复的所有者
            isOwner[_owners[i]] = true; // 标记为所有者
        }
        owners = _owners; // 初始化所有者列表
        requiredSignatures = _requiredSignatures; // 设置所需签名数
    }

    // 提交提议，只有所有者可以调用
    function submitProposal(address _to, uint _value, bytes memory _data) public onlyOwner {
        Proposal storage proposal = proposals.push(); // 创建新提议并添加到数组
        proposal.to = _to; // 设置提议的目标地址
        proposal.value = _value; // 设置提议的金额
        proposal.data = _data; // 设置附加数据
        proposal.confirmations = 0; // 初始化确认数
        proposal.executed = false; // 初始化执行状态
    }

    // 确认提议，只有所有者可以调用
    function confirmProposal(uint proposalIndex) public onlyOwner {
        Proposal storage proposal = proposals[proposalIndex]; // 获取提议
        require(!proposal.executed,"Proposal already executed"); // 确保提议未被执行
        require(!proposal.isConfirmed[msg.sender],"Already confirmed"); // 确保调用者未确认过

        proposal.isConfirmed[msg.sender] = true; // 标记为已确认
        proposal.confirmations++; // 增加确认数

        // 如果确认数达到所需数量，则执行提议
        if (proposal.confirmations >= requiredSignatures) {
            executeProposal(proposalIndex);
        }
    }

    // 执行提议，内部函数
    function executeProposal(uint proposalIndex) internal {
        Proposal storage proposal = proposals[proposalIndex]; // 获取提议
        require(proposal.confirmations >= requiredSignatures,"Not enough confirmations"); // 确保确认数足够
        require(!proposal.executed,"Proposal already executed"); // 确保提议未被执行

        proposal.executed = true; // 标记为已执行

        // 调用目标地址并转移资金
        (bool success, ) = proposal.to.call{value: proposal.value}(proposal.data);
        require(success,"Transaction execution failed"); // 确保交易执行成功
    }

    // 接收以太币的函数
    receive() external payable {}
}
