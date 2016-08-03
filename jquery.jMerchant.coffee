(($) ->
  class PaymentProcessor
    constructor: ->
      @pl = {}
      @requiredPayloadKeys = []

    generatePayload: (payload) ->
      $.extend({}, payload) # removes keys with undefined values

    validatePayload: ->
      for key in @requiredPayloadKeys
        @pl[key] or $.error("Payment Validation Error: Missing #{key}")

  class JetPay extends PaymentProcessor
    constructor: (testMode) ->
      @paymentUrl = if testMode
        'https://testapp1.jetpay.com/jetdirect/post/cc/process_cc.php'
      else
        'https://extapp01.jetpay.com/jetdirect/post/cc/process_cc.php'

      super()

    sendPayment: (callbacks) ->
      opts =
        url: @paymentUrl
        type: 'GET'
        data: @merchantPayload
        dataType: 'jsonp'
        jsonpCallback: 'callback'

      $.ajax(opts)
        .done (resp) ->
          if resp.approved
            callbacks.approved(resp)
          else
            callbacks.declined(resp)
        .fail (resp) ->
          callbacks.declined(resp)
          console.error('Payment request failed unexpectedly.')

    generatePayload: (paymentInfo) ->
      @populateOptionalFields(paymentInfo)
      @populateRequiredFields(paymentInfo)
      @merchantPayload = super(@pl)

    populateOptionalFields: (paymentInfo) ->
      @pl.customerEmail   = paymentInfo.customerEmail
      @pl.billingAddress1 = paymentInfo.billingAddress1
      @pl.billingAddress2 = paymentInfo.billingAddress2
      @pl.billingCity     = paymentInfo.billingCity
      @pl.billingState    = paymentInfo.billingState
      @pl.billingCountry  = paymentInfo.billingCountry

      @pl.ud1 = paymentInfo.ud1
      @pl.ud2 = paymentInfo.ud2
      @pl.ud3 = paymentInfo.ud3

      @pl.merData0 = paymentInfo.merData0
      @pl.merData1 = paymentInfo.merData1
      @pl.merData2 = paymentInfo.merData2
      @pl.merData3 = paymentInfo.merData3
      @pl.merData4 = paymentInfo.merData4
      @pl.merData5 = paymentInfo.merData5
      @pl.merData6 = paymentInfo.merData6
      @pl.merData7 = paymentInfo.merData7
      @pl.merData8 = paymentInfo.merData8
      @pl.merData9 = paymentInfo.merData9

    populateRequiredFields: (paymentInfo) ->
      # First and last name, or name (full name) is
      # required, but not both
      @pl.fName = paymentInfo.firstName
      @pl.lName = paymentInfo.lastName
      @pl.name  = paymentInfo.name

      @pl.cardNum = paymentInfo.cardNum
      @pl.expMo   = paymentInfo.cardExpMo
      @pl.expYr   = "#{paymentInfo.cardExpYr}".slice(-2)
      @pl.cvv     = paymentInfo.cardCvv
      @pl.amount  = paymentInfo.amount

      @pl.billingZip = paymentInfo.billingZip

      @pl.cid             = paymentInfo.cid
      @pl.jp_tid          = paymentInfo.jp_tid
      @pl.jp_key          = paymentInfo.jp_key
      @pl.jp_request_hash = paymentInfo.jp_request_hash
      @pl.order_number    = paymentInfo.order_number
      @pl.trans_type      = paymentInfo.trans_type

      @pl.retUrl  = paymentInfo.retUrl
      @pl.decUrl  = paymentInfo.decUrl
      @pl.dataUrl = paymentInfo.dataUrl

    validatePayload: ->
      @requiredPayloadKeys = [
        'cardNum', 'expMo', 'expYr', 'cvv', 'amount', 'billingZip',
        'cid', 'jp_tid', 'jp_key', 'jp_request_hash', 'order_number',
        'trans_type', 'retUrl', 'decUrl', 'dataUrl'
      ]

      if @pl.name and (@pl.fName or @pl.lName)
          $.error('Payment Validation Error: JetPay requires a name or a first/last name, but not both.')

      super()

  class CyberSource extends PaymentProcessor
    constructor: (testMode) ->
      @requestType = 'post'
      @paymentUrl = if testMode
        'https://testsecureacceptance.cybersource.com/silent/pay'
      else
        'https://secureacceptance.cybersource.com/silent/pay'

      super()

    sendPayment: ->
      inputs = ("<input name='#{key}' value='#{value}'>" for key, value of @merchantPayload).join()
      $form  = $("<form action='#{@paymentUrl}' method='POST' style='visibility: hidden; position: absolute; height: 0;' >#{inputs}</form>")

      $form.appendTo('body').submit()

      undefined

    generatePayload: (paymentInfo) ->
      @populateOptionalFields(paymentInfo)
      @populateRequiredFields(paymentInfo)
      @merchantPayload = @orderFields(super(@pl))

    populateOptionalFields: (paymentInfo) ->
      if paymentInfo.bill_to_forename or paymentInfo.bill_to_surname
        [firstName, lastName] = [paymentInfo.bill_to_forename, paymentInfo.bill_to_surname]
      else
        [firstName, lastName] = paymentInfo.name.split(' ')

      @pl.card_type                        = $.fn.creditCardInfoForNum(paymentInfo.cardNum).type
      @pl.card_number                      = paymentInfo.cardNum
      @pl.card_expiry_date                 = "#{paymentInfo.cardExpMo}-#{paymentInfo.cardExpYr}"
      @pl.card_cvn                         = paymentInfo.cardCvv
      @pl.bill_to_forename                 = firstName
      @pl.bill_to_surname                  = lastName
      @pl.bill_to_company_name             = paymentInfo.bill_to_company_name
      @pl.bill_to_address_line1            = paymentInfo.bill_to_address_line1
      @pl.bill_to_address_line2            = paymentInfo.bill_to_address_line2
      @pl.bill_to_address_city             = paymentInfo.bill_to_address_city
      @pl.bill_to_address_state            = paymentInfo.bill_to_address_state
      @pl.bill_to_address_country          = paymentInfo.bill_to_address_country
      @pl.bill_to_address_postal_code      = paymentInfo.billingZip
      @pl.bill_to_email                    = paymentInfo.bill_to_email
      @pl.bill_to_phone                    = paymentInfo.bill_to_phone
      @pl.complete_route                   = paymentInfo.complete_route
      @pl.consumer_id                      = paymentInfo.consumer_id
      @pl.customer_cookies_accepted        = paymentInfo.customer_cookies_accepted
      @pl.customer_gift_wrap               = paymentInfo.customer_gift_wrap
      @pl.customer_ip_address              = paymentInfo.customer_ip_address
      @pl.date_of_birth                    = paymentInfo.date_of_birth
      @pl.departure_time                   = paymentInfo.departure_time
      @pl.device_fingerprint_id            = paymentInfo.device_fingerprint_id
      @pl.ignore_avs                       = paymentInfo.ignore_avs
      @pl.ignore_cvn                       = paymentInfo.ignore_cvn
      @pl.journey_type                     = paymentInfo.journey_type
      @pl.line_item_count                  = paymentInfo.line_item_count
      @pl.override_backoffice_post_url     = paymentInfo.override_backoffice_post_url
      @pl.override_custom_cancel_page      = paymentInfo.override_custom_cancel_page
      @pl.override_custom_receipt_page     = paymentInfo.override_custom_receipt_page
      @pl.payment_method                   = paymentInfo.payment_method
      @pl.payment_token                    = paymentInfo.payment_token
      @pl.payment_token_comments           = paymentInfo.payment_token_comments
      @pl.payment_token_title              = paymentInfo.payment_token_title
      @pl.recurring_amount                 = paymentInfo.recurring_amount
      @pl.recurring_frequency              = paymentInfo.recurring_frequency
      @pl.recurring_start_date             = paymentInfo.recurring_start_date
      @pl.recurring_number_of_installments = paymentInfo.recurring_number_of_installments
      @pl.returns_accepted                 = paymentInfo.returns_accepted
      @pl.ship_to_address_city             = paymentInfo.ship_to_address_city
      @pl.ship_to_address_country          = paymentInfo.ship_to_address_country
      @pl.ship_to_address_line1            = paymentInfo.ship_to_address_line1
      @pl.ship_to_address_line2            = paymentInfo.ship_to_address_line2
      @pl.ship_to_address_postal_code      = paymentInfo.ship_to_address_postal_code
      @pl.ship_to_address_state            = paymentInfo.ship_to_address_state
      @pl.ship_to_company_name             = paymentInfo.ship_to_company_name
      @pl.ship_to_forename                 = paymentInfo.ship_to_forename
      @pl.ship_to_phone                    = paymentInfo.ship_to_phone
      @pl.ship_to_surname                  = paymentInfo.ship_to_surname
      @pl.shipping_method                  = paymentInfo.shipping_method
      @pl.skip_decision_manager            = paymentInfo.skip_decision_manager
      @pl.tax_amount                       = paymentInfo.tax_amount
      @pl['item_#_code']                   = paymentInfo['item_#_code']
      @pl['item_#_quantity']               = paymentInfo['item_#_quantity']
      @pl['item_#_sku']                    = paymentInfo['item_#_sku']
      @pl['item_#_tax_amount']             = paymentInfo['item_#_tax_amount']
      @pl['item_#_unit_price']             = paymentInfo['item_#_unit_price']
      @pl['journey_leg#_dest']             = paymentInfo['journey_leg#_dest']
      @pl['journey_leg#_orig']             = paymentInfo['journey_leg#_orig']

      for n in [1..5]
        @pl["merchant_secure_data#{n}"] = paymentInfo["merchant_secure_data#{n}"]

      for n in [1..100]
        @pl["merchant_defined_data#{n}"] = paymentInfo["merchant_defined_data#{n}"]

    populateRequiredFields: (paymentInfo) ->
      @pl.access_key           = paymentInfo.access_key
      @pl.profile_id           = paymentInfo.profile_id
      @pl.signature            = paymentInfo.signature
      @pl.reference_number     = paymentInfo.order_number
      @pl.transaction_uuid     = paymentInfo.transaction_uuid
      @pl.amount               = paymentInfo.amount
      @pl.currency             = paymentInfo.currency
      @pl.locale               = paymentInfo.locale
      @pl.transaction_type     = paymentInfo.transaction_type
      @pl.signed_date_time     = paymentInfo.signed_date_time
      @pl.signed_field_names   = paymentInfo.signed_field_names
      @pl.unsigned_field_names = paymentInfo.unsigned_field_names
      @pl.allow_payment_token_update = paymentInfo.allow_payment_token_update

    orderFields: (payload) ->
      _.tap {}, (merchantPayload) =>
        for field in payload.signed_field_names.split(',')
          merchantPayload[field] = payload[field]

        for field in payload.unsigned_field_names.split(',')
          merchantPayload[field] = payload[field]

        merchantPayload['signature'] = payload['signature']

    validatePayload: ->
      @requiredPayloadKeys = [
        'access_key', 'profile_id', 'signature', 'amount', 'currency',
        'locale', 'reference_number', 'transaction_type', 'transaction_uuid',
        'signed_date_time', 'signed_field_names', 'unsigned_field_names'
      ]

      super()

  class jMerchant
    PaymentProcessors =
      'JetPay': JetPay
      'CyberSource': CyberSource

    constructor: (merchantName, testMode) ->
      if merchantName not in Object.keys(PaymentProcessors)
        $.error("#{merchantName} is not a supported merchant")

      @processor = new PaymentProcessors[merchantName](testMode)

    sendPayment: (paymentInfo, callbacks) ->
      @processor.generatePayload(paymentInfo)
      @processor.validatePayload()
      @processor.sendPayment(callbacks)

  $.jMerchant = (merchantName, testMode) ->
    new jMerchant(merchantName, testMode)
)(jQuery)

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
  $.fn.creditCardInfoForNum = (number) ->
    normalize = (number) ->
      number.toString().replace(/[ -]/g, '')

    cardTypes = [
      { name: 'amex',          type: '003', pattern: /^3[47]/ }
      { name: 'jcb',           type: '007', pattern: /^35(2[89]|[3-8][0-9])/ }
      { name: 'visa_electron', type: '033', pattern: /^(4026|417500|4508|4844|491(3|7))/ }
      { name: 'visa',          type: '001', pattern: /^4/ }
      { name: 'mastercard',    type: '002', pattern: /^5[1-5]/ }
      { name: 'discover',      type: '004', pattern: /^(6011|622(12[6-9]|1[3-9][0-9]|[2-8][0-9]{2}|9[0-1][0-9]|92[0-5]|64[4-9])|65)/ }
    ]

    for cardType in cardTypes
      if normalize(number).match(cardType.pattern)
        return name: cardType.name, type: cardType.type

      null
)(jQuery)

(($) ->
  $.fn.obj = (number) ->
    normalize = (number) ->
      number.toString().replace(/[ -]/g, '')

    cardTypes = [
      { name: 'amex',          type: '003', pattern: /^3[47]/ }
      { name: 'jcb',           type: '007', pattern: /^35(2[89]|[3-8][0-9])/ }
      { name: 'visa_electron', type: '033', pattern: /^(4026|417500|4508|4844|491(3|7))/ }
      { name: 'visa',          type: '001', pattern: /^4/ }
      { name: 'mastercard',    type: '002', pattern: /^5[1-5]/ }
      { name: 'discover',      type: '004', pattern: /^(6011|622(12[6-9]|1[3-9][0-9]|[2-8][0-9]{2}|9[0-1][0-9]|92[0-5]|64[4-9])|65)/ }
    ]

    for cardType in cardTypes
      if normalize(number).match(cardType.pattern)
        return name: cardType.name, type: cardType.type

      null
)(jQuery)
