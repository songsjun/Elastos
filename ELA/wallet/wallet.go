package wallet

import (
	"errors"
	"path/filepath"

	"github.com/elastos/Elastos.ELA/common"
	"github.com/elastos/Elastos.ELA/common/log"
	"github.com/elastos/Elastos.ELA/core/contract"
	"github.com/elastos/Elastos.ELA/crypto"
	"github.com/elastos/Elastos.ELA/utils"
)

type AddressInfo struct {
	address string
	code    []byte
}

type Wallet struct {
	addressBook map[string]*AddressInfo
	coinsCP     *CoinsCheckPoint
	FileStore
}

func (w *Wallet) LoadAddresses() error {
	addressBook := make(map[string]*AddressInfo, 0)
	storeAddresses, err := w.LoadAddressData()
	if err != nil {
		return err
	}
	for _, addressData := range storeAddresses {
		code, err := common.HexStringToBytes(addressData.Code)
		if err != nil {
			return err
		}
		addressInfo := &AddressInfo{
			address: addressData.Address,
			code:    code,
		}
		addressBook[addressData.Address] = addressInfo
	}
	w.addressBook = addressBook

	return nil
}

func (w *Wallet) ImportPubkey(pubKey []byte, enableUtxoDB bool) error {
	pk, err := crypto.DecodePoint(pubKey)
	if err != nil {
		return errors.New("invalid public key")
	}
	sc, err := contract.CreateStandardContract(pk)
	if err != nil {
		return err
	}
	address, err := sc.ToProgramHash().ToAddress()
	if err != nil {
		return err
	}

	if err := w.SaveAddressData(address, sc.Code); err != nil {
		return err
	}

	w.addressBook[address] = &AddressInfo{
		address: address,
		code:    sc.Code,
	}

	if enableUtxoDB {
		return nil
	}

	return w.coinsCP.RescanWallet()
}

func (w *Wallet) ImportAddress(address string, enableUtxoDB bool) error {
	_, err := common.Uint168FromAddress(address)
	if err != nil {
		return errors.New("invalid address")
	}

	if err := w.SaveAddressData(address, nil); err != nil {
		return err
	}

	w.addressBook[address] = &AddressInfo{
		address: address,
		code:    nil,
	}

	if enableUtxoDB {
		return nil
	}

	return w.coinsCP.RescanWallet()
}

func New(dataDir string, coinsCP *CoinsCheckPoint) *Wallet {
	walletPath := filepath.Join(dataDir, "wallet.dat")
	wallet := Wallet{
		addressBook: make(map[string]*AddressInfo, 0),
		FileStore:   FileStore{path: walletPath},
		coinsCP:     coinsCP,
	}

	exist := utils.FileExisted(walletPath)
	if !exist {
		if err := wallet.BuildDatabase(walletPath); err != nil {
			log.Warn("Build wallet failed, " + err.Error())
		}
		if err := wallet.SaveStoredData("Version", []byte(WalletVersion)); err != nil {
			log.Warn("Save version field failed, " + err.Error())
		}
		if err := wallet.SaveStoredData("Height", []byte("0")); err != nil {
			log.Warn("Save height field failed, " + err.Error())
		}
	} else {
		if err := wallet.LoadAddresses(); err != nil {
			log.Warn("Build wallet failed" + err.Error())
		}
	}

	return &wallet
}
