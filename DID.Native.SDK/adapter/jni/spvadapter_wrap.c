#include <jni.h>
#include <stdlib.h>
#include <string.h>

#include "spvadapter.h"

/* unreferenced local function has been removed */
#if defined(_MSC_VER)
#   pragma warning(disable : 4505)
#endif

/* exporting methods */
#if defined(__GNUC__)
#   if (__GNUC__ >= 4) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4)
#       ifndef GCC_HASCLASSVISIBILITY
#           define GCC_HASCLASSVISIBILITY
#       endif
#   endif
#endif

#ifndef JNI_EXPORT
#   if defined(_WIN32) || defined(__WIN32__) || defined(__CYGWIN__)
#       if defined(STATIC_LINKED)
#           define JNI_EXPORT
#       else
#           define JNI_EXPORT __declspec(dllexport)
#       endif
#   else
#       if defined(__GNUC__) && defined(GCC_HASCLASSVISIBILITY)
#           define JNI_EXPORT __attribute__ ((visibility("default")))
#       else
#           define JNI_EXPORT
#       endif
#   endif
#endif

/* Deal with Microsoft's attempt at deprecating C standard runtime functions */
#if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_DEPRECATE)
#   define _CRT_SECURE_NO_DEPRECATE
#endif

/* Deal with Microsoft's attempt at deprecating methods in the standard C++ library */
#if defined(_MSC_VER) && !defined(_SCL_SECURE_NO_DEPRECATE)
#   define _SCL_SECURE_NO_DEPRECATE
#endif

#ifdef __cplusplus
extern "C" {
#endif

static JavaVM *jvm;

/* Contract support */
#define contract_assert(nullreturn, expr, msg)                        \
    if (!(expr)) {                                                    \
        JavaThrowException(jenv, JavaIllegalArgumentException, msg);  \
        return nullreturn;                                            \
    } else

/* Support for throwing Java exceptions */
typedef enum {
    JavaOutOfMemoryError = 1,
    JavaIOException,
    JavaRuntimeException,
    JavaIndexOutOfBoundsException,
    JavaArithmeticException,
    JavaIllegalArgumentException,
    JavaNullPointerException,
    JavaDirectorPureVirtual,
    JavaClassNotFoundException,
    JavaUnknownError,
    DIDStoreException,
    DIDResolveException
} JavaExceptionCodes;

typedef struct {
    JavaExceptionCodes code;
    const char *className;
} JavaException;


static void JavaThrowException(JNIEnv *jenv, JavaExceptionCodes code,
    const char *msg)
{
    jclass exclass;

    static const JavaException java_exceptions[] = {
        { JavaOutOfMemoryError, "java/lang/OutOfMemoryError" },
        { JavaIOException, "java/io/IOException" },
        { JavaRuntimeException, "java/lang/RuntimeException" },
        { JavaIndexOutOfBoundsException, "java/lang/IndexOutOfBoundsException" },
        { JavaArithmeticException, "java/lang/ArithmeticException" },
        { JavaIllegalArgumentException, "java/lang/IllegalArgumentException" },
        { JavaNullPointerException, "java/lang/NullPointerException" },
        { JavaDirectorPureVirtual, "java/lang/RuntimeException" },
        { JavaClassNotFoundException, "java/lang/ClassNotFoundException"},
        { JavaUnknownError,  "java/lang/UnknownError" },
        { DIDStoreException, "org/elastos/did/exception/DIDStoreException" },
        { DIDResolveException, "org/elastos/did/exception/DIDResolveException" },
        { (JavaExceptionCodes)0,  "java/lang/UnknownError" }
    };

    const JavaException *ex = java_exceptions;

    while (ex->code != code && ex->code)
        ex++;

    (*jenv)->ExceptionClear(jenv);
    exclass = (*jenv)->FindClass(jenv, ex->className);
    if (exclass)
        (*jenv)->ThrowNew(jenv, exclass, msg);
}

JNI_EXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
    JNIEnv *env = NULL;

    // Hold global jvm reference.
    jvm = vm;

    if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_8) == JNI_OK)
      return JNI_VERSION_1_8;

    if ((*vm)->GetEnv(vm, (void **)&env, JNI_VERSION_1_6) == JNI_OK)
      return JNI_VERSION_1_6;

    return JNI_VERSION_1_4;
}

JNI_EXPORT jlong JNICALL Java_org_elastos_did_adapter_SPVAdapter_create(
        JNIEnv *jenv, jclass jcls, jstring jWalletDir, jstring jWalletId,
        jstring jNetwork, jstring jResolver)
{
    const char *walletDir = NULL;
    const char *walletId = NULL;
    const char *network = NULL;
    const char *resolver = NULL;
    jlong result = 0 ;

    (void)jcls;

    if (jWalletDir)
        walletDir = (*jenv)->GetStringUTFChars(jenv, jWalletDir, 0);

    if (!walletDir) {
        JavaThrowException(jenv, JavaIllegalArgumentException, "Invalid wallet data dir.");
        return 0;
    }

    if (jWalletId)
        walletId = (*jenv)->GetStringUTFChars(jenv, jWalletId, 0);

    if (!walletId) {
        (*jenv)->ReleaseStringUTFChars(jenv, jWalletDir, walletDir);
        JavaThrowException(jenv, JavaIllegalArgumentException, "Invalid wallet ID.");
        return 0;
    }

    if (jNetwork)
        network = (*jenv)->GetStringUTFChars(jenv, jNetwork, 0);

    if (jResolver)
        resolver = (*jenv)->GetStringUTFChars(jenv, jResolver, 0);

    result = (jlong)SpvDidAdapter_Create(walletDir, walletId, network, resolver);

    if (resolver) (*jenv)->ReleaseStringUTFChars(jenv, jResolver, resolver);
    if (network) (*jenv)->ReleaseStringUTFChars(jenv, jNetwork, network);
    (*jenv)->ReleaseStringUTFChars(jenv, jWalletId, walletId);
    (*jenv)->ReleaseStringUTFChars(jenv, jWalletDir, walletDir);

    if (result == 0) {
        JavaThrowException(jenv, DIDStoreException, "DID adapter initialize SPV wallet failed.");
        return 0;
    }

    return result;
}

JNI_EXPORT void JNICALL Java_org_elastos_did_adapter_SPVAdapter_destroy(
        JNIEnv *jenv, jclass jcls, jlong jHandle)
{
    (void)jenv;
    (void)jcls;

    if (jHandle)
      SpvDidAdapter_Destroy((SpvDidAdapter *)jHandle);
}

JNI_EXPORT jboolean JNICALL Java_org_elastos_did_adapter_SPVAdapter_isAvailable(
        JNIEnv *jenv, jclass jcls, jlong jHandle)
{
    SpvDidAdapter *handle = (SpvDidAdapter *)jHandle;
    int result;

    (void)jenv;
    (void)jcls;

    if (!handle) {
        JavaThrowException(jenv, JavaIllegalArgumentException, NULL);
        return JNI_FALSE;
    }

    result = SpvDidAdapter_IsAvailable(handle);
    return (jboolean)(result != 0);
}

JNI_EXPORT jstring JNICALL Java_org_elastos_did_adapter_SPVAdapter_createIdTransaction(
        JNIEnv *jenv, jclass jcls, jlong jHandle, jstring jPayload,
        jstring jMemo, jstring jPassword)
{
    SpvDidAdapter *handle = (SpvDidAdapter *)jHandle;
    const char *payload = NULL;
    const char *memo = NULL;
    const char *password = NULL;
    const char *txid;

    (void)jcls;

    if (jPayload)
        payload = (*jenv)->GetStringUTFChars(jenv, jPayload, 0);

    if (!payload) {
        JavaThrowException(jenv, JavaIllegalArgumentException, "Invalid DID transaction payload.");
        return 0;
    }

    if (jPassword)
        password = (*jenv)->GetStringUTFChars(jenv, jPassword, 0);

    if (!password) {
        (*jenv)->ReleaseStringUTFChars(jenv, jPayload, payload);
        JavaThrowException(jenv, JavaIllegalArgumentException, "Invalid payment password.");
        return 0;
    }

    if (jMemo)
        memo = (*jenv)->GetStringUTFChars(jenv, jMemo, 0);

    txid = SpvDidAdapter_CreateIdTransaction(handle, payload, memo, password);

    if (memo) (*jenv)->ReleaseStringUTFChars(jenv, jMemo, memo);
    (*jenv)->ReleaseStringUTFChars(jenv, jPassword, password);
    (*jenv)->ReleaseStringUTFChars(jenv, jPayload, payload);

    if (txid) {
        jstring jTxid = (*jenv)->NewStringUTF(jenv, txid);
        SpvDidAdapter_FreeMemory(handle, (void *)txid);
        return jTxid;
    } else {
        JavaThrowException(jenv, DIDStoreException, "DID adapter create ID teansaction failed.");
        return 0;
    }
}

typedef struct {
    JNIEnv *env;
    jobject obj;
    jmethodID method;
} JavaMethodContext;

static void TransactionCallbackWrapper(const char *txid, int status,
        const char *msg, void *context)
{
    JavaMethodContext *ctx = (JavaMethodContext *)context;
    JNIEnv *env;
    jstring jTxid;
    jstring jMsg = NULL;

    if (!ctx)
      return;

    // TODO: CHECKME!!! use which env object?!
    (*jvm)->AttachCurrentThread(jvm, (void **)&env, NULL);

    jTxid = (*env)->NewStringUTF(env, txid);
    if (msg)
        jMsg = (*env)->NewStringUTF(env, msg);

    (*env)->CallVoidMethod(env, ctx->obj, ctx->method, jTxid, status, jMsg);

    (*jvm)->DetachCurrentThread(jvm);
    (*(ctx->env))->DeleteGlobalRef(ctx->env, ctx->obj);

    free(context);
}

JNI_EXPORT jboolean JNICALL Java_org_elastos_did_adapter_SPVAdapter_createIdTransactionEx(
        JNIEnv *jenv, jclass jcls, jlong jHandle, jstring jPayload,
        jstring jMemo, jint jConfirms, jobject jCallback, jstring jPassword)
{
    SpvDidAdapter *handle = (SpvDidAdapter *)jHandle;
    JavaMethodContext *ctx = NULL;
    const char *payload = NULL;
    const char *memo = NULL;
    const char *password = NULL;
    int rc;

    (void)jcls;

    if (jPayload)
        payload = (*jenv)->GetStringUTFChars(jenv, jPayload, 0);

    if (!payload) {
        JavaThrowException(jenv, JavaIllegalArgumentException, "Invalid DID transaction payload.");
        return JNI_FALSE;
    }

    if (jPassword)
        password = (*jenv)->GetStringUTFChars(jenv, jPassword, 0);

    if (!password) {
        (*jenv)->ReleaseStringUTFChars(jenv, jPayload, payload);
        JavaThrowException(jenv, JavaIllegalArgumentException, "Invalid payment password.");
        return JNI_FALSE;
    }

    if (jMemo)
        memo = (*jenv)->GetStringUTFChars(jenv, jMemo, 0);

    if (jCallback) {
        jclass cls = (*jenv)->FindClass(jenv,
                "org/elastos/did/DIDAdapter$TransactionCallback");
        if (!cls) {
            if (memo) (*jenv)->ReleaseStringUTFChars(jenv, jMemo, memo);
            (*jenv)->ReleaseStringUTFChars(jenv, jPassword, password);
            (*jenv)->ReleaseStringUTFChars(jenv, jPayload, payload);

            JavaThrowException(jenv, JavaClassNotFoundException, "Can not find TransactionCallback class");
            return JNI_FALSE;
        }

        jmethodID method = (*jenv)->GetMethodID(jenv, cls, "accept",
                "(Ljava/lang/String;ILjava/lang/String;)V");

        ctx = malloc(sizeof(JavaMethodContext));
        if (!ctx) {
            if (memo) (*jenv)->ReleaseStringUTFChars(jenv, jMemo, memo);
            (*jenv)->ReleaseStringUTFChars(jenv, jPassword, password);
            (*jenv)->ReleaseStringUTFChars(jenv, jPayload, payload);

            JavaThrowException(jenv, JavaOutOfMemoryError, "Out of memory");
            return JNI_FALSE;
        }

        ctx->env = jenv;
        ctx->obj = (*jenv)->NewGlobalRef(jenv, jCallback);
        ctx->method = method;
    }

    rc = SpvDidAdapter_CreateIdTransactionEx(handle, payload, memo,
            (int)jConfirms, TransactionCallbackWrapper, ctx, password);

    if (memo) (*jenv)->ReleaseStringUTFChars(jenv, jMemo, memo);
    (*jenv)->ReleaseStringUTFChars(jenv, jPassword, password);
    (*jenv)->ReleaseStringUTFChars(jenv, jPayload, payload);

    return (jboolean)(rc == 0);
}


JNI_EXPORT jstring JNICALL Java_org_elastos_did_adapter_SPVAdapter_resolve(
        JNIEnv *jenv, jclass jcls, jlong jHandle, jstring jDid, jboolean jAll)
{
    SpvDidAdapter *handle = (SpvDidAdapter *)jHandle;
    const char *did = NULL;
    const char *result = NULL;

    (void)jcls;

    if (jDid)
        did = (char *)(*jenv)->GetStringUTFChars(jenv, jDid, 0);

    if (!did) {
        JavaThrowException(jenv, JavaIllegalArgumentException, "Invalid DID parameter.");
        return 0;
    }

    result = SpvDidAdapter_Resolve(handle, did, (int)jAll);
    (*jenv)->ReleaseStringUTFChars(jenv, jDid, did);

    if (result) {
        jstring jresult = (*jenv)->NewStringUTF(jenv, result);
        SpvDidAdapter_FreeMemory(handle, (void *)result);
        return jresult;
    } else {
        JavaThrowException(jenv, DIDResolveException, "DID adapter try to resolve DID failed.");
        return 0;
    }
}

#ifdef __cplusplus
}
#endif
