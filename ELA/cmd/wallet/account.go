package wallet

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"

	"github.com/elastos/Elastos.ELA/account"
	cmdcom "github.com/elastos/Elastos.ELA/cmd/common"
	"github.com/elastos/Elastos.ELA/common"
	"github.com/elastos/Elastos.ELA/core/contract"

	"github.com/urfave/cli"
)

var accountCommand = []cli.Command{
	{
		Category: "Account",
		Name:     "create",
		Aliases:  []string{"c"},
		Usage:    "create a account",
		Flags: []cli.Flag{
			AccountWalletFlag,
			AccountPasswordFlag,
		},
		Action: createAccount,
	},
	{
		Category: "Account",
		Name:     "account",
		Aliases:  []string{"a"},
		Usage:    "show account address, public key and program hash",
		Flags: []cli.Flag{
			AccountWalletFlag,
		},
		Action: accountInfo,
	},
	{
		Category: "Account",
		Name:     "list",
		Aliases:  []string{"l"},
		Usage:    "list wallet information [account, balance, verbose]",
		Flags: []cli.Flag{
			AccountWalletFlag,
		},
		Action: listAccount,
	},
	{
		Category: "Account",
		Name:     "add",
		Usage:    "add a new account",
		Action:   addAccount,
	},
	{
		Category: "Account",
		Name:     "chpwd",
		Usage:    "change wallet password",
		Action:   changePassword,
	},
	{
		Category:  "Account",
		Name:      "import",
		Usage:     "import an account by private key hex string",
		ArgsUsage: "[args]",
		Flags: []cli.Flag{
			AccountWalletFlag,
			AccountPasswordFlag,
		},
		Action: importAccount,
	},
	{
		Category: "Account",
		Name:     "export",
		Usage:    "export all account private keys in hex string",
		Flags: []cli.Flag{
			AccountWalletFlag,
			AccountPasswordFlag,
		},
		Action: exportAccount,
	},
	{
		Category: "Account",
		Name:     "multisigaddr",
		Usage:    "generate multi-signature address",
		Flags: []cli.Flag{
			AccountWalletFlag,
		},
	},
	{
		Category: "Account",
		Name:     "depositaddr",
		Usage:    "generate deposit address",
		Action:   generateDepositAddress,
	},
}

func createAccount(c *cli.Context) error {
	walletPath := c.String("wallet")
	password := c.String("password")

	var p []byte
	if password == "" {
		var err error
		p, err = cmdcom.GetConfirmedPassword()
		if err != nil {
			return err
		}
	} else {
		p = []byte(password)
	}

	client, err := account.Create(walletPath, p)
	if err != nil {
		return err
	}

	return ShowAccountInfo(client)
}

func accountInfo(c *cli.Context) error {
	walletPath := c.String("wallet")
	if exist := cmdcom.FileExisted(walletPath); !exist {
		fmt.Println(fmt.Sprintf("error: %s is not found.", walletPath))
		cli.ShowCommandHelpAndExit(c, "account", 1)
	}
	password, err := cmdcom.GetPassword()
	if err != nil {
		return err
	}
	client, err := account.Open(walletPath, password)
	if err != nil {
		return err
	}
	if err := ShowAccountInfo(client); err != nil {
		fmt.Println("error: show account info failed,", err)
		cli.ShowCommandHelpAndExit(c, "account", 1)
	}
	return nil
}

func listAccount(c *cli.Context) error {
	walletPath := c.String("wallet")
	if exist := cmdcom.FileExisted(walletPath); !exist {
		fmt.Println(fmt.Sprintf("error: %s is not found.", walletPath))
		cli.ShowCommandHelpAndExit(c, "account", 1)
	}
	if err := ShowAccountBalance(walletPath); err != nil {
		fmt.Println("error: list accounts information failed,", err)
		cli.ShowCommandHelpAndExit(c, "list", 1)
	}
	return nil
}

func addAccount(c *cli.Context) error {
	// todo
	return nil
}

func changePassword(c *cli.Context) error {
	// todo
	return nil
}

func importAccount(c *cli.Context) error {
	walletPath := c.String("wallet")
	pwdHex := c.String("password")

	if c.NArg() < 1 {
		cmdcom.PrintErrorMsg("Missing argument. PrivateKey hex expected.")
		cli.ShowCommandHelpAndExit(c, "import", 1)
	}
	privateKeyHex := c.Args().First()

	privateKeyBytes, err := hex.DecodeString(privateKeyHex)
	if err != nil {
		return err
	}

	var pwd []byte
	if pwdHex == "" {
		pwd, err = cmdcom.GetConfirmedPassword()
		if err != nil {
			return err
		}
	} else {
		pwd = []byte(pwdHex)
	}

	var client *account.ClientImpl
	if _, err := os.Open(walletPath); os.IsNotExist(err) {
		client = account.NewClient(walletPath, pwd, true)
		if client == nil {
			return errors.New("client nil")
		}
	} else {
		client, err = account.Open(walletPath, pwd)
		if err != nil {
			return err
		}
	}

	acc, err := account.NewAccountWithPrivateKey(privateKeyBytes)
	if err != nil {
		return err
	}
	if err := client.SaveAccount(acc); err != nil {
		return err
	}

	return ShowAccountInfo(client)
}

func exportAccount(c *cli.Context) error {
	walletPath := c.String("wallet")
	pwdHex := c.String("password")

	var pwd []byte
	if pwdHex == "" {
		var err error
		pwd, err = cmdcom.GetPassword()
		if err != nil {
			return err
		}
	} else {
		pwd = []byte(pwdHex)
	}

	client, err := account.Open(walletPath, pwd)
	if err != nil {
		return err
	}

	accounts := client.GetAccounts()
	privateKeys := make([]string, 0, len(accounts))
	for _, account := range accounts {
		str := hex.EncodeToString(account.PrivateKey[:])
		privateKeys = append(privateKeys, str)
	}

	data, err := json.Marshal(privateKeys)
	if err != nil {
		return err
	}

	fmt.Println(string(data))
	return nil
}

func generateDepositAddress(c *cli.Context) error {
	if c.NArg() < 1 {
		cmdcom.PrintErrorMsg("Missing argument. Standard address expected.")
		cli.ShowCommandHelpAndExit(c, "depositaddress", 1)
	}
	addr := c.Args().First()

	var programHash *common.Uint168
	var err error
	if addr == "" {
		storeAccounts, err := account.GetWalletAccountData(account.KeystoreFileName)
		if err != nil {
			return err
		}
		for _, a := range storeAccounts {
			if a.Type == account.MAINACCOUNT {
				p, err := common.HexStringToBytes(a.ProgramHash)
				if err != nil {
					return err
				}
				programHash, err = common.Uint168FromBytes(p)
				if err != nil {
					return err
				}
			}
		}
	} else {
		programHash, err = common.Uint168FromAddress(addr)
		if err != nil {
			return err
		}
	}

	codeHash := programHash.ToCodeHash()
	depositHash := common.Uint168FromCodeHash(byte(contract.PrefixDeposit), codeHash)
	address, err := depositHash.ToAddress()
	if err != nil {
		return nil
	}
	fmt.Println(address)

	return nil
}
