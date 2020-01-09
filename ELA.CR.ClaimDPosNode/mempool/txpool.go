// Copyright (c) 2017-2019 The Elastos Foundation
// Use of this source code is governed by an MIT
// license that can be found in the LICENSE file.
//

package mempool

import (
	"bytes"
	"errors"
	"fmt"
	"sync"

	"github.com/elastos/Elastos.ELA/blockchain"
	. "github.com/elastos/Elastos.ELA/common"
	"github.com/elastos/Elastos.ELA/common/config"
	"github.com/elastos/Elastos.ELA/common/log"
	. "github.com/elastos/Elastos.ELA/core/types"
	"github.com/elastos/Elastos.ELA/core/types/outputpayload"
	"github.com/elastos/Elastos.ELA/core/types/payload"
	"github.com/elastos/Elastos.ELA/elanet/pact"
	elaerr "github.com/elastos/Elastos.ELA/errors"
	"github.com/elastos/Elastos.ELA/events"
)

type TxPool struct {
	conflictManager
	chainParams *config.Params

	sync.RWMutex
	txnList map[Uint256]*Transaction // transaction which have been verifyed will put into this map

	txnListSize int
}

//append transaction to txnpool when check ok.
//1.check  2.check with ledger(db) 3.check with pool
func (mp *TxPool) AppendToTxPool(tx *Transaction) elaerr.ELAError {
	mp.Lock()
	defer mp.Unlock()
	err := mp.appendToTxPool(tx)
	if err != nil {
		return err
	}

	go events.Notify(events.ETTransactionAccepted, tx)
	return nil
}

func (mp *TxPool) appendToTxPool(tx *Transaction) elaerr.ELAError {
	txHash := tx.Hash()

	// Don't accept the transaction if it already exists in the pool.  This
	// applies to orphan transactions as well.  This check is intended to
	// be a quick check to weed out duplicates.
	if _, ok := mp.txnList[txHash]; ok {
		return elaerr.Simple(elaerr.ErrTxDuplicate, nil)
	}

	if tx.IsCoinBaseTx() {
		log.Warnf("coinbase tx %s cannot be added into transaction pool", tx.Hash())
		return elaerr.Simple(elaerr.ErrBlockIneffectiveCoinbase, nil)
	}

	chain := blockchain.DefaultLedger.Blockchain
	bestHeight := blockchain.DefaultLedger.Blockchain.GetHeight()
	if errCode := chain.CheckTransactionSanity(bestHeight+1, tx); errCode != nil {
		log.Warn("[TxPool CheckTransactionSanity] failed", tx.Hash())
		return errCode
	}
	references, err := chain.UTXOCache.GetTxReference(tx)
	if err != nil {
		log.Warn("[CheckTransactionContext] get transaction reference failed")
		return elaerr.Simple(elaerr.ErrTxUnknownReferredTx, nil)
	}
	if errCode := chain.CheckTransactionContext(bestHeight+1, tx, references); errCode != nil {
		log.Warn("[TxPool CheckTransactionContext] failed", tx.Hash())
		return errCode
	}
	//verify transaction by pool with lock
	if errCode := mp.verifyTransactionWithTxnPool(tx); errCode != nil {
		log.Warn("[TxPool verifyTransactionWithTxnPool] failed", tx.Hash())
		return errCode
	}

	size := tx.GetSize()
	if mp.txnListSize+size > pact.MaxTxPoolSize {
		log.Warn("TxPool check transactions size failed", tx.Hash())
		return elaerr.Simple(elaerr.ErrTxPoolOverCapacity, nil)
	}

	if errCode := mp.AppendTx(tx); errCode != nil {
		log.Warn("[TxPool verifyTransactionWithTxnPool] failed", tx.Hash())
		return errCode
	}

	// Add the transaction to mem pool
	mp.txnList[txHash] = tx
	mp.txnListSize += size

	return nil
}

// HaveTransaction returns if a transaction is in transaction pool by the given
// transaction id. If no transaction match the transaction id, return false
func (mp *TxPool) HaveTransaction(txId Uint256) bool {
	mp.RLock()
	_, ok := mp.txnList[txId]
	mp.RUnlock()
	return ok
}

// GetTxsInPool returns a slice of all transactions in the mp.
//
// This function is safe for concurrent access.
func (mp *TxPool) GetTxsInPool() []*Transaction {
	mp.RLock()
	txs := make([]*Transaction, 0, len(mp.txnList))
	for _, tx := range mp.txnList {
		txs = append(txs, tx)
	}
	mp.RUnlock()
	return txs
}

//clean the trasaction Pool with committed block.
func (mp *TxPool) CleanSubmittedTransactions(block *Block) {
	mp.Lock()
	mp.cleanTransactions(block.Transactions)
	mp.cleanSideChainPowTx()
	if err := mp.cleanCanceledProducerAndCR(block.Transactions); err != nil {
		log.Warn("error occurred when clean canceled producer and cr", err)
	}
	mp.Unlock()
}

func (mp *TxPool) cleanTransactions(blockTxs []*Transaction) {
	txsInPool := len(mp.txnList)
	deleteCount := 0
	for _, blockTx := range blockTxs {
		if blockTx.TxType == CoinBase {
			continue
		}

		if blockTx.IsNewSideChainPowTx() || blockTx.IsUpdateVersion() {
			if _, ok := mp.txnList[blockTx.Hash()]; ok {
				mp.doRemoveTransaction(blockTx.Hash(), blockTx.GetSize())
				deleteCount++
			}
			continue
		}

		inputUtxos, err := blockchain.DefaultLedger.Blockchain.UTXOCache.GetTxReference(blockTx)
		if err != nil {
			log.Infof("Transaction=%s not exist when deleting, %s.",
				blockTx.Hash(), err)
			continue
		}
		for input := range inputUtxos {
			// we search transactions in transaction pool which have the same utxos with those transactions
			// in block. That is, if a transaction in the new-coming block uses the same utxo which a transaction
			// in transaction pool uses, then the latter one should be deleted, because one of its utxos has been used
			// by a confirmed transaction packed in the new-coming block.
			if tx := mp.getInputUTXOList(input); tx != nil {
				if tx.Hash() == blockTx.Hash() {
					// it is evidently that two transactions with the same transaction id has exactly the same utxos with each
					// other. This is a special case of what we've said above.
					log.Debugf("duplicated transactions detected when adding a new block. "+
						" Delete transaction in the transaction pool. Transaction id: %s", tx.Hash())
				} else {
					log.Debugf("double spent UTXO inputs detected in transaction pool when adding a new block. "+
						"Delete transaction in the transaction pool. "+
						"block transaction hash: %s, transaction hash: %s, the same input: %s, index: %d",
						blockTx.Hash(), tx.Hash(), input.Previous.TxID, input.Previous.Index)
				}

				//1.remove from txnList
				mp.doRemoveTransaction(tx.Hash(), tx.GetSize())

				deleteCount++
			}
		}

		if err := mp.RemoveTx(blockTx); err != nil {
			log.Warnf("remove tx %s when delete", blockTx.Hash())
		}
	}
	log.Debug(fmt.Sprintf("[cleanTransactionList],transaction %d in block, %d in transaction pool before, %d deleted,"+
		" Remains %d in TxPool",
		len(blockTxs), txsInPool, deleteCount, len(mp.txnList)))
}

func (mp *TxPool) cleanCanceledProducerAndCR(txs []*Transaction) error {
	for _, txn := range txs {
		if txn.TxType == CancelProducer {
			cpPayload, ok := txn.Payload.(*payload.ProcessProducer)
			if !ok {
				return errors.New("invalid cancel producer payload")
			}
			if err := mp.cleanVoteAndUpdateProducer(cpPayload.OwnerPublicKey); err != nil {
				log.Error(err)
			}
		}
		if txn.TxType == UnregisterCR {
			crPayload, ok := txn.Payload.(*payload.UnregisterCR)
			if !ok {
				return errors.New("invalid cancel producer payload")
			}
			if err := mp.cleanVoteAndUpdateCR(crPayload.DID); err != nil {
				log.Error(err)
			}
		}
	}

	return nil
}

func (mp *TxPool) cleanVoteAndUpdateProducer(ownerPublicKey []byte) error {
	for _, txn := range mp.txnList {
		if txn.TxType == TransferAsset {
		end:
			for _, output := range txn.Outputs {
				if output.Type == OTVote {
					opPayload, ok := output.Payload.(*outputpayload.VoteOutput)
					if !ok {
						return errors.New("invalid vote output payload")
					}
					for _, content := range opPayload.Contents {
						if content.VoteType == outputpayload.Delegate {
							for _, cv := range content.CandidateVotes {
								if bytes.Equal(ownerPublicKey, cv.Candidate) {
									mp.removeTransaction(txn)
									break end
								}
							}
						}
					}
				}
			}
		} else if txn.TxType == UpdateProducer {
			upPayload, ok := txn.Payload.(*payload.ProducerInfo)
			if !ok {
				return errors.New("invalid update producer payload")
			}
			if bytes.Equal(upPayload.OwnerPublicKey, ownerPublicKey) {
				mp.removeTransaction(txn)
				if err := mp.RemoveKey(
					BytesToHexString(upPayload.OwnerPublicKey),
					slotDPoSOwnerPublicKey); err != nil {
					return err
				}
				if err := mp.RemoveKey(
					BytesToHexString(upPayload.NodePublicKey),
					slotDPoSNodePublicKey); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

func (mp *TxPool) cleanVoteAndUpdateCR(did Uint168) error {
	for _, txn := range mp.txnList {
		if txn.TxType == TransferAsset {
			for _, output := range txn.Outputs {
				if output.Type == OTVote {
					opPayload, ok := output.Payload.(*outputpayload.VoteOutput)
					if !ok {
						return errors.New("invalid vote output payload")
					}
					for _, content := range opPayload.Contents {
						if content.VoteType == outputpayload.CRC {
							for _, cv := range content.CandidateVotes {
								if bytes.Equal(did.Bytes(), cv.Candidate) {
									mp.removeTransaction(txn)
								}
							}
						}
					}
				}
			}
		} else if txn.TxType == UpdateCR {
			crPayload, ok := txn.Payload.(*payload.CRInfo)
			if !ok {
				return errors.New("invalid update CR payload")
			}
			if did.IsEqual(crPayload.DID) {
				mp.removeTransaction(txn)
				if err := mp.RemoveKey(crPayload.DID, slotCRDID); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

//get the transaction by hash
func (mp *TxPool) GetTransaction(hash Uint256) *Transaction {
	mp.RLock()
	defer mp.RUnlock()
	return mp.txnList[hash]
}

//verify transaction with txnpool
func (mp *TxPool) verifyTransactionWithTxnPool(
	txn *Transaction) elaerr.ELAError {
	if txn.IsSideChainPowTx() {
		// check and replace the duplicate sidechainpow tx
		mp.replaceDuplicateSideChainPowTx(txn)
	}

	return mp.VerifyTx(txn)
}

//remove from associated map
func (mp *TxPool) removeTransaction(tx *Transaction) {
	//1.remove from txnList
	if _, ok := mp.txnList[tx.Hash()]; ok {
		mp.doRemoveTransaction(tx.Hash(), tx.GetSize())
	}
}

func (mp *TxPool) IsDuplicateSidechainTx(sidechainTxHash Uint256) bool {
	mp.RLock()
	defer mp.RUnlock()
	return mp.ContainsKey(sidechainTxHash, slotSidechainTxHashes)
}

// check and replace the duplicate sidechainpow tx
func (mp *TxPool) replaceDuplicateSideChainPowTx(txn *Transaction) {
	var replaceList []*Transaction

	for _, v := range mp.txnList {
		if v.TxType == SideChainPow {
			oldPayload := v.Payload.Data(payload.SideChainPowVersion)
			oldGenesisHashData := oldPayload[32:64]

			newPayload := txn.Payload.Data(payload.SideChainPowVersion)
			newGenesisHashData := newPayload[32:64]

			if bytes.Equal(oldGenesisHashData, newGenesisHashData) {
				replaceList = append(replaceList, v)
			}
		}
	}

	for _, txn := range replaceList {
		txid := txn.Hash()
		log.Info("replace sidechainpow transaction, txid=", txid.String())
		mp.removeTransaction(txn)
	}
}

// clean the sidechainpow tx pool
func (mp *TxPool) cleanSideChainPowTx() {
	for hash, txn := range mp.txnList {
		if txn.IsSideChainPowTx() {
			arbiter := blockchain.DefaultLedger.Arbitrators.GetOnDutyCrossChainArbitrator()
			if err := blockchain.CheckSideChainPowConsensus(txn, arbiter); err != nil {
				// delete tx
				mp.doRemoveTransaction(hash, txn.GetSize())
			}
		}
	}
}

func (mp *TxPool) GetTransactionCount() int {
	mp.RLock()
	defer mp.RUnlock()
	return len(mp.txnList)
}

func (mp *TxPool) getInputUTXOList(input *Input) *Transaction {
	return mp.GetTx(input.ReferKey(), slotTxInputsReferKeys)
}

func (mp *TxPool) MaybeAcceptTransaction(tx *Transaction) error {
	mp.Lock()
	defer mp.Unlock()
	return mp.appendToTxPool(tx)
}

func (mp *TxPool) RemoveTransaction(txn *Transaction) {
	mp.Lock()
	txHash := txn.Hash()
	for i := range txn.Outputs {
		input := Input{
			Previous: OutPoint{
				TxID:  txHash,
				Index: uint16(i),
			},
		}

		txn := mp.getInputUTXOList(&input)
		if txn != nil {
			mp.removeTransaction(txn)
		}
	}
	mp.Unlock()
}

func (mp *TxPool) doRemoveTransaction(hash Uint256, txSize int) {
	if _, exist := mp.txnList[hash]; exist {
		delete(mp.txnList, hash)
		mp.txnListSize -= txSize
	}
}

func NewTxPool(params *config.Params) *TxPool {
	return &TxPool{
		conflictManager: newConflictManager(),
		chainParams:     params,
		txnList:         make(map[Uint256]*Transaction),
	}
}
