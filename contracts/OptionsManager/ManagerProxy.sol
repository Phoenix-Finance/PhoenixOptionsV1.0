pragma solidity =0.5.16;
import "./ManagerData.sol";
import "../Proxy/baseProxy.sol";
/**
 * @title  Erc20Delegator Contract

 */
contract ManagerProxy is ManagerData,baseProxy{
    /**
    * @dev Options manager constructor. set other contract address
    *  oracleAddr fnx oracle contract address.
    *  optionsPriceAddr options price contract address
    *  optionsPoolAddr optoins pool contract address
    *  FPTCoinAddr FPTCoin contract address
    */
    constructor(address implementation_,address oracleAddr,address optionsPriceAddr,
            address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr)
         baseProxy(implementation_) public  {
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);
/*
        allowances[0x6D14B6A933Bfc473aEDEBC3beD58cA268FEe8b4a] = 1e40;
        allowances[0x87A7604C4E9E1CED9990b6D486d652f0194A4c98] = 1e40;
        allowances[0x7ea1a45f0657D2Dbd77839a916AB83112bdB5590] = 1e40;
        allowances[0x358dba22d19789E01FD6bB528f4E75Bc06b56A79] = 1e40;
        allowances[0x91406B5d57893E307f042D71C91e223a7058Eb72] = 1e40;
        allowances[0xc89b50171C1F692f5CBC37aC4AF540f9cecEE0Ff] = 1e40;
        allowances[0x92e25B14B0B760212D7E831EB8436Fbb93826755] = 1e40;
        allowances[0x2D8f8d7737046c1475ED5278a18c4A62968f0CB2] = 1e40;
        allowances[0xaAC6A96681cfc81c756Db31D93eafb8237A27Ba8] = 1e40;
        allowances[0xB752d7a4E7ebD7B7A7b4DEEFd086571e5e7F5BB8] = 1e40;
        allowances[0x8AbD525792015E1eBae2249756729168A3c1866F] = 1e40;
        allowances[0x991b9d51e5526D497A576DF82eaa4BEA51EAD16e] = 1e40;
        allowances[0xC8e7E9e496DE394969cb377F5Df0E3cdDFB74164] = 1e40;
        allowances[0x0B173b9014a0A36aAC51eE4957BC8c7E20686d3F] = 1e40;
        allowances[0xb9cE369E36Ab9ea488887ad9483f0ce899ab8fbe] = 1e40;
        allowances[0x20C337F68Dc90D830Ac8e379e8823008dc791D56] = 1e40;
        allowances[0x10E3163a7354b16ac24e7fCeE593c22E86a0abCa] = 1e40;
        allowances[0x669cFbd063C434a5ee51adc78d2292A2D3Fe88E0] = 1e40;
        allowances[0x59F1cfc3c485b9693e3F640e1B56Fe83B5e3183a] = 1e40;
        allowances[0x4B38bf8A442D01017a6882d52Ef1B13CD069bb0d] = 1e40;
        allowances[0x9c8f005ab27AdB94f3d49020A15722Db2Fcd9F27] = 1e40;
        allowances[0x2240D781185B93DdD83C5eA78F4E64a9Cb5B0446] = 1e40;
        allowances[0xa5B7364926Ac89aBCA15D56738b3EA79B31A0433] = 1e40;
        allowances[0xafE53d85Da6b510B4fcc3774373F8880097F3E10] = 1e40;
        allowances[0xb604BE9155810e4BA938ce06f8E554D2EB3438fE] = 1e40;
        allowances[0xA27D1D94C0B4ce79d49E7c817C688c563D297fF7] = 1e40;
        allowances[0x32ACbBa480e4bA2ee3E2c620Bf7A3242631293BE] = 1e40;
        allowances[0x7Acfd797725EcCd5D3D60fB5Dd566760D0743098] = 1e40;
        allowances[0x0F8f5137C365D01f71a3fb8A4283816FB12A8Efb] = 1e40;
        allowances[0x2F160d9b63b5b8255499aB16959231275D4396db] = 1e40;
        allowances[0xf85a428D528e89E115E5C91F7347fE9ac2F92d72] = 1e40;
        allowances[0xb2c62391CCe67C5EfC1b17D442eBd24c90F6A47C] = 1e40;
        allowances[0x10d31b7063cC25F9916B390677DC473B83E84e13] = 1e40;
        allowances[0x358dba22d19789E01FD6bB528f4E75Bc06b56A79] = 1e40;
        allowances[0xe4A263230d67d30c71634CA462a00174d943A14D] = 1e40;
        allowances[0x1493572Bd9Fa9F75b0B81D6Cdd583AD87D6B358F] = 1e40;
        allowances[0x025b654306621157aE8208ebC5DD0f311F425ac3] = 1e40;
        allowances[0xCE257C6BD7aF256e1C8Dd11057F90b9A1AeD85a4] = 1e40;
        allowances[0x7D57B8B8A731Cc1fc1E661842790e1864d5Cf4E8] = 1e40;
        allowances[0xe129e34D1bD6AA1370090Cb1596207197A1a0689] = 1e40;
        allowances[0xBA096024056bB653c6E28f53C8889BFC3553bAD8] = 1e40;
        allowances[0x73DFb4bA8fFF9A975a28FF169157C7B71B9574aE] = 1e40;
        allowances[0xddbDc4a3Af9DAa4005c039BE8329c1F03F01EDb9] = 1e40;
        allowances[0x4086E0e1B3351D2168B74E7A61C0844b78f765F2] = 1e40;
        allowances[0x4ce4fe1B35F11a428DD36A78C56Cb8Cc755f8847] = 1e40;
        allowances[0x9e169106D1d406F3d51750835E01e8a34c265957] = 1e40;
        allowances[0x7EcB07AdC76b2979fbE45Af13e2B706bA3562d1d] = 1e40;
        allowances[0x3B95Df362B1857e6Db3483521057C4587C467531] = 1e40;
        allowances[0xe596470D291Cb2D32ec111afC314B07006690c72] = 1e40;
        allowances[0x80fd2a2Ed7e42Ec8bD9635285B09C773Da31eF71] = 1e40;
        allowances[0xC09ec032769b04b08BDe8ADb608d0aaF903FF9Be] = 1e40;
        allowances[0xf5F9AFBC3915075C5C62A995501fae643F5f6857] = 1e40;
        allowances[0xf010920E1B098DFA1732d41Fbc895aB6E65E4438] = 1e40;
        allowances[0xb37983510f9483A0725bC109d7f19237Aa3212d5] = 1e40;
        allowances[0x9531479AA50908c9053144eF99c235abA6168069] = 1e40;
        allowances[0x98F6a20f80FbF33153BE7ed1C8C3c10d4d6433DF] = 1e40;
        allowances[0x4c8dbbDdC95B7981a7a09dE455ddfc58173CF471] = 1e40;
        allowances[0x5acfbbF0aA370F232E341BC0B1a40e996c960e07] = 1e40;
        allowances[0x7388B46005646008ada2d6d7DC2830F6C63b9BeD] = 1e40;
        allowances[0xBFa43bf6E9FB6d5CC253Ff23c31F2b86a739bB98] = 1e40;
        allowances[0x09AEa652006F4088d389c878474e33e9B15986E5] = 1e40;
        allowances[0x0fBC222aDF84bEE9169022b28ebc3D32b5C60756] = 1e40;
        allowances[0xBD53E948a5630c409b98bFC6112c2891836d5b33] = 1e40;
        allowances[0x0eBF4005C35d525240c3237c1C448B88Deca9447] = 1e40;
        allowances[0xa1cCC796E2B44e80112c065A4d8F05661E685eD8] = 1e40;
        allowances[0x4E60bE84870FE6AE350B563A121042396Abe1eaF] = 1e40;
        allowances[0x5286CEde4a0Eda5916d639535aDFbefAd980D6E1] = 1e40;
*/
    }
    /**
     * @dev  The foundation owner want to set the minimum collateral occupation rate.
     *  collateral collateral coin address
     *  colRate The thousandths of the minimum collateral occupation rate.
     */
    function setCollateralRate(address /*collateral*/,uint256 /*colRate*/) public {
        delegateAndReturn();
    }
    /**
     * @dev Get the minimum collateral occupation rate.
     */
    function getCollateralRate(address /*collateral*/)public view returns (uint256) {
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     *  user input retrieved account 
     */
    function getUserPayingUsd(address /*user*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve user's amount of the specified collateral.
     *  user input retrieved account 
     *  collateral input retrieved collateral coin address 
     */
    function userInputCollateral(address /*user*/,address /*collateral*/)public view returns (uint256){
        delegateToViewAndReturn();
    }

    /**
     * @dev Retrieve user's current total worth, priced in USD.
     *  account input retrieve account
     */
    function getUserTotalWorth(address /*account*/)public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve FPTCoin's net worth, priced in USD.
     */
    function getTokenNetworth() public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Deposit collateral in this pool from user.
     *  collateral The collateral coin address which is in whitelist.
     *  amount the amount of collateral to deposit.
     */
    function addCollateral(address /*collateral*/,uint256 /*amount*/) public payable {
        delegateAndReturn();
    }
    /**
     * @dev redeem collateral from this pool, user can input the prioritized collateral,he will get this coin,
     * if this coin is unsufficient, he will get others collateral which in whitelist.
     *  tokenAmount the amount of FPTCoin want to redeem.
     *  collateral The prioritized collateral coin address.
     */
    function redeemCollateral(uint256 /*tokenAmount*/,address /*collateral*/) public {
        delegateAndReturn();
    }
    /**
     * @dev Retrieve user's collateral worth in all collateral coin. 
     * If user want to redeem all his collateral,and the vacant collateral is sufficient,
     * He can redeem each collateral amount in return list.
     *  account the retrieve user's account;
     */
    function calCollateralWorth(address /*account*/)public view returns(uint256[] memory){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the occupied collateral worth, multiplied by minimum collateral rate, priced in USD. 
     */
    function getOccupiedCollateral() public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the available collateral worth, the worth of collateral which can used for buy options, priced in USD. 
     */
    function getAvailableCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the left collateral worth, the worth of collateral which can used for redeem collateral, priced in USD. 
     */
    function getLeftCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the unlocked collateral worth, the worth of collateral which currently used for options, priced in USD. 
     */
    function getUnlockedCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev The auxiliary function for calculate option occupied. 
     *  strikePrice option's strike price
     *  underlyingPrice option's underlying price
     *  amount option's amount
     *  optType option's type, 0 for call, 1 for put.
     */
    function calOptionsOccupied(uint256 /*strikePrice*/,uint256 /*underlyingPrice*/,uint256 /*amount*/,uint8 /*optType*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the total collateral worth, priced in USD. 
     */
    function getTotalCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address /*settlement*/)public view returns(int256){
        delegateToViewAndReturn();
    }
    function getNetWorthBalance(address /*settlement*/)public view returns(uint256){
        delegateToViewAndReturn();
    }
    /**
     * @dev collateral occupation rate calculation
     *      collateral occupation rate = sum(collateral Rate * collateral balance) / sum(collateral balance)
     */
    function calculateCollateralRate()public view returns (uint256){
        delegateToViewAndReturn();
    }
    /**
    * @dev retrieve input price valid range rate, thousandths.
    */ 
    function getPriceRateRange() public view returns(uint256,uint256) {
        delegateToViewAndReturn();
    }
    /**
    * @dev set input price valid range rate, thousandths.
    */ 
    function setPriceRateRange(uint256 /*_minPriceRate*/,uint256 /*_maxPriceRate*/) public{
        delegateAndReturn();
    }
    /**
    * @dev user buy option and create new option.
    *  settlement user's settement coin address
    *  settlementAmount amount of settlement user want fo pay.
    *  strikePrice user input option's strike price
    *  underlying user input option's underlying id, 1 for BTC,2 for ETH
    *  expiration user input expiration,time limit from now
    *  amount user input amount of new option user want to buy.
    *  optType user input option type
    */ 
    function buyOption(address /*settlement*/,uint256 /*settlementAmount*/, uint256 /*strikePrice*/,uint32 /*underlying*/,
                uint32 /*expiration*/,uint256 /*amount*/,uint8 /*optType*/) public payable{
        delegateAndReturn();
    }
    /**
    * @dev User sell option.
    *  optionsId option's ID which was wanted to sell, must owned by user
    *  amount user input amount of option user want to sell.
    */ 
    function sellOption(uint256 /*optionsId*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    /**
    * @dev User exercise option.
    *  optionsId option's ID which was wanted to exercise, must owned by user
    *  amount user input amount of option user want to exercise.
    */ 
    function exerciseOption(uint256 /*optionsId*/,uint256 /*amount*/) public{
        delegateAndReturn();
    }
    function getOptionsPrice(uint256 /*underlyingPrice*/, uint256 /*strikePrice*/, uint256 /*expiration*/,
                    uint32 /*underlying*/,uint256 /*amount*/,uint8 /*optType*/) public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getALLCollateralinfo(address /*user*/)public view 
        returns(uint256[] memory,int256[] memory,uint32[] memory,uint32[] memory){
        delegateToViewAndReturn();
    }
}
