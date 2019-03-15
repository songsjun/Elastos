package config

import (
	"log"
	"math/big"
	"os"
	"time"

	"github.com/elastos/Elastos.ELA/common"
)

var (
	Parameters ConfigParams

	MainNet = ChainParams{
		Name:               "MainNet",
		PowLimit:           powLimit,
		PowLimitBits:       0x1f0008ff,
		TargetTimePerBlock: time.Minute * 2,
		TargetTimespan:     time.Minute * 2 * 720,
		AdjustmentFactor:   int64(4),
		MaxOrphanBlocks:    10000,
		MinMemoryNodes:     20160,
		CoinbaseLockTime:   100,
		RewardPerBlock:     rewardPerBlock(time.Minute * 2),
	}

	TestNet = ChainParams{
		Name:               "TestNet",
		PowLimit:           powLimit,
		PowLimitBits:       0x1e1da5ff,
		TargetTimePerBlock: time.Second * 10,
		TargetTimespan:     time.Second * 10 * 10,
		AdjustmentFactor:   int64(4),
		MaxOrphanBlocks:    10000,
		MinMemoryNodes:     20160,
		CoinbaseLockTime:   100,
		RewardPerBlock:     rewardPerBlock(time.Second * 10),
	}

	RegNet = ChainParams{
		Name:               "RegNet",
		PowLimit:           powLimit,
		PowLimitBits:       0x207fffff,
		TargetTimePerBlock: time.Second * 1,
		TargetTimespan:     time.Second * 1 * 10,
		AdjustmentFactor:   int64(4),
		MaxOrphanBlocks:    10000,
		MinMemoryNodes:     20160,
		CoinbaseLockTime:   100,
		RewardPerBlock:     rewardPerBlock(time.Second * 1),
	}
)

type PowConfiguration struct {
	PayToAddr    string `json:"PayToAddr"`
	AutoMining   bool   `json:"AutoMining"`
	MinerInfo    string `json:"MinerInfo"`
	MinTxFee     int    `json:"MinTxFee"`
	InstantBlock bool   `json:"InstantBlock"`
}

type RpcConfiguration struct {
	User        string   `json:"User"`
	Pass        string   `json:"Pass"`
	WhiteIPList []string `json:"WhiteIPList"`
}

type CRCArbiterInfo struct {
	PublicKey  string `json:"PublicKey"`
	NetAddress string `json:"NetAddress"`
}

type Configuration struct {
	ActiveNet            string               `json:"ActiveNet"`
	Magic                uint32               `json:"Magic"`
	FoundationAddress    string               `json:"FoundationAddress"`
	Version              int                  `json:"Version"`
	SeedList             []string             `json:"SeedList"`
	HttpRestPort         int                  `json:"HttpRestPort"`
	MinCrossChainTxFee   int                  `json:"MinCrossChainTxFee"`
	RestCertPath         string               `json:"RestCertPath"`
	RestKeyPath          string               `json:"RestKeyPath"`
	HttpInfoPort         uint16               `json:"HttpInfoPort"`
	HttpInfoStart        bool                 `json:"HttpInfoStart"`
	HttpWsPort           int                  `json:"HttpWsPort"`
	HttpJsonPort         int                  `json:"HttpJsonPort"`
	NodePort             uint16               `json:"NodePort"`
	PrintLevel           uint8                `json:"PrintLevel"`
	MaxLogsSize          int64                `json:"MaxLogsSize"`
	MaxPerLogSize        int64                `json:"MaxPerLogSize"`
	MaxTxsInBlock        int                  `json:"MaxTransactionInBlock"`
	PowConfiguration     PowConfiguration     `json:"PowConfiguration"`
	EnableArbiter        bool                 `json:"EnableArbiter"`
	ArbiterConfiguration ArbiterConfiguration `json:"ArbiterConfiguration"`
	RpcConfiguration     RpcConfiguration     `json:"RpcConfiguration"`
	HeightVersions       []uint32             `json:"HeightVersions"`
	VoteStartHeight      uint32               `json:"VoteStartHeight"`
}

type ArbiterConfiguration struct {
	PublicKey                string           `json:"PublicKey"`
	Magic                    uint32           `json:"Magic"`
	NodePort                 uint16           `json:"NodePort"`
	ProtocolVersion          uint32           `json:"ProtocolVersion"`
	Services                 uint64           `json:"Services"`
	PrintLevel               uint8            `json:"PrintLevel"`
	SignTolerance            uint64           `json:"SignTolerance"`
	MaxLogsSize              int64            `json:"MaxLogsSize"`
	MaxPerLogSize            int64            `json:"MaxPerLogSize"`
	OriginArbiters           []string         `json:"OriginArbiters"`
	CRCArbiters              []CRCArbiterInfo `json:"CRCArbiters"`
	NormalArbitratorsCount   int              `json:"NormalArbitratorsCount"`
	CandidatesCount          int              `json:"CandidatesCount"`
	EmergencyInactivePenalty common.Fixed64   `json:"EmergencyInactivePenalty"`
	MaxInactiveRounds        uint32           `json:"MaxInactiveRounds"`
	InactivePenalty          common.Fixed64   `json:"InactivePenalty"`
	InactiveEliminateCount   uint32           `json:"InactiveEliminateCount"`
	EnableEventRecord        bool             `json:"EnableEventRecord"`
	PreConnectOffset         uint32           `json:"PreConnectOffset"`
}

type Seed struct {
	PublicKey string `json:"PublicKey"`
	Address   string `json:"Address"`
}

type ConfigFile struct {
	Configuration `json:"Configuration"`
}

type ChainParams struct {
	Name               string
	PowLimit           *big.Int
	PowLimitBits       uint32
	TargetTimePerBlock time.Duration
	TargetTimespan     time.Duration
	AdjustmentFactor   int64
	MaxOrphanBlocks    int
	MinMemoryNodes     uint32
	CoinbaseLockTime   uint32
	RewardPerBlock     common.Fixed64
}

type ConfigParams struct {
	*Configuration
	ChainParam *ChainParams
}

func (config *Configuration) GetArbiterID() []byte {
	publicKey, err := common.HexStringToBytes(config.ArbiterConfiguration.PublicKey)
	if err != nil || len(publicKey) != 33 {
		log.Fatalf("get arbiter public key error %v", err)
		os.Exit(1)
	}

	return publicKey
}
