package config

var Template = Configuration{
	Magic:              7630401,
	Version:            23,
	SeedList:           []string{"127.0.0.1:30338"},
	HttpInfoPort:       20333,
	HttpRestPort:       20334,
	HttpWsPort:         20335,
	HttpJsonPort:       20336,
	NodePort:           20338,
	PrintLevel:         0,
	MaxLogsSize:        0,
	MaxPerLogSize:      0,
	MinCrossChainTxFee: 10000,
	PowConfiguration: PowConfiguration{
		PayToAddr:  "8VYXVxKKSAxkmRrfmGpQR2Kc66XhG6m3ta",
		AutoMining: false,
		MinerInfo:  "ELA",
		MinTxFee:   100,
	},
	EnableArbiter: false,
	ArbiterConfiguration: ArbiterConfiguration{
		Magic:                    7630403,
		IPAddress:                "localhost",
		NodePort:                 30338,
		PrintLevel:               1,
		SignTolerance:            5,
		MaxLogsSize:              0,
		MaxPerLogSize:            0,
		NormalArbitratorsCount:   5,
		CandidatesCount:          0,
		EmergencyInactivePenalty: 0, //there will be no penalty in this version
		MaxInactiveRounds:        720 * 2,
		InactivePenalty:          0, //there will be no penalty in this version
		EnableEventRecord:        false,
		PreConnectOffset:         360,
	},
	RpcConfiguration: RpcConfiguration{
		User:        "",
		Pass:        "",
		WhiteIPList: []string{"127.0.0.1"},
	},
	CheckAddressHeight: 88812,
	VoteStartHeight:    88812,
	CRCOnlyDPOSHeight:  1008812, //fixme edit height later
	PublicDPOSHeight:   1108812, //fixme edit height later
}
