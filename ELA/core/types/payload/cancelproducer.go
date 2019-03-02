package payload

import (
	"bytes"
	"errors"
	"io"

	"github.com/elastos/Elastos.ELA/common"
	"github.com/elastos/Elastos.ELA/crypto"
)

type ProducerOperation byte

const (
	ProducerOperationVersion byte = 0x00

	OperationCancel   ProducerOperation = 0x01
	OperationActivate ProducerOperation = 0x02
)

type ProcessProducer struct {
	OwnerPublicKey []byte
	Signature      []byte
	Operation      ProducerOperation
}

func (a *ProcessProducer) Data(version byte) []byte {
	buf := new(bytes.Buffer)
	if err := a.Serialize(buf, version); err != nil {
		return []byte{0}
	}
	return buf.Bytes()
}

func (a *ProcessProducer) Serialize(w io.Writer, version byte) error {
	err := a.SerializeUnsigned(w, version)
	if err != nil {
		return err
	}

	err = common.WriteVarBytes(w, a.Signature)
	if err != nil {
		return errors.New("[ProcessProducer], signature serialize failed")
	}

	return nil
}

func (a *ProcessProducer) SerializeUnsigned(w io.Writer, version byte) error {
	err := common.WriteVarBytes(w, a.OwnerPublicKey)
	if err != nil {
		return errors.New("[ProcessProducer], write owner public key failed")
	}

	err = common.WriteUint8(w, uint8(a.Operation))
	if err != nil {
		return errors.New("[ProcessProducer], write operation failed")
	}

	return nil
}

func (a *ProcessProducer) Deserialize(r io.Reader, version byte) error {
	err := a.DeserializeUnsigned(r, version)
	if err != nil {
		return err
	}

	a.Signature, err = common.ReadVarBytes(r, crypto.SignatureLength, "signature")
	if err != nil {
		return errors.New("[ProcessProducer], signature deserialize failed")
	}

	return nil
}

func (a *ProcessProducer) DeserializeUnsigned(r io.Reader, version byte) error {
	var err error
	a.OwnerPublicKey, err = common.ReadVarBytes(r, crypto.NegativeBigLength, "public key")
	if err != nil {
		return errors.New("[ProcessProducer], read owner public key failed")
	}

	var op uint8
	op, err = common.ReadUint8(r)
	if err != nil {
		return errors.New("[ProcessProducer], read operation failed")
	}
	a.Operation = ProducerOperation(op)

	return err
}
