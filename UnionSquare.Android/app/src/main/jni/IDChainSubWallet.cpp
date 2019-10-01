// Copyright (c) 2012-2018 The Elastos Open Source Project
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "Utils.h"
#include "IIDChainSubWallet.h"
#include "nlohmann/json.hpp"

using namespace Elastos::ElaWallet;

#define JNI_CreateIDTransaction "(JLjava/lang/String;Ljava/lang/String;)Ljava/lang/String;"

static jstring JNICALL CreateIDTransaction(JNIEnv *env, jobject clazz, jlong instance,
                                           jstring jpayloadJson,
                                           jstring jmemo) {
    bool exception = false;
    std::string msgException;

    const char *payloadJson = env->GetStringUTFChars(jpayloadJson, NULL);
    const char *memo = env->GetStringUTFChars(jmemo, NULL);

    IIDChainSubWallet *wallet = (IIDChainSubWallet *) instance;
    jstring tx = NULL;

    try {
        nlohmann::json txJson = wallet->CreateIDTransaction(nlohmann::json::parse(payloadJson),
                                                            memo);
        tx = env->NewStringUTF(txJson.dump().c_str());
    } catch (const std::exception &e) {
        exception = true;
        msgException = e.what();
    }

    env->ReleaseStringUTFChars(jpayloadJson, payloadJson);
    env->ReleaseStringUTFChars(jmemo, memo);

    if (exception) {
        ThrowWalletException(env, msgException.c_str());
    }

    return tx;
}


static const JNINativeMethod methods[] = {
        REGISTER_METHOD(CreateIDTransaction),
};

jint RegisterIDChainSubWallet(JNIEnv *env, const std::string &path) {
    return RegisterNativeMethods(env, path + "IDChainSubWallet", methods, NELEM(methods));
}

