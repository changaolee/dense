// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract DataRepository {

    struct Data {
        string hash;  // 数据明文的哈希值
        string kcph;  // 使用 Pa 加密的 k 和 addr
        bool valid;  // 标记位，用于判断数据是否有效
    }

    // 全量数据：mapping 用于对数据去重，string[] 用于数据遍历
    mapping(address => mapping(string => Data)) dataMap;
    mapping(address => string[]) dataList;

    // 授权情况：数据拥有者 => (数据哈希 => (被授权用户 => 重加密数据))
    mapping(address => mapping(string => mapping(address => string))) authzStatus;

    event Upload(address indexed operator, string indexed hash);  // 上传数据事件
    event Share(address indexed operator, string indexed hash, address indexed to);  // 共享数据事件

    error RepeatUpload(address sender, string hash);  // 重复上传数据
    error NotExists(address owner, string hash);  // 数据不存在
    error NotAuthorized(address sender, address owner, string hash);  // 未被授权查看数据

    // 保证每个用户相同的数据只能上传一次
    modifier uniqueUpload(string calldata _hash) {
        if (dataMap[msg.sender][_hash].valid) {
            revert RepeatUpload(msg.sender, _hash);
        }
        _;
    }

    // 保证要查看的数据存在
    modifier dataExists(address _owner, string calldata _hash) {
        if (!dataMap[_owner][_hash].valid) {
            revert NotExists(_owner, _hash);
        }
        _;
    }

    // 保证数据访问者有访问权限
    modifier ownerOrAuthorized(address _owner, string calldata _hash) {
        if (msg.sender != _owner && bytes(authzStatus[_owner][_hash][msg.sender]).length == 0) {
            revert NotAuthorized(msg.sender, _owner, _hash);
        }
        _;
    }
    
    /**
     * 上传数据
     * _hash: 数据明文的哈希值
     * _kcph: 使用 Pa 加密的 k 和 addr
     */
    function uploadData(string calldata _hash, string calldata _kcph)
        external
        uniqueUpload(_hash)
    {
        dataMap[msg.sender][_hash] = Data({hash: _hash, kcph: _kcph, valid: true});
        dataList[msg.sender].push(_hash);

        emit Upload(msg.sender, _hash);
    }

    /**
     * 查看数据
     * _owner: 数据拥有者
     * _hash: 数据明文的哈希值
     */
    function viewData(address _owner, string calldata _hash)
        external
        view
        dataExists(_owner, _hash)
        ownerOrAuthorized(_owner, _hash)
        returns (string memory kcph, string memory hash)
    {
        Data memory data = dataMap[_owner][_hash];
        hash = _hash;
        if (msg.sender == _owner) {
            kcph = data.kcph;
        } else {
            kcph = authzStatus[_owner][_hash][msg.sender];
        }
    }

    /**
     * 共享数据
     * _to: 被共享者地址
     * _hash: 被共享数据哈希值
     * _rkcph: 被重加密的数据
     */
     function shareData(address _to, string calldata _hash, string calldata _rkcph)
        external
        dataExists(msg.sender, _hash)
    {
        authzStatus[msg.sender][_hash][_to] = _rkcph;

        emit Share(msg.sender, _hash, _to);
    }

    /**
     * 列出拥有的数据
     */
    function listOwnedData()
        external
        view
        returns (string[] memory hashlist)
    {
        hashlist = dataList[msg.sender];
    }
}