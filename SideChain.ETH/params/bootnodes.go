// Copyright 2015 The Elastos.ELA.SideChain.ETH Authors
// This file is part of the Elastos.ELA.SideChain.ETH library.
//
// The Elastos.ELA.SideChain.ETH library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The Elastos.ELA.SideChain.ETH library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the Elastos.ELA.SideChain.ETH library. If not, see <http://www.gnu.org/licenses/>.

package params

// MainnetBootnodes are the enode URLs of the P2P bootstrap nodes running on
// the main Ethereum network.
var MainnetBootnodes = []string{
	"enode://ec8a4e686c19702ae3dae0b362bb8d6ad390f40c7eb1bb8bc0a22d506fb09c34efbe7baa492e8ba6ea6d5be238d7a478aede8f8b4f968686eeca562d9ac63fdb@52.81.82.85:30301",
}

// TestnetBootnodes are the enode URLs of the P2P bootstrap nodes running on the
// Ropsten test network.
var TestnetBootnodes = []string{
	"enode://ec8a4e686c19702ae3dae0b362bb8d6ad390f40c7eb1bb8bc0a22d506fb09c34efbe7baa492e8ba6ea6d5be238d7a478aede8f8b4f968686eeca562d9ac63fdb@52.81.82.85:30301",
}

// RinkebyBootnodes are the enode URLs of the P2P bootstrap nodes running on the
// Rinkeby test network.
var RinkebyBootnodes = []string{
	"enode://ec8a4e686c19702ae3dae0b362bb8d6ad390f40c7eb1bb8bc0a22d506fb09c34efbe7baa492e8ba6ea6d5be238d7a478aede8f8b4f968686eeca562d9ac63fdb@52.81.82.85:30301",
}

// DiscoveryV5Bootnodes are the enode URLs of the P2P bootstrap nodes for the
// experimental RLPx v5 topic-discovery network.
var DiscoveryV5Bootnodes = []string{
	"enode://da476658b470ccfd35e7886cd8c971ef77fa0ae6557e963686af7ef3f09cf484ee3063301db2e33969b31dbbff480373911fa2e478cc583deb80ffa005c513c0@54.223.196.249:20000",
}
