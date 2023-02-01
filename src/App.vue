<template>
  <div class="common-layout">
    <el-container>
      <el-main>
        <el-card class="box-card">
          <el-descriptions
            title="DENSE - 数据存证共享仓库"
            direction="vertical"
            :column="2"
            border
          >
            <el-descriptions-item label="合约地址">{{ address }}</el-descriptions-item>
            <el-descriptions-item label="网络类型">{{ network }}</el-descriptions-item>
            <el-descriptions-item label="RSA 私钥">{{ privateKey }}</el-descriptions-item>
            <el-descriptions-item label="当前账号">{{ account }}</el-descriptions-item>
            <el-descriptions-item label="RSA 公钥">{{ publicKey }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="box-card">
              <el-divider content-position="left">上传数据</el-divider>
              <el-form label-width="120px">
                <el-input
                  v-model="uploadedData"
                  :rows="4"
                  type="textarea"
                  placeholder="填写原始数据..."
                />
              </el-form>
              <el-row :gutter="20">
                <el-col :span="4" :offset="20">
                  <el-button @click="upload" type="primary" class="btn authzBtn"
                    >上传</el-button
                  >
                </el-col>
              </el-row>
            </el-card>

            <el-card class="box-card">
              <el-divider content-position="left">授权数据</el-divider>
              <el-form label-width="120px">
                <el-form-item label="被授权用户钱包">
                  <el-input v-model="authzWalletAddress" />
                </el-form-item>
                <el-form-item label="被授权用户公钥">
                  <el-input v-model="authzPublicKey" />
                </el-form-item>
                <el-form-item label="被授权数据哈希">
                  <el-input v-model="authzDataHash" />
                </el-form-item>
              </el-form>
              <el-row :gutter="20">
                <el-col :span="4" :offset="20">
                  <el-button @click="authzData" type="primary" class="btn"
                    >授权</el-button
                  >
                </el-col>
              </el-row>
            </el-card>

            <el-card class="box-card">
              <el-divider content-position="left">查看本人或被授权数据</el-divider>
              <el-form label-width="120px">
                <el-form-item label="数据哈希">
                  <el-input v-model="viewDataHash" />
                </el-form-item>
                <el-form-item label="数据拥有者">
                  <el-input v-model="viewDataOwner" placeholder="默认为当前用户" />
                </el-form-item>
              </el-form>
              <el-row :gutter="20">
                <el-col :span="4" :offset="20">
                  <el-button @click="viewData" type="primary" class="btn">查看</el-button>
                </el-col>
              </el-row>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card
              class="box-card"
              v-if="
                debug.rows != undefined && debug.rows != null && debug.rows.length > 0
              "
            >
              <el-descriptions title="调试日志" :column="1">
                <el-descriptions-item
                  v-for="row in debug.rows"
                  v-bind:label="row.key"
                  :key="row.key"
                >
                  {{ row.value }}
                </el-descriptions-item>
              </el-descriptions>
            </el-card>
            <el-card class="box-card">
              <el-divider content-position="left">已上传数据列表</el-divider>
              <el-card class="box-card" v-for="row in ownedData.rows" :key="row.hash">
                {{ row.hash }}
              </el-card>
            </el-card>
          </el-col>
        </el-row>
      </el-main>
    </el-container>
  </div>
</template>

<style>
.authzBtn {
  margin-top: 20px;
}
.btn {
  float: right;
}
.box-card {
  margin-bottom: 10px;
}
</style>

<script>
import Web3 from "web3";
import Keccak256 from "keccak256";
import AES from "./utils/aes";
import { ElMessage } from "element-plus";

const Proxy = require("proxy-recrypt-js").Proxy;
const PRE = require("proxy-recrypt-js");
const CryptoJS = require("crypto-js");

const contract = require("@truffle/contract");
const dataRepositoryArtifact = require("../build/contracts/DataRepository.json");

const ADDRESS = "0xC9Ab57514A1F944750cCA1F52eB1e34505925E3f";

const DEV_WALLET_A = "0xa04004f21F252F6683F81b83C0480F468F884c92";
const DEV_PRIVATE_KEY_A =
  "7e940152578eb6181e5063181d41e820311fe75c09995f439031e1babbe834b4";
const DEV_PUBLIC_KEY_A =
  "04463507ffe6d920ce8f3bb6ee32c0286dc771ae9e5047db8c7c99e2e7c4d73df443402b94f14839db1a4d592f47b77d9c0a02d44c08a9cbfa277e20a9bde60b44";

const DEV_WALLET_B = "0x4D987F306882255aDb5574E8075d759D63FF749E";
const DEV_PRIVATE_KEY_B =
  "e736caf2bb37b79f075c24b91f2513caf1a70f7844a7333183aab317dad0cef6";
const DEV_PUBLIC_KEY_B =
  "0461dec89bbf42361130788e4b376bc6d6d954b9657621919b7431a8062d8208708150d8818b2775701a38594961632a0172caf77b0392af3377d0abc160926354";

export default {
  name: "App",

  data() {
    return {
      connected: false,
      account: "",
      address: "",
      network: "",
      privateKey: "",
      publicKey: "",
      uploadedData: "",
      authzWalletAddress: "",
      authzPublicKey: "",
      authzDataHash: "",
      viewDataHash: "",
      viewDataOwner: "",
      ownedData: {
        type: Object,
        required: true,
      },
      debug: {
        type: Object,
        required: true,
      },
    };
  },

  async created() {
    await this.initialization();
  },

  methods: {
    async initialization() {
      if (window.ethereum) {
        this.provider = window.ethereum;

        // 连接钱包
        await window.ethereum.request({ method: "eth_requestAccounts" }).then(() => {
          this.connected = true;
        });

        this.web3 = new Web3(this.provider);
        this.web3.eth.getAccounts().then((accs) => {
          this.account = accs[0];
        });
        this.web3.eth.net.getNetworkType().then((net) => {
          this.network = net;
        });

        // 获取合约
        this.address = ADDRESS;
        const dataRepository = contract(dataRepositoryArtifact);
        dataRepository.setProvider(this.provider);
        this.dataRepository = await dataRepository.at(this.address);

        // 生成密钥对
        if (this.account == DEV_WALLET_A) {
          this.privateKey = DEV_PRIVATE_KEY_A;
          this.publicKey = DEV_PUBLIC_KEY_A;
        } else if (this.account == DEV_WALLET_B) {
          this.privateKey = DEV_PRIVATE_KEY_B;
          this.publicKey = DEV_PUBLIC_KEY_B;
        } else {
          var kp = Proxy.generate_key_pair();
          this.privateKey = Proxy.to_hex(kp.get_private_key().to_bytes());
          this.publicKey = Proxy.to_hex(kp.get_public_key().to_bytes());
        }

        this.listOwnedData();
        this.debug.rows = [];
      }
    },

    upload() {
      if (this.uploadedData.length == 0) {
        ElMessage.error("不允许上传空数据");
        return;
      }

      let M = this.uploadedData;
      this.log("接收明文 M", M, true);

      let hash = Keccak256(M).toString("hex");
      this.log("计算 M 的哈希值 hash", hash);

      let k = AES.generateKey();
      this.log("随机生成对称密钥 k", k);

      let cph = AES.encrypt(M, k);
      this.log("基于 k 计算 M 的密文 cph", cph);

      // this.log("测试对 cph 解密", AES.decrypt(cph, k));

      let plaintext = JSON.stringify({ k: k, cph: cph });
      let KcphObj = PRE.encryptData(this.publicKey, plaintext);
      let Kcph = CryptoJS.enc.Base64.stringify(
        CryptoJS.enc.Utf8.parse(JSON.stringify(KcphObj))
      );
      this.log("使用 RSA 公钥加密 k 和 cph 得到 Kcph", Kcph);

      // let testObj = JSON.parse(
      //   CryptoJS.enc.Base64.parse(Kcph).toString(CryptoJS.enc.Utf8)
      // );
      // let testKcph = PRE.decryptData(this.privateKey, testObj);
      // testKcph = testKcph.toString(CryptoJS.enc.Utf8);
      // this.log("测试对 Kcph 解密", testKcph);

      this.log("将 Kcph 和 hash 一起上传至区块链", "...");
      this.dataRepository.uploadData(hash, Kcph, { from: this.account }).then(() => {
        this.log("上传成功", "!!!");
        this.listOwnedData();
      });
    },

    authzData() {
      if (this.authzWalletAddress.length == 0) {
        ElMessage.error("请填写被授权用户钱包地址");
        return;
      }
      if (this.authzPublicKey.length == 0) {
        ElMessage.error("请填写被授权用户公钥");
        return;
      }
      if (this.authzDataHash.length == 0) {
        ElMessage.error("请填写被授权数据哈希");
        return;
      }

      this.log("接收到被授权用户钱包地址", this.authzWalletAddress, true);
      this.log("接收到被授权用户公钥", this.authzPublicKey);
      this.log("接收到被授权数据哈希", this.authzDataHash);

      this.dataRepository
        .viewData(this.account, this.authzDataHash, { from: this.account })
        .then((r) => {
          let Kcph = r.kcph;
          this.log("获取链上数据 Kcph", Kcph);

          let cpk = PRE.generateReEncrytionKey(this.privateKey, this.authzPublicKey);
          this.log("生成重加密 key", cpk);

          let KcphObj = JSON.parse(
            CryptoJS.enc.Base64.parse(Kcph).toString(CryptoJS.enc.Utf8)
          );
          PRE.reEncryption(cpk, KcphObj);
          let rKcph = CryptoJS.enc.Base64.stringify(
            CryptoJS.enc.Utf8.parse(JSON.stringify(KcphObj))
          );
          this.log("计算重加密数据 rKcph", rKcph);

          this.log("将重加密数据 rKcph 上传至区块链", "...");
          this.dataRepository
            .shareData(this.authzWalletAddress, this.authzDataHash, rKcph, {
              from: this.account,
            })
            .then(() => {
              this.log("上传成功", "!!!");
            });
        });
    },

    viewData() {
      if (this.viewDataHash.length == 0) {
        ElMessage.error("请填写数据哈希");
        return;
      }
      if (this.viewDataOwner.length == 0) {
        this.viewDataOwner = this.account;
      }

      this.log("接收到数据哈希", this.viewDataHash, true);
      this.log("接收到数据拥有者", this.viewDataOwner);

      this.dataRepository
        .viewData(this.viewDataOwner, this.viewDataHash, { from: this.account })
        .then((r) => {
          let Kcph = r.kcph;
          let hash = r.hash;
          this.log("获取链上数据 Kcph", Kcph);
          this.log("获取数据哈希 hash", hash);

          let KcphObj = JSON.parse(
            CryptoJS.enc.Base64.parse(Kcph).toString(CryptoJS.enc.Utf8)
          );
          let plaintext = PRE.decryptData(this.privateKey, KcphObj);
          plaintext = plaintext.toString(CryptoJS.enc.Utf8);
          this.log("对 Kcph 解密", plaintext);

          let plaintextObj = JSON.parse(plaintext);
          let M = AES.decrypt(plaintextObj.cph, plaintextObj.k);
          this.log("使用对称密钥 cph 对 k 解密得到明文 M", M);

          let success = Keccak256(M).toString("hex") == hash;
          this.log("比对数据哈希", success ? "校验成功!!!" : "校验失败...");
        });
    },

    listOwnedData() {
      this.ownedData.rows = [];
      this.dataRepository.listOwnedData({ from: this.account }).then((r) => {
        for (let i = 0; i < r.length; i++) {
          this.ownedData.rows.push({ hash: r[i] });
        }
      });
    },

    log(key, value, reset = false) {
      if (reset) {
        this.debug.idx = 0;
        this.debug.rows = [];
      }
      this.debug.idx++;
      console.log(this.debug.idx + ". " + key + ": " + value);
      if (value.length > 64) {
        value = value.substring(0, 64) + "...";
      }
      this.debug.rows.push({ key: this.debug.idx + ". " + key, value: value });
    },
  },
};
</script>
