export default function ether (n) {
    return new web3.BigNumber(web3toWei(n, 'ether'));
}