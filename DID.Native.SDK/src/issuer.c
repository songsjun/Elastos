/*
 * Copyright (c) 2019 Elastos Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "ela_did.h"
#include "did.h"
#include "credential.h"
#include "crypto.h"
#include "issuer.h"

extern const char *ProofType;

Issuer *Issuer_Create(DID *did, DIDURL *signkey, DIDStore *store)
{
    Issuer *issuer;
    DIDDocument *doc;
    bool isAuthKey;

    if (!did)
        return NULL;

    //doc = DID_Resolve(did);
    doc = DIDStore_LoadDID(store, did);
    if (!doc)
        return NULL;

    if (!signkey)
        signkey = DIDDocument_GetDefaultPublicKey(doc);
    else {
        isAuthKey = DIDDocument_IsAuthenticationKey(doc, signkey);
        if (!isAuthKey) {
            DIDDocument_Destroy(doc);
            return NULL;
        }
    }

    if (!DIDStore_ContainsPrivateKey(store, did, signkey)) {
        DIDDocument_Destroy(doc);
        return NULL;
    }

    issuer = (Issuer*)calloc(1, sizeof(Issuer));
    if (!issuer)
        return NULL;

    DID_Copy(&issuer->signer, DIDDocument_GetSubject(doc));
    DIDURL_Copy(&issuer->signkey, signkey);
    DIDDocument_Destroy(doc);
    return issuer;
}

void Issuer_Destroy(Issuer *issuer)
{
    if (!issuer)
        return;

    free(issuer);
}

DID *Issuer_GetSigner(Issuer *issuer)
{
    if (!issuer)
        return NULL;

    return &issuer->signer;
}

DIDURL *Issuer_GetSignKey(Issuer *issuer)
{
    if (!issuer)
        return NULL;

    return &issuer->signkey;
}

Credential *Issuer_CreateCredential(Issuer *issuer, DID *owner, DIDURL *credid,
        const char **types, size_t typesize, Property *properties, int propsize,
        time_t expires, const char *storepass)
{
    Credential *cred;
    const char *data;
    char signature[SIGNATURE_BYTES * 2];
    DIDStore *store;
    int i, rc;

    if (!issuer ||!owner || !credid || !types || typesize <= 0||
            !properties || propsize <= 0 || expires <= 0 ||
            !storepass || !*storepass)
        return NULL;

    if (!DID_Equals(owner, &credid->did))
        return NULL;

    cred = (Credential*)calloc(1, sizeof(Credential));
    if (!cred)
        return NULL;

    if (!DIDURL_Copy(&cred->id, credid))
        goto errorExit;

    //set type
    cred->type.size = typesize;
    cred->type.types = (char**)calloc(typesize, sizeof(char*));
    if (!cred->type.types)
        goto errorExit;
    for (i = 0; i < typesize; i++)
        cred->type.types[i] = strdup(types[i]);

    //set issuer
    DID_Copy(&cred->issuer, &issuer->signer);

    //expire and issue date
    cred->expirationDate = expires;
    time(&cred->issuanceDate);

    //subject
    strcpy(cred->subject.id.idstring, owner->idstring);

    cred->subject.infos.size = propsize;
    cred->subject.infos.properties = (Property*)calloc(propsize, sizeof(Property));
    if (!cred->subject.infos.properties)
        goto errorExit;
    for (i = 0; i < propsize; i++) {
        Property *pro = &(properties[i]);
        cred->subject.infos.properties[i].key = strdup(pro->key);
        cred->subject.infos.properties[i].value = strdup(pro->value);
    }

    //proof
    data = Credential_ToJson_ForSign(cred, false, true);
    if (!data)
        goto errorExit;
    rc = DIDStore_Sign(issuer->signer.meta.store, storepass, &issuer->signer,
            &issuer->signkey, signature, 1, (unsigned char*)data, strlen(data));
    free((char*)data);
    if (rc)
        goto errorExit;

    strcpy(cred->proof.type, ProofType);
    DIDURL_Copy(&cred->proof.verificationMethod, &issuer->signkey);
    strcpy(cred->proof.signatureValue, signature);
    return cred;

errorExit:
    Credential_Destroy(cred);
    return NULL;
}
