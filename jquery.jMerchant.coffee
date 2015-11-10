(($) ->
  $.fn.serializeObject = ->
      result = {}
      inputArr = @serializeArray()

      for input in inputArr
        name = $.camelCase(input.name)
        value = result[name]

        if value
          if $.isArray(value)
            value.push(input.value)
          else
            result[name] = [
              result[name],
              input.value
            ]
        else
          result[name] = input.value

      result
)(jQuery)

(($) ->
  class PaymentProcessor
    constructor: ->
      @payload = {}
      @requiredPayloadKeys = []

    validatePayload: ->
      for key in @requiredPayloadKeys
        @payload[key] or $.error("Payment Validation Error: Missing #{key}")

  class JetPay extends PaymentProcessor
    constructor: ->
      @paymentUrl = 'https://testapp1.jetpay.com/jetdirect/post/cc/process_cc.php'
      super()

    generatePayload: (paymentInfo) ->
      @populateOptionalFields(paymentInfo)
      @populateRequiredFields(paymentInfo)
      @payload

    populateOptionalFields: (paymentInfo) ->
      @payload.customerEmail   = paymentInfo.customerEmail
      @payload.billingAddress1 = paymentInfo.billingAddress1
      @payload.billingAddress2 = paymentInfo.billingAddress2
      @payload.billingCity     = paymentInfo.billingCity
      @payload.billingState    = paymentInfo.billingState
      @payload.billingCountry  = paymentInfo.billingCountry

      @payload.ud1 = paymentInfo.ud1
      @payload.ud2 = paymentInfo.ud2
      @payload.ud3 = paymentInfo.ud3

      @payload.merData0 = paymentInfo.merData0
      @payload.merData1 = paymentInfo.merData1
      @payload.merData2 = paymentInfo.merData2
      @payload.merData3 = paymentInfo.merData3
      @payload.merData4 = paymentInfo.merData4
      @payload.merData5 = paymentInfo.merData5
      @payload.merData6 = paymentInfo.merData6
      @payload.merData7 = paymentInfo.merData7
      @payload.merData8 = paymentInfo.merData8
      @payload.merData9 = paymentInfo.merData9

    populateRequiredFields: (paymentInfo) ->
      # First and last name, or name (full name) is
      # required, but not both
      @payload.fName = paymentInfo.firstName
      @payload.lName = paymentInfo.lastName
      @payload.name  = paymentInfo.name

      @payload.cardNum = paymentInfo.cardNum
      @payload.expMo   = paymentInfo.cardExpMo
      @payload.expYr   = paymentInfo.cardExpYr
      @payload.cvv     = paymentInfo.cardCvv
      @payload.amount  = paymentInfo.amount

      @payload.billingZip = paymentInfo.billingZip

      @payload.cid             = paymentInfo.cid
      @payload.jp_tid          = paymentInfo.jp_tid
      @payload.jp_key          = paymentInfo.jp_key
      @payload.jp_request_hash = paymentInfo.jp_request_hash
      @payload.order_number    = paymentInfo.order_number
      @payload.trans_type      = paymentInfo.trans_type

      @payload.retUrl  = paymentInfo.retUrl
      @payload.decUrl  = paymentInfo.decUrl
      @payload.dataUrl = paymentInfo.dataUrl

    validatePayload: ->
      @requiredPayloadKeys = [
        'cardNum', 'expMo', 'expYr', 'cvv', 'amount', 'billingZip',
        'cid', 'jp_tid', 'jp_key', 'jp_request_hash', 'order_number',
        'trans_type', 'retUrl', 'decUrl', 'dataUrl'
      ]

      # @validatePayload(paymentInfo)
      if @payload.name and (@payload.fName or @payload.lName)
          $.error('Payment Validation Error: JetPay requires a name or a first/last name, but not both.')

      super()

  class jMerchant
    PaymentProcessors =
      'JetPay': JetPay

    constructor: (merchantName) ->
      if merchantName not in Object.keys(PaymentProcessors)
        $.error("#{merchantName} is not a supported merchant")

      @processor = new PaymentProcessors[merchantName]

    generatePayload: (paymentInfo) ->
      payload = @processor.generatePayload(paymentInfo)
      $.extend({}, payload) # removes keys with undefined values

    sendPayment: (paymentInfo) ->
      payload = @generatePayload(paymentInfo)

      @processor.validatePayload()

      $.ajax
        url: this.processor.paymentUrl
        type: 'GET'
        data: payload
        dataType: 'jsonp'
        jsonpCallback: 'callback'

  $.jMerchant = (merchantName) ->
    new jMerchant(merchantName)
)(jQuery)
