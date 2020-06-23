/*
 * Copyright (c) 2019 Elastos Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
#include "MasterWallet.h"
#include "EthSidechainSubWallet.h"
#include <Ethereum/EthereumClient.h>
#include <ethereum/ewm/BREthereumAccount.h>
#include <WalletCore/CoinInfo.h>
#include <Common/ErrorChecker.h>
#include <Common/hash.h>

namespace Elastos {
	namespace ElaWallet {

		EthSidechainSubWallet::~EthSidechainSubWallet() {
		}

		EthSidechainSubWallet::EthSidechainSubWallet(const CoinInfoPtr &info,
													 const ChainConfigPtr &config,
													 MasterWallet *parent,
													 const std::string &netType) :
			SubWallet(netType, parent, config, info) {

			_walletID = _parent->GetID() + ":" + info->GetChainID();

			AccountPtr account = _parent->GetAccount();
			bytes_t pubkey = account->GetETHSCPubKey();
			if (pubkey.empty()) {
				if (!account->HasMnemonic() || account->Readonly()) {
					ErrorChecker::ThrowParamException(Error::UnsupportOperation, "unsupport operation: ethsc pubkey is empty");
				} else {
					if (account->HasPassphrase()) {
						ErrorChecker::ThrowParamException(Error::Other, "need to call IMasterWallet::VerifyPassPhrase() first");
					} else {
						ErrorChecker::ThrowParamException(Error::Other, "need to call IMasterWallet::VerifyPayPassword() first");
					}
				}
			}

			EthereumNetworkPtr network(new EthereumNetwork(netType));
			_client = ClientPtr(new EthereumClient(network, parent->GetDataPath(), pubkey));
		}

		std::string EthSidechainSubWallet::GetTransferID(const EthereumTransferPtr &tx) const {
			bytes_t tid = sha256(bytes_t(tx->getRaw(), sizeof(tx->getRaw())));
			tid.erase(tid.begin() + 4, tid.end());
			return tid.getHex();
		}

		EthereumTransferPtr EthSidechainSubWallet::LookupTransfer(const std::string &tid) const {
			std::vector<EthereumTransferPtr> transfers = _client->_ewm->getWallet()->getTransfers();
			for (size_t i = 0; i < transfers.size(); ++i) {
				if (tid == GetTransferID(transfers[i]))
					return transfers[i];
			}

			return nullptr;
		}

		std::string EthSidechainSubWallet::GetChainID() const {
			return SubWallet::GetChainID();
		}

		nlohmann::json EthSidechainSubWallet::GetBasicInfo() const {
			ArgInfo("{} {}", _walletID, GetFunName());

			EthereumWalletPtr wallet = _client->_ewm->getWallet();
			nlohmann::json j, jinfo;

			jinfo["Symbol"] = wallet->getSymbol();
			jinfo["GasLimit"] = wallet->getDefaultGasLimit();
			jinfo["GasPrice"] = wallet->getDefaultGasPrice();
			jinfo["Account"] = wallet->getAccount()->getPrimaryAddress();
			jinfo["HoldsEther"] = wallet->walletHoldsEther();

			j["Info"] = jinfo;
			j["ChainID"] = _info->GetChainID();

			ArgInfo("r => {}", j.dump());
			return j;
		}

		nlohmann::json EthSidechainSubWallet::GetBalanceInfo() const {
			ArgInfo("{} {}", _walletID, GetFunName());

			nlohmann::json j;
			j["Info"] = "not ready";
			j["Summary"] = nlohmann::json();

			ArgInfo("r => {}", j.dump());
			return j;
		}

		std::string EthSidechainSubWallet::GetBalance() const {
			ArgInfo("{} {}", _walletID, GetFunName());

			std::string balance = _client->_ewm->getWallet()->getBalance();

			ArgInfo("r => {}", balance);
			return balance;
		}

		std::string EthSidechainSubWallet::GetBalanceWithAddress(const std::string &address) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("addr: {}", address);

			std::string primaryAddress = _client->_ewm->getWallet()->getAccount()->getPrimaryAddress();
			std::string balance = "0";
			if (primaryAddress == address)
				balance = _client->_ewm->getWallet()->getBalance();

			ArgInfo("r => {}", balance);
			return balance;
		}

		std::string EthSidechainSubWallet::CreateAddress() {
			ArgInfo("{} {}", _walletID, GetFunName());

			std::string addr = _client->_ewm->getWallet()->getAccount()->getPrimaryAddress();

			ArgInfo("r => {}", addr);
			return addr;
		}

		nlohmann::json EthSidechainSubWallet::GetAllAddress(uint32_t start, uint32_t count, bool internal) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("start: {}", start);
			ArgInfo("count: {}", count);
			ArgInfo("internal: {}", internal);

			std::vector<std::string> addresses;
			addresses.push_back(_client->_ewm->getWallet()->getAccount()->getPrimaryAddress());
			nlohmann::json j;
			j["Addresses"] = addresses;
			j["MaxCount"] = 1;

			ArgInfo("r => {}", j.dump());
			return j;
		}

		nlohmann::json EthSidechainSubWallet::GetAllPublicKeys(uint32_t start, uint32_t count) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("s: {}", start);
			ArgInfo("c: {}", count);

			std::vector<std::string> pubkey;
			pubkey.push_back(_client->_ewm->getWallet()->getAccount()->getPrimaryAddressPublicKey().getHex());
			nlohmann::json j;
			j["PublicKeys"] = pubkey;
			j["MaxCount"] = 1;

			ArgInfo("r => {}", j.dump());
			return j;
		}

		void EthSidechainSubWallet::AddCallback(ISubWalletCallback *subCallback) {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("callback: *");
		}

		void EthSidechainSubWallet::RemoveCallback() {
			ArgInfo("{} {}", _walletID, GetFunName());
		}

		nlohmann::json EthSidechainSubWallet::CreateTransaction(const std::string &fromAddress,
																const std::string &targetAddress,
																const std::string &amount,
																const std::string &memo) {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("from: {}", fromAddress);
			ArgInfo("target: {}", targetAddress);
			ArgInfo("amount: {}", amount);
			ArgInfo("memo: {}", memo);

			nlohmann::json j;

			EthereumTransferPtr tx = _client->_ewm->getWallet()->createTransfer(targetAddress, amount, EthereumAmount::Unit::ETHER_ETHER);

			j["ID"] = GetTransferID(tx);
			j["Fee"] = _client->_ewm->getWallet()->transferEstimatedFee(amount);

			ArgInfo("r => {}", j.dump());

			return j;
		}

		nlohmann::json EthSidechainSubWallet::GetAllUTXOs(uint32_t start, uint32_t count,
														  const std::string &address) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("start: {}", start);
			ArgInfo("cnt: {}", count);
			ArgInfo("addr: {}", address);

			nlohmann::json j;

			ArgInfo("r => {}", j.dump());

			return j;
		}

		nlohmann::json EthSidechainSubWallet::CreateConsolidateTransaction(const std::string &memo) {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("memo: {}", memo);

			nlohmann::json j;

			ArgInfo("r => {}", j.dump());
			return j;
		}

		nlohmann::json EthSidechainSubWallet::SignTransaction(const nlohmann::json &tx,
															  const std::string &payPassword) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("tx: {}", tx.dump());
			ArgInfo("passwd: *");

			std::string tid;
			EthereumTransferPtr transfer;
			if (tx.find("ID") == tx.end())
				ErrorChecker::ThrowParamException(Error::InvalidArgument, "'ID' not found in json");

			try {
				tid = tx["ID"].get<std::string>();
				transfer = LookupTransfer(tid);
			} catch (const std::exception &e) {
				ErrorChecker::ThrowParamException(Error::InvalidArgument, "get 'ID' of json failed");
			}

			ErrorChecker::CheckParam(transfer == nullptr, Error::InvalidArgument, "transfer " + tid + " not found");

			uint512 seed = _parent->GetAccount()->GetSeed(payPassword);
			BRKey prvkey = derivePrivateKeyFromSeed(*(UInt512 *)seed.begin(), 0);
			_client->_ewm->getWallet()->signWithPrivateKey(transfer, prvkey);

			nlohmann::json j = tx;
			j["Hash"] = transfer->getOriginationTransactionHash();

			ArgInfo("r => {}", j.dump());
			return j;
		}

		nlohmann::json EthSidechainSubWallet::GetTransactionSignedInfo(const nlohmann::json &tx) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("tx: {}", tx.dump());

			nlohmann::json j;

			ArgInfo("r => {}", j.dump());

			return j;
		}

		nlohmann::json EthSidechainSubWallet::PublishTransaction(const nlohmann::json &tx) {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("tx: {}", tx.dump());

			std::string tid;
			EthereumTransferPtr transfer;
			if (tx.find("ID") == tx.end())
				ErrorChecker::ThrowParamException(Error::InvalidArgument, "'ID' not found in json");

			try {
				tid = tx["ID"].get<std::string>();
				transfer = LookupTransfer(tid);
			} catch (const std::exception &e) {
				ErrorChecker::ThrowParamException(Error::InvalidArgument, "get 'ID' of json failed");
			}
			ErrorChecker::CheckParam(transfer == nullptr, Error::InvalidArgument, "transfer " + tid + " not found");

			_client->_ewm->getWallet()->submit(transfer);

			nlohmann::json j = tx;
			j["Hash"] = transfer->getOriginationTransactionHash();

			ArgInfo("r => {}", j.dump());
			return j;
		}

		std::string EthSidechainSubWallet::ConvertToRawTransaction(const nlohmann::json &tx) {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("tx: {}", tx.dump());

			ArgInfo("r => ");
			return "";
		}

		nlohmann::json EthSidechainSubWallet::GetAllTransaction(uint32_t start, uint32_t count,
																const std::string &txid) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("start: {}, cnt: {}, txid: {}", start, count, txid);

			nlohmann::json j;

			ArgInfo("r => {}", j.dump());

			return j;
		}

		nlohmann::json EthSidechainSubWallet::GetAllCoinBaseTransaction(uint32_t start, uint32_t count,
																		const std::string &txID) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("start: {}, cnt: {}, txid: {}", start, count, txID);

			return nlohmann::json();
		}

		nlohmann::json EthSidechainSubWallet::GetAssetInfo(const std::string &assetID) const {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("asset: {}", assetID);

			nlohmann::json j;

			ArgInfo("r => {}", j.dump());
			return j;
		}

		bool EthSidechainSubWallet::SetFixedPeer(const std::string &address, uint16_t port) {
			ArgInfo("{} {}", _walletID, GetFunName());
			ArgInfo("addr: {}, port: {}", address, port);

			ArgInfo("r => false");
			return false;
		}

		void EthSidechainSubWallet::SyncStart() {
			ArgInfo("{} {}", _walletID, GetFunName());
			_client->_ewm->connect();
		}

		void EthSidechainSubWallet::SyncStop() {
			ArgInfo("{} {}", _walletID, GetFunName());
			_client->_ewm->disconnect();
		}

		void EthSidechainSubWallet::Resync() {
			ArgInfo("{} {}", _walletID, GetFunName());

		}

		void EthSidechainSubWallet::StartP2P() {
			_client->_ewm->connect();
		}

		void EthSidechainSubWallet::StopP2P() {
			_client->_ewm->disconnect();
		}

		void EthSidechainSubWallet::FlushData() {

		}

	}
}