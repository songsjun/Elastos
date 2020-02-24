import Foundation

public class VerifiableCredential: DIDObject {
    private var _types: Array<String> = []
    private var _issuer: DID?
    private var _issuanceDate: Date?
    private var _expirationDate: Date?
    private var _subject: VerifiableCredentialSubject?
    private var _proof: VerifiableCredentialProof?
    private var _meta: CredentialMeta?

    private let RULE_EXPIRE : Int = 1
    private let RULE_GENUINE: Int = 2
    private let RULE_VALID  : Int = 3

    private var meta: CredentialMeta?

    override init() {
        super.init()
    }

    init(_ credential: VerifiableCredential) {
        super.init(credential.getId(), credential.getType())

        self._types = credential.getTypes()
        self._issuer = credential.issuer
        self._issuanceDate = credential.issuanceDate
        self._expirationDate = credential.expirationDate
        self._subject = credential.subject
        self._proof = credential.proof
    }

    override func setId(_ id: DIDURL) {
        super.setId(id)
    }

    public override func getType() -> String {
        var builder = ""
        var first = true

        builder.append("[")
        for type in _types {
            builder.append(!first ? ", ": "")
            builder.append(type)

            if  first {
                first = true
            }
        }
        builder.append("]")

        return builder
    }

    public func getTypes() -> [String] {
        return self._types
    }

    func appendType(_ type: String) {
        self._types.append(type)
    }

    func setType(_ newTypes: [String]) {
        for type in newTypes {
            self._types.append(type)
        }
    }

    public var issuer: DID {
        // Guaranteed that this field would not be nil because the object
        // was generated by "builder".
        return self._issuer!
    }

    // This type of getXXXX function would specifically be provided for
    // sdk internal when we can't be sure about it's validity/integrity.
    func getIssuer() -> DID? {
        return self._issuer
    }

    func setIssuer(_ newIssuer: DID) {
        self._issuer = newIssuer
    }

    public var issuanceDate: Date {
        // Guaranteed that this field would not be nil because the object
        // was generated by "builder".
        return _issuanceDate!
    }

    func getIssuanceDate() -> Date? {
        return _issuanceDate
    }

    func setIssuanceDate(_ issuanceDate: Date) {
        self._issuanceDate = issuanceDate
    }

    public var expirationDate: Date {
        // Guaranteed that this field would not be nil because the object
        // was generated by "builder".
        return _expirationDate!
    }

    func getExpirationDate() -> Date? {
        return _issuanceDate
    }

    func setExpirationDate(_ expirationDate: Date) {
        self._expirationDate = expirationDate
    }

    func getMeta() -> CredentialMeta {
        if  self._meta == nil {
            self._meta = CredentialMeta()
        }
        return self._meta!
    }

    func setMeta(_ newValue: CredentialMeta) {
        self._meta = newValue
    }

    public func setExtra(value: String, forName: String) throws {
        guard !forName.isEmpty else {
            throw DIDError.illegalArgument()
        }

        getMeta().setExtra(value, forName)
        try getMeta().store?.storeCredentialMeta(subject.did, getId(), getMeta())
    }

    public func getExtra(forName: String) -> String? {
        return getMeta().getExtra(forName)
    }
    
    public var aliasName: String {
        return getMeta().aliasName
    }

    private func setAliasName(_ newValue: String?) throws {
        getMeta().setAlias(newValue)
        try getMeta().store?.storeCredentialMeta(subject.did, getId(), getMeta())
    }

    public func unsetAlias() throws {
        try setAliasName(nil)
    }

    public func setAlias(_ newValue: String) throws {
        try setAliasName(newValue)
    }
    
    public func isSelfProclaimed() -> Bool {
        return issuer == subject.did
    }
    
    private func traceCheck(_ rule: Int) throws -> Bool {
        let controllerDoc = getSubject()?.did.resolve()
        guard let _ = controllerDoc else {
            return false
        }

        switch rule {
        case RULE_EXPIRE:
            if controllerDoc!.isExpired {
                return true
            }
        case RULE_GENUINE:
            if !controllerDoc!.isGenuine {
                return false
            }
        case RULE_VALID:
            if !controllerDoc!.isValid {
                return false
            }
        default:
            break
        }

        if !isSelfProclaimed() {
            let issuerDoc = getIssuer()?.resolve()
            guard let _ = issuerDoc else {
                return false
            }

            switch rule {
            case RULE_EXPIRE:
                if issuerDoc!.isExpired {
                    return true
                }
            case RULE_GENUINE:
                if !issuerDoc!.isGenuine {
                    return false
                }
            case RULE_VALID:
                if !issuerDoc!.isValid {
                    return false
                }
            default:
                break
            }
        }

        return rule != RULE_EXPIRE
    }
    
    private func checkExpired() throws -> Bool {
        return _expirationDate != nil ? DateHelper.isExipired(_expirationDate!) : false
    }

    public var isExpired: Bool {
        do {
            return try traceCheck(RULE_EXPIRE) ? true : checkExpired()
        } catch {
            return false
        }
    }

    /*
    public func isExpiredAsync() -> Promise<Bool> {
        // TODO:
    }
    */

    private func checkGenuine() throws -> Bool {
        let doc = issuer.resolve()
        guard let _ = doc else {
            return false
        }
        // Credential should signed by authentication key.
        guard doc!.containsAuthenticationKey(forId: proof.verificationMethod) else {
            return false
        }
        // Unsupported public key type;
        guard proof.type != Constants.DEFAULT_PUBLICKEY_TYPE else {
            return false
        }

        let data: Data = toJson(true, true).data(using: .utf8)!
        return try doc!.verifyWithIdentity(proof.verificationMethod, proof.signature, [data])
    }

    public var isGenuine: Bool {
        do {
            return try !traceCheck(RULE_GENUINE) ? checkGenuine(): false
        } catch {
            return false
        }
    }

    /*
    public func isGenuineAsync() -> Promise<Bool> {
        // TODO:
    }
    */

    public var isValid: Bool {
        do {
            return try !traceCheck(RULE_VALID) ? !checkExpired() && checkGenuine() : false
        } catch {
            return false
        }
    }

    /*
    public func isValidAsync() -> Promise<Bool> {
        // TODO:
    }
    */

    public var subject: VerifiableCredentialSubject {
        return _subject!
    }

    func getSubject() -> VerifiableCredentialSubject? {
        return _subject
    }

    func setSubject(_ newSubject: VerifiableCredentialSubject) {
        self._subject = newSubject
    }

    public var proof: VerifiableCredentialProof {
        return _proof!
    }

    func getProof() -> VerifiableCredentialProof? {
        return _proof
    }

    func setProof(_ newProof: VerifiableCredentialProof) {
        self._proof = newProof
    }

    func checkIntegrity() -> Bool {
        return (!getTypes().isEmpty && _subject != nil)
    }

    func parse(_ node: JsonNode, _ ref: DID?) throws  {
        let error = { (des) -> DIDError in
            return DIDError.malformedCredential(des)
        }

        let serializer = JsonSerializer(node)
        var options: JsonSerializer.Options

        let arrayNode = node.get(forKey: Constants.TYPE)?.asArray()
        guard let _ = arrayNode else {
            throw DIDError.malformedCredential("missing credential type")
        }
        for item in arrayNode! {
            appendType(item.toString())
        }

        options = JsonSerializer.Options()
                                .withOptional()
                                .withRef(ref)
                                .withHint("credential issuer")
                                .withError(error)
        let issuer = try serializer.getDID(Constants.ISSUER, options)

        options = JsonSerializer.Options()
                                .withHint("credential expirationDate")
                                .withError(error)
        let issuanceDate = try serializer.getDate(Constants.ISSUANCE_DATE, options)

        options = JsonSerializer.Options()
                                .withHint("credential id")
                                .withError(error)
        let id = try serializer.getDIDURL(Constants.ID, options)

        var subNode = node.get(forKey: Constants.CREDENTIAL_SUBJECT)
        guard let _ = subNode else {
            throw DIDError.malformedCredential("missing credential subject.")
        }
        let subject = try VerifiableCredentialSubject.fromJson(subNode!, ref)

        subNode = node.get(forKey: Constants.PROOF)
        guard let _ = subNode else {
            throw DIDError.malformedCredential("missing credential proof")
        }
        let proof = try VerifiableCredentialProof.fromJson(subNode!, ref)

        setIssuer(issuer)
        setIssuanceDate(issuanceDate)
        setSubject(subject)
        setId(id!)
        setProof(proof)

        if let _ = getIssuer() {
            setIssuer(self.subject.did)
        }
    }

    class func fromJson(_ node: JsonNode, _ ref: DID?) throws -> VerifiableCredential {
        let credential = VerifiableCredential()
        try credential.parse(node, ref)
        return credential
    }

    class func fromJson(_ json: Data) throws -> VerifiableCredential {
        guard !json.isEmpty else {
            throw DIDError.illegalArgument()
        }

        let data: Dictionary<String, Any>
        do {
            data = try JSONSerialization.jsonObject(with: json, options: []) as! Dictionary<String, Any>
        } catch {
            throw DIDError.didResolveError("Parse resolve result error")
        }

        return try fromJson(JsonNode(data), nil)
    }

    class func fromJson(_ json: String) throws -> VerifiableCredential {
        return try fromJson(json.data(using: .utf8)!)
    }

    func toJson(_ generator: JsonGenerator, _ ref: DID?, _ normalized: Bool) {
        toJson(generator, ref, normalized, false)
    }

    func toJson(_ generator: JsonGenerator, _ normalized: Bool) {
        toJson(generator, nil, normalized)
    }

    /*
    * Normalized serialization order:
    *
    * - id
    * - type ordered names array(case insensitive/ascending)
    * - issuer
    * - issuanceDate
    * - expirationDate
    * + credentialSubject
    *   - id
    *   - properties ordered by name(case insensitive/ascending)
    * + proof
    *   - type
    *   - method
    *   - signature
    */
    func toJson(_ generator: JsonGenerator, _ ref: DID?, _ normalized: Bool, _ forSign: Bool) {
        generator.writeStartObject()

        // id
        generator.writeFieldName(Constants.ID)
        generator.writeString(IDGetter(getId(), ref).value(normalized))

        // type
        generator.writeFieldName(Constants.TYPE)
        generator.writeStartArray()
        for type in getTypes() {
            generator.writeString(type)
        }
        generator.writeEndArray()

        // issuer
        if normalized || issuer != subject.did {
            generator.writeStringField(Constants.ISSUER, issuer.toString())
        }

        // issuanceDate
        generator.writeFieldName(Constants.ISSUANCE_DATE)
        generator.writeString(DateFormatter.convertToUTCStringFromDate(issuanceDate))

        // expirationDate
        if let _ = getExpirationDate() {
            generator.writeFieldName(Constants.EXPIRATION_DATE)
            generator.writeString(DateFormatter.convertToUTCStringFromDate(expirationDate))
        }

        // credenitalSubject
        generator.writeFieldName(Constants.CREDENTIAL_SUBJECT)
        subject.toJson(generator, ref, normalized)

        // proof
        if !forSign {
            generator.writeFieldName(Constants.PROOF)
            proof.toJson(generator, issuer, normalized)
        }

        generator.writeEndObject()
    }

    func toJson(_ normalized: Bool, _ forSign: Bool) -> String {
        let generator = JsonGenerator()
        toJson(generator, nil, forSign)
        return generator.toString()
    }
}

extension VerifiableCredential: CustomStringConvertible {
    func toString(_ normalized: Bool) -> String {
        return toJson(normalized, false)
    }

    func toString() -> String {
        return toString(false)
    }

    public var description: String {
        return toString()
    }
}
