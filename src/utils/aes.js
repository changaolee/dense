import CryptoJS from "crypto-js";

export default {
    /**
     * 随机生成秘钥
     * @param n {int} 密钥位数
     */
    generateKey(n = 64) {
        var chars = [
            "0", "1", "2", "3", "4",
            "5", "6", "7", "8", "9",
            "A", "B", "C", "D", "E", "F",
        ];
        var res = "";
        for (var i = 0; i < n; i++) {
            var id = Math.floor(Math.random() * chars.length);
            res += chars[id];
        }
        return res;
    },

    /**
     * AES-256-ECB 对称加密
     * @param text {string} 要加密的明文
     * @param secretKey {string} 密钥，43位随机大小写与数字
     * @returns {string} 加密后的密文，Base64格式
     */
    encrypt(text, secretKey) {
        var keyHex = CryptoJS.enc.Base64.parse(secretKey);
        var messageHex = CryptoJS.enc.Utf8.parse(text);
        var encrypted = CryptoJS.AES.encrypt(messageHex, keyHex, {
            mode: CryptoJS.mode.ECB,
            padding: CryptoJS.pad.Pkcs7,
        });
        return encrypted.toString();
    },

    /**
     * AES-256-ECB 对称解密
     * @param textBase64 {string} 要解密的密文，Base64格式
     * @param secretKey {string} 密钥，43位随机大小写与数字
     * @returns {string} 解密后的明文
     */
    decrypt(textBase64, secretKey) {
        var keyHex = CryptoJS.enc.Base64.parse(secretKey);
        var decrypt = CryptoJS.AES.decrypt(textBase64, keyHex, {
            mode: CryptoJS.mode.ECB,
            padding: CryptoJS.pad.Pkcs7,
        });
        return CryptoJS.enc.Utf8.stringify(decrypt);
    }
};
