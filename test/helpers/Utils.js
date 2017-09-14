/* global assert */

function isException(error) {
    let strError = error.toString();
    return strError.includes('invalid opcode') || strError.includes('invalid JUMP') || strError.includes('out of gas');
}

function ensureException(error) {
    assert(isException(error), error.toString());
}

// https://gist.github.com/xavierlepretre/88682e871f4ad07be4534ae560692ee6
function getTransactionReceiptMined(txnHash, interval) {
  var transactionReceiptAsync;
  interval = interval ? interval : 500;
  transactionReceiptAsync = function(txnHash, resolve, reject) {
    try {
      var receipt = web3.eth.getTransactionReceipt(txnHash);
      if (receipt == null) {
        setTimeout(function () {
          transactionReceiptAsync(txnHash, resolve, reject);
        }, interval);
      } else {
        resolve(receipt);
      }
    } catch(e) {
      reject(e);
    }
  };

  return new Promise(function (resolve, reject) {
    transactionReceiptAsync(txnHash, resolve, reject);
  });
};

// Found here https://gist.github.com/xavierlepretre/afab5a6ca65e0c52eaf902b50b807401
function getEventsPromise(myFilter, count) {
  return new Promise(function (resolve, reject) {
    count = count ? count : 1;
    var results = [];
    myFilter.watch(function (error, result) {
      if (error) {
        reject(error);
      } else {
        count--;
        results.push(result);
      }
      if (count <= 0) {
        resolve(results);
        myFilter.stopWatching();
      }
    });
  });
};

module.exports = {
    zeroAddress: '0x0000000000000000000000000000000000000000',
    exceptionGasToUse: 3000000,
    isException: isException,
    ensureException: ensureException,
    getEventsPromise: getEventsPromise,
    getTransactionReceiptMined: getTransactionReceiptMined
};
