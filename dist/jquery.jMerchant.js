var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function($) {
  return $.fn.serializeObject = function() {
    var i, input, inputArr, len, name, result, value;
    result = {};
    inputArr = this.serializeArray();
    for (i = 0, len = inputArr.length; i < len; i++) {
      input = inputArr[i];
      name = $.camelCase(input.name);
      value = result[name];
      if (value) {
        if ($.isArray(value)) {
          value.push(input.value);
        } else {
          result[name] = [result[name], input.value];
        }
      } else {
        result[name] = input.value;
      }
    }
    return result;
  };
})(jQuery);

(function($) {
  var JetPay, PaymentProcessor, jMerchant;
  PaymentProcessor = (function() {
    function PaymentProcessor() {
      this.payload = {};
      this.requiredPayloadKeys = [];
    }

    PaymentProcessor.prototype.validatePayload = function() {
      var i, key, len, ref, results;
      ref = this.requiredPayloadKeys;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        key = ref[i];
        results.push(this.payload[key] || $.error("Payment Validation Error: Missing " + key));
      }
      return results;
    };

    return PaymentProcessor;

  })();
  JetPay = (function(superClass) {
    extend(JetPay, superClass);

    function JetPay() {
      this.paymentUrl = 'https://testapp1.jetpay.com/jetdirect/post/cc/process_cc.php';
      JetPay.__super__.constructor.call(this);
    }

    JetPay.prototype.generatePayload = function(paymentInfo) {
      this.populateOptionalFields(paymentInfo);
      this.populateRequiredFields(paymentInfo);
      return this.payload;
    };

    JetPay.prototype.populateOptionalFields = function(paymentInfo) {
      this.payload.customerEmail = paymentInfo.customerEmail;
      this.payload.billingAddress1 = paymentInfo.billingAddress1;
      this.payload.billingAddress2 = paymentInfo.billingAddress2;
      this.payload.billingCity = paymentInfo.billingCity;
      this.payload.billingState = paymentInfo.billingState;
      this.payload.billingCountry = paymentInfo.billingCountry;
      this.payload.ud1 = paymentInfo.ud1;
      this.payload.ud2 = paymentInfo.ud2;
      this.payload.ud3 = paymentInfo.ud3;
      this.payload.merData0 = paymentInfo.merData0;
      this.payload.merData1 = paymentInfo.merData1;
      this.payload.merData2 = paymentInfo.merData2;
      this.payload.merData3 = paymentInfo.merData3;
      this.payload.merData4 = paymentInfo.merData4;
      this.payload.merData5 = paymentInfo.merData5;
      this.payload.merData6 = paymentInfo.merData6;
      this.payload.merData7 = paymentInfo.merData7;
      this.payload.merData8 = paymentInfo.merData8;
      return this.payload.merData9 = paymentInfo.merData9;
    };

    JetPay.prototype.populateRequiredFields = function(paymentInfo) {
      this.payload.fName = paymentInfo.firstName;
      this.payload.lName = paymentInfo.lastName;
      this.payload.name = paymentInfo.name;
      this.payload.cardNum = paymentInfo.cardNum;
      this.payload.expMo = paymentInfo.cardExpMo;
      this.payload.expYr = paymentInfo.cardExpYr;
      this.payload.cvv = paymentInfo.cardCvv;
      this.payload.amount = paymentInfo.amount;
      this.payload.billingZip = paymentInfo.billingZip;
      this.payload.cid = paymentInfo.cid;
      this.payload.jp_tid = paymentInfo.jp_tid;
      this.payload.jp_key = paymentInfo.jp_key;
      this.payload.jp_request_hash = paymentInfo.jp_request_hash;
      this.payload.order_number = paymentInfo.order_number;
      this.payload.trans_type = paymentInfo.trans_type;
      this.payload.retUrl = paymentInfo.retUrl;
      this.payload.decUrl = paymentInfo.decUrl;
      return this.payload.dataUrl = paymentInfo.dataUrl;
    };

    JetPay.prototype.validatePayload = function() {
      this.requiredPayloadKeys = ['cardNum', 'expMo', 'expYr', 'cvv', 'amount', 'billingZip', 'cid', 'jp_tid', 'jp_key', 'jp_request_hash', 'order_number', 'trans_type', 'retUrl', 'decUrl', 'dataUrl'];
      if (this.payload.name && (this.payload.fName || this.payload.lName)) {
        $.error('Payment Validation Error: JetPay requires a name or a first/last name, but not both.');
      }
      return JetPay.__super__.validatePayload.call(this);
    };

    return JetPay;

  })(PaymentProcessor);
  jMerchant = (function() {
    var PaymentProcessors;

    PaymentProcessors = {
      'JetPay': JetPay
    };

    function jMerchant(merchantName) {
      if (indexOf.call(Object.keys(PaymentProcessors), merchantName) < 0) {
        $.error(merchantName + " is not a supported merchant");
      }
      this.processor = new PaymentProcessors[merchantName];
    }

    jMerchant.prototype.generatePayload = function(paymentInfo) {
      var payload;
      payload = this.processor.generatePayload(paymentInfo);
      return $.extend({}, payload);
    };

    jMerchant.prototype.sendPayment = function(paymentInfo) {
      var payload;
      payload = this.generatePayload(paymentInfo);
      this.processor.validatePayload();
      return $.ajax({
        url: this.processor.paymentUrl,
        type: 'GET',
        dataType: 'jsonp',
        data: payload
      });
    };

    return jMerchant;

  })();
  return $.jMerchant = function(merchantName) {
    return new jMerchant(merchantName);
  };
})(jQuery);
