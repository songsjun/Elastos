package store

import (
	"bytes"
	"sort"
	"sync"

	"github.com/elastos/Elastos.ELA/blockchain"
	"github.com/elastos/Elastos.ELA/blockchain/interfaces"
	"github.com/elastos/Elastos.ELA/common"
	"github.com/elastos/Elastos.ELA/common/config"
	"github.com/elastos/Elastos.ELA/common/log"
	"github.com/elastos/Elastos.ELA/core/contract"
	"github.com/elastos/Elastos.ELA/core/types"
	"github.com/elastos/Elastos.ELA/events"
)

type ArbitratorsConfig struct {
	ArbitratorsCount uint32
	CandidatesCount  uint32
	CRCArbitrators   []config.CRCArbitratorParams
	Versions         interfaces.HeightVersions
	Store            interfaces.IDposStore
	ChainStore       blockchain.IChainStore
	Emergency        EmergencyConfig
}

type Arbitrators struct {
	cfg              ArbitratorsConfig
	DutyChangedCount uint32

	currentArbitrators [][]byte
	currentCandidates  [][]byte

	currentArbitratorsProgramHashes []*common.Uint168
	currentCandidatesProgramHashes  []*common.Uint168

	nextArbitrators [][]byte
	nextCandidates  [][]byte

	crcArbitratorsProgramHashes map[common.Uint168]interface{}

	emergency *emergencyMechanism

	lock sync.Mutex
}

func (a *Arbitrators) Start() error {
	a.lock.Lock()
	defer a.lock.Unlock()

	a.crcArbitratorsProgramHashes = make(map[common.Uint168]interface{})
	for _, v := range a.cfg.CRCArbitrators {
		hash, err := contract.PublicKeyToStandardProgramHash(v.PublicKey)
		if err != nil {
			return err
		}
		a.crcArbitratorsProgramHashes[*hash] = nil
	}

	block, err := a.cfg.ChainStore.GetBlock(a.cfg.ChainStore.GetCurrentBlockHash())
	if err != nil {
		return err
	}
	if a.cfg.Versions.GetDefaultBlockVersion(block.Height) == 0 {
		if a.currentArbitrators, err = a.cfg.Versions.GetNormalArbitratorsDesc(block); err != nil {
			return err
		}
	} else {
		if err := a.cfg.Store.GetArbitrators(a); err != nil {
			return err
		}
	}

	if err := a.updateArbitratorsProgramHashes(); err != nil {
		return err
	}

	return nil
}

func (a *Arbitrators) ForceChange() error {
	block, err := a.cfg.ChainStore.GetBlock(a.cfg.ChainStore.GetCurrentBlockHash())
	if err != nil {
		return err
	}

	if err = a.updateNextArbitrators(block); err != nil {
		return err
	}

	if err = a.changeCurrentArbitrators(); err != nil {
		return err
	}

	events.Notify(events.ETNewArbiterElection, a.nextArbitrators)

	return nil
}

func (a *Arbitrators) OnBlockReceived(b *types.Block, confirmed bool) {
	if confirmed {
		a.lock.Lock()
		a.onChainHeightIncreased(b)
		a.lock.Unlock()
	}
}

func (a *Arbitrators) OnConfirmReceived(p *types.DPosProposalVoteSlot) {
	a.lock.Lock()
	defer a.lock.Unlock()
	block, err := a.cfg.ChainStore.GetBlock(p.Hash)
	if err != nil {
		log.Warn("Error occurred when changing arbitrators, details: ", err)
		return
	}

	a.onChainHeightIncreased(block)
}

func (a *Arbitrators) GetArbitrators() [][]byte {
	a.lock.Lock()
	defer a.lock.Unlock()

	return a.currentArbitrators
}

func (a *Arbitrators) GetCandidates() [][]byte {
	a.lock.Lock()
	defer a.lock.Unlock()

	return a.currentCandidates
}

func (a *Arbitrators) GetNextArbitrators() [][]byte {
	a.lock.Lock()
	defer a.lock.Unlock()

	return a.nextArbitrators
}

func (a *Arbitrators) GetNextCandidates() [][]byte {
	a.lock.Lock()
	defer a.lock.Unlock()

	return a.nextCandidates
}

func (a *Arbitrators) IsCRCArbitratorProgramHash(hash *common.Uint168) bool {
	_, ok := a.crcArbitratorsProgramHashes[*hash]
	return ok
}

func (a *Arbitrators) IsCRCArbitrator(pk []byte) bool {
	for _, v := range a.cfg.CRCArbitrators {
		if bytes.Equal(v.PublicKey, pk) {
			return true
		}
	}
	return false
}

func (a *Arbitrators) GetCRCArbitrators() []config.CRCArbitratorParams {
	return a.cfg.CRCArbitrators
}

func (a *Arbitrators) GetArbitratorsProgramHashes() []*common.Uint168 {
	a.lock.Lock()
	defer a.lock.Unlock()

	return a.currentArbitratorsProgramHashes
}

func (a *Arbitrators) GetCandidatesProgramHashes() []*common.Uint168 {
	a.lock.Lock()
	defer a.lock.Unlock()

	return a.currentCandidatesProgramHashes
}

func (a *Arbitrators) GetOnDutyArbitrator() []byte {
	return a.GetNextOnDutyArbitrator(uint32(0))
}

func (a *Arbitrators) GetNextOnDutyArbitrator(offset uint32) []byte {
	return a.cfg.Versions.GetNextOnDutyArbitrator(a.cfg.ChainStore.GetHeight(),
		a.DutyChangedCount, offset)
}

func (a *Arbitrators) GetArbitersCount() uint32 {
	a.lock.Lock()
	defer a.lock.Unlock()
	return a.getArbitersCount()
}

func (a *Arbitrators) GetArbitersMajorityCount() uint32 {
	a.lock.Lock()
	minSignCount := float64(a.getArbitersCount()) * blockchain.DposMajorityRatioNumerator / blockchain.DposMajorityRatioDenominator
	a.lock.Unlock()

	return uint32(minSignCount)
}

func (a *Arbitrators) HasArbitersMajorityCount(num uint32) bool {
	return num > a.GetArbitersMajorityCount()
}

func (a *Arbitrators) HasArbitersMinorityCount(num uint32) bool {
	return num >= a.cfg.ArbitratorsCount-a.GetArbitersMajorityCount()
}

func (a *Arbitrators) GetActiveDposPeers() (result map[string]string) {
	peers, err := a.cfg.Store.GetDirectPeers()
	if err == nil {
		log.Warn("get direct peers from data base error")
		return result
	}

	for _, v := range peers {
		if v.Sequence > 0 {
			pk := common.BytesToHexString(v.PublicKey)
			result[pk] = v.Address
		}
	}
	return result
}

func (a *Arbitrators) TryEnterEmergency(blockTime uint32) (result bool) {
	result = a.emergency.TryEnterEmergency(blockTime)

	if result {
		if err := a.ForceChange(); err != nil {
			panic("initialize crc arbitrators error when enter emergency state, details: " + err.Error())
		}
	}
	return result
}

func (a *Arbitrators) GetLastConfirmedBlockTimeStamp() uint32 {
	return a.emergency.GetEmergencyData().LastConfirmedBlockTimeStamp
}

func (a *Arbitrators) onChainHeightIncreased(block *types.Block) {

	if !a.TryEnterEmergency(block.Timestamp) {
		if a.isNewElection() {
			if err := a.changeCurrentArbitrators(); err != nil {
				log.Error("Change current arbitrators error: ", err)
				return
			}

			if err := a.updateNextArbitrators(block); err != nil {
				log.Error("Update arbitrators error: ", err)
				return
			}

			events.Notify(events.ETNewArbiterElection, a.nextArbitrators)

		} else {
			a.DutyChangedCount++
			a.saveDposRelated()
		}
	}

	a.emergency.ResetBlockTime(block.Timestamp)
}

func (a *Arbitrators) saveDposRelated() {
	a.cfg.Store.SaveDposDutyChangedCount(a.DutyChangedCount)
	if a.emergency.IsRunning() {
		data := a.emergency.GetEmergencyData()
		a.cfg.Store.SaveEmergencyData(data.EmergencyStarted, data.EmergencyStartTime, data.LastConfirmedBlockTimeStamp)
	}
}

func (a *Arbitrators) isNewElection() bool {
	return a.DutyChangedCount == a.cfg.ArbitratorsCount-1
}

func (a *Arbitrators) changeCurrentArbitrators() error {
	a.currentArbitrators = a.nextArbitrators
	a.currentCandidates = a.nextCandidates

	a.cfg.Store.SaveCurrentArbitrators(a)

	if err := a.sortArbitrators(); err != nil {
		return err
	}

	if err := a.updateArbitratorsProgramHashes(); err != nil {
		return err
	}

	a.DutyChangedCount = 0
	a.saveDposRelated()

	return nil
}

func (a *Arbitrators) updateNextArbitrators(block *types.Block) error {
	a.emergency.TryLeaveEmergency()

	if !a.emergency.IsRunning() {
		producers, err := a.cfg.Versions.GetNormalArbitratorsDesc(block)
		if err != nil {
			return err
		}

		a.nextArbitrators = producers
		for _, v := range a.cfg.CRCArbitrators {
			a.nextArbitrators = append(a.nextArbitrators, v.PublicKey)
		}

		candidates, err := a.cfg.Versions.GetCandidatesDesc(block)
		if err != nil {
			return err
		}
		a.nextCandidates = candidates

		return nil
	} else {
		a.nextArbitrators = [][]byte{}
		for _, v := range a.cfg.CRCArbitrators {
			a.nextArbitrators = append(a.nextArbitrators, v.PublicKey)
		}
		a.nextCandidates = [][]byte{}
		return nil
	}

	a.cfg.Store.SaveNextArbitrators(a)
	return nil
}

func (a *Arbitrators) sortArbitrators() error {

	strArbitrators := make([]string, len(a.currentArbitrators))
	for i := 0; i < len(strArbitrators); i++ {
		strArbitrators[i] = common.BytesToHexString(a.currentArbitrators[i])
	}
	sort.Strings(strArbitrators)

	a.currentArbitrators = make([][]byte, len(strArbitrators))
	for i := 0; i < len(strArbitrators); i++ {
		value, err := common.HexStringToBytes(strArbitrators[i])
		if err != nil {
			return err
		}
		a.currentArbitrators[i] = value
	}

	return nil
}

func (a *Arbitrators) getArbitersCount() uint32 {
	return uint32(len(a.GetArbitrators()))
}

func (a *Arbitrators) updateArbitratorsProgramHashes() error {
	a.currentArbitratorsProgramHashes = make([]*common.Uint168, len(a.currentArbitrators))
	for index, v := range a.currentArbitrators {
		hash, err := contract.PublicKeyToStandardProgramHash(v)
		if err != nil {
			return err
		}
		a.currentArbitratorsProgramHashes[index] = hash
	}

	a.currentCandidatesProgramHashes = make([]*common.Uint168, len(a.currentCandidates))
	for index, v := range a.currentCandidates {
		hash, err := contract.PublicKeyToStandardProgramHash(v)
		if err != nil {
			return err
		}
		a.currentCandidatesProgramHashes[index] = hash
	}

	return nil
}

func NewArbitrators(cfg *ArbitratorsConfig) (*Arbitrators, error) {
	return &Arbitrators{cfg: *cfg, emergency: &emergencyMechanism{cfg: cfg.Emergency}}, nil
}
