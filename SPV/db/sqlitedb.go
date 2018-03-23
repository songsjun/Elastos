package db

import (
	"database/sql"
	"fmt"
	"sync"

	"SPVWallet/bloom"
	"SPVWallet/log"

	_ "github.com/mattn/go-sqlite3"
)

const (
	DriverName = "sqlite3"
	DBName     = "./spv_wallet.db"
)

type SQLiteDB struct {
	*sync.RWMutex
	*sql.DB

	info   Info
	addrs  Addrs
	utxos  UTXOs
	stxos  STXOs
	proofs Proofs
	txns   TXNs
	queue  Queue

	filterLock *sync.Mutex
}

func NewSQLiteDB() (DataStore, error) {
	db, err := sql.Open(DriverName, DBName)
	if err != nil {
		fmt.Println("Open data db error:", err)
		return nil, err
	}
	// Use the save lock
	lock := new(sync.RWMutex)

	// Create info db
	infoDB, err := NewInfoDB(db, lock)
	if err != nil {
		return nil, err
	}
	// Create addrs db
	addrsDB, err := NewAddrsDB(db, lock)
	if err != nil {
		return nil, err
	}
	// Create UTXOs db
	utxosDB, err := NewUTXOsDB(db, lock)
	if err != nil {
		return nil, err
	}
	// Create STXOs db
	stxosDB, err := NewSTXOsDB(db, lock)
	if err != nil {
		return nil, err
	}
	// Create Proofs db
	proofsDB, err := NewProofsDB(db, lock)
	if err != nil {
		return nil, err
	}
	// Create TXNs db
	txnsDB, err := NewTXNsDB(db, lock)
	if err != nil {
		return nil, err
	}
	// Create Queue db
	queueDB, err := NewQueueDB(db, lock)
	if err != nil {
		return nil, err
	}

	return &SQLiteDB{
		RWMutex: lock,
		DB:      db,

		info:   infoDB,
		addrs:  addrsDB,
		utxos:  utxosDB,
		stxos:  stxosDB,
		proofs: proofsDB,
		txns:   txnsDB,
		queue:  queueDB,

		filterLock: new(sync.Mutex),
	}, nil
}

func (db *SQLiteDB) Info() Info {
	return db.info
}

func (db *SQLiteDB) Addrs() Addrs {
	return db.addrs
}

func (db *SQLiteDB) UTXOs() UTXOs {
	return db.utxos
}

func (db *SQLiteDB) STXOs() STXOs {
	return db.stxos
}

func (db *SQLiteDB) Proofs() Proofs {
	return db.proofs
}

func (db *SQLiteDB) TXNs() TXNs {
	return db.txns
}

func (db *SQLiteDB) Queue() Queue {
	return db.queue
}

func (db *SQLiteDB) Rollback(height uint32) error {
	db.Lock()
	defer db.Unlock()

	tx, err := db.Begin()
	if err != nil {
		return err
	}

	// Rollback Proofs
	_, err = tx.Exec("DELETE FROM Proofs WHERE Height=?", height)
	if err != nil {
		return err
	}

	// Rollback UTXOs
	_, err = tx.Exec("DELETE FROM UTXOs WHERE AtHeight=?", height)
	if err != nil {
		return err
	}

	// Rollback STXOs
	_, err = tx.Exec("DELETE FROM STXOs WHERE SpendHeight=?", height)
	if err != nil {
		return err
	}

	// Rollback TXNs
	_, err = tx.Exec("DELETE FROM TXNs WHERE Height=?", height)
	if err != nil {
		return err
	}

	// Rollback Queue
	_, err = tx.Exec("DELETE FROM Queue WHERE Height=?", height)
	if err != nil {
		return err
	}

	return tx.Commit()
}

func (db *SQLiteDB) GetBloomFilter() *bloom.Filter {
	db.filterLock.Lock()
	defer db.filterLock.Unlock()

	addrs := db.addrs.GetAddrFilter().GetScriptHashes()
	utxos, _ := db.utxos.GetAll()
	stxos, _ := db.stxos.GetAll()

	elements := uint32(len(addrs) + len(utxos) + len(stxos))
	filter := bloom.NewFilter(elements, 0, 0.00003)

	for _, addr := range addrs {
		filter.Add(addr.ToArray())
	}

	for _, utxo := range utxos {
		filter.AddOutPoint(&utxo.Op)
	}

	for _, stxo := range stxos {
		filter.AddOutPoint(&stxo.Op)
	}

	return filter
}

func (db *SQLiteDB) Close() {
	db.Lock()
	db.DB.Close()
	log.Debug("SQLite DB closed")
}
