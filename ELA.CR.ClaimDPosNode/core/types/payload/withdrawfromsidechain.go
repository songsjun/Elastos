package payload

import (
	"bytes"
	"errors"
	"io"

	"github.com/elastos/Elastos.ELA/common"
)

const WithdrawFromSideChainPayloadVersion byte = 0x00

type PayloadWithdrawFromSideChain struct {
	BlockHeight                uint32
	GenesisBlockAddress        string
	SideChainTransactionHashes []common.Uint256
}

func (t *PayloadWithdrawFromSideChain) Data(version byte) []byte {
	buf := new(bytes.Buffer)
	if err := t.Serialize(buf, version); err != nil {
		return []byte{0}
	}

	return buf.Bytes()
}

func (t *PayloadWithdrawFromSideChain) Serialize(w io.Writer, version byte) error {
	if err := common.WriteUint32(w, t.BlockHeight); err != nil {
		return errors.New("[PayloadWithdrawFromSideChain], BlockHeight serialize failed.")
	}
	if err := common.WriteVarString(w, t.GenesisBlockAddress); err != nil {
		return errors.New("[PayloadWithdrawFromSideChain], GenesisBlockAddress serialize failed.")
	}

	if err := common.WriteVarUint(w, uint64(len(t.SideChainTransactionHashes))); err != nil {
		return errors.New("[PayloadWithdrawFromSideChain], SideChainTransactionHashes count serialize failed")
	}

	for _, hash := range t.SideChainTransactionHashes {
		err := hash.Serialize(w)
		if err != nil {
			return errors.New("[PayloadWithdrawFromSideChain], SideChainTransactionHashes serialize failed")
		}
	}
	return nil
}

func (t *PayloadWithdrawFromSideChain) Deserialize(r io.Reader, version byte) error {
	height, err := common.ReadUint32(r)
	if err != nil {
		return errors.New("[PayloadWithdrawFromSideChain], BlockHeight deserialize failed.")
	}
	address, err := common.ReadVarString(r)
	if err != nil {
		return errors.New("[PayloadWithdrawFromSideChain], GenesisBlockAddress deserialize failed.")
	}

	count, err := common.ReadVarUint(r, 0)
	if err != nil {
		return errors.New("[PayloadWithdrawFromSideChain], SideChainTransactionHashes count deserialize failed")
	}

	t.SideChainTransactionHashes = make([]common.Uint256, 0)
	for i := uint64(0); i < count; i++ {
		var hash common.Uint256
		err := hash.Deserialize(r)
		if err != nil {
			return errors.New("[PayloadWithdrawFromSideChain], SideChainTransactionHash deserialize failed.")
		}
		t.SideChainTransactionHashes = append(t.SideChainTransactionHashes, hash)
	}

	t.BlockHeight = height
	t.GenesisBlockAddress = address

	return nil
}
