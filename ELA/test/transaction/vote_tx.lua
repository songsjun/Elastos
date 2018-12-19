local m = require("api")

-- client: path, password, if create
local wallet = client.new("keystore.dat", "123", false)

-- account
local addr = wallet:get_address()
local pubkey = wallet:get_publickey()

print("addr", addr)
print("pubkey", pubkey)

-- asset_id
local asset_id = m.get_asset_id()

-- amount, fee, recipent
local amount = 0.2
local fee = 0.001
local vote_type = 0
local vote_candidates = {'DVgnDnVfPVuPa2y2E4JitaWjWgRGJDuyrD'}

-- payload
local ta = transferasset.new()

-- transaction: version, tx_type, payload_version, payload, locktime
local tx = transaction.new(9, 0x02, 0, ta, 0)

-- input: from, amount + fee
local charge = tx:appendenough(addr, (amount + fee) * 100000000)
print("charge", charge)

-- votecontent: vote_type, vote_candidates
local vote_content = votecontent.new(vote_type, vote_candidates)
print("vote_content", vote_content:get())

-- outputpayload
local vote_output = voteoutput.new(0, { vote_content })
print("vote_output", vote_output:get())

local default_output = defaultoutput.new()

-- output: asset_id, value, recipient, output_paload_type, output_paload
local charge_output = output.new(asset_id, charge, addr, 0, default_output)
local amount_output = output.new(asset_id, amount * 100000000, addr, 1, vote_output)
-- print("txoutput", charge_output:get())
-- print("txoutput", amount_output:get())
tx:appendtxout(charge_output)
tx:appendtxout(amount_output)

print(tx:get())

-- sign
tx:sign(wallet)
print(tx:get())

-- send
local hash = tx:hash()
local res = m.send_tx(tx)

print("sending " .. hash)

if (res ~= hash)
then
	print(res)
else
	print("tx send success")
end
