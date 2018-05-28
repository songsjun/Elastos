// Copyright (c) 2012-2018 The Elastos Open Source Project
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef __ELASTOS_SDK_IDCHAINSUBWALLET_H__
#define __ELASTOS_SDK_IDCHAINSUBWALLET_H__

#include "Interface/IIdChainSubWallet.h"
#include "SubWallet.h"

namespace Elastos {
	namespace SDK {

		class IdChainSubWallet : public IIdChainSubWallet, public SubWallet {
		public:
			~IdChainSubWallet();

			virtual nlohmann::json GenerateId(std::string &id, std::string &privateKey);

			virtual std::string getIdValue(const std::string &path);

			virtual std::string SendIdTransaction(
					const std::string &fromAddress,
					const nlohmann::json &payloadJson,
					const nlohmann::json &programJson,
					double fee,
					const std::string &payPassword,
					const std::string &memo);

		protected:
			friend class MasterWallet;

			IdChainSubWallet(const CoinInfo &info,
							 const ChainParams &chainParams,
							 const std::string &payPassword,
							 MasterWallet *parent);

			virtual boost::shared_ptr<Transaction> createTransaction(TxParam *param) const;
		};

	}
}

#endif //__ELASTOS_SDK_IDCHAINSUBWALLET_H__
