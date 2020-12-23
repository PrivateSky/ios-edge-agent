# iOS-smartwallet
iOS smartwallet for OpenDSU is a general container for a webview loader

## Native APIS

### webViewContainer.addAPI(name,functionImplementation)



## JavaScript APIs
### $$.nativeSmartWallet.importNativeAPI(name) 
returns a function with varargs  and the last argument a callback. This new function  is a proxy and the actual execution will happen  on the native side by sending 

#### generateRandom(length,callback)  
returns a buffer with length random bytes

#### nativeChoice(text,option1, ..., optionn, callback)
display an allert with text and n buttons for each option. The callback returns the choosed option. 


