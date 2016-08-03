# jMerchant
A jQuery plugin intended to simplify implementing direct post payment processing with PCI DSS 3.1 SAQ A-EP compliance

## Merchants

### JetPay
JetPay#submitPurchase
  - needs an approved/declined function
  - if the `.sendPayment` response returns an `approved` key the `approved` function will be triggered, otherwise trigger `declined`
