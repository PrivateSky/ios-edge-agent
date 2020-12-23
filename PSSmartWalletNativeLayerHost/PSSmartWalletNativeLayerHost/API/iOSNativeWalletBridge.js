/*

Allowed parameters: Strings, Numbers, Arrays of String|Number
*/

const isString = (str) => {
  return typeof str === 'string' || str instanceof String
}

const isNumber = (num) => {
    return typeof num === 'number' || num instanceof Number
}

const exists = (element) => {
    return element !== null && element !== undefined;
}


class PNGStreamHandler {
    constructor(videoElement) {
        this.canvas = document.createElement("canvas");
        this.ctx = this.canvas.getContext('2d');
        this.videoElement = videoElement;
        this.hasSetUpStream = false;
        this.canvas.setAttribute("id", "canvas1");
        videoElement.parentElement.appendChild(this.canvas);
    }
    
    setupStream() {
        this.hasSetUpStream = true;
        this.videoElement.width = this.canvas.width;
        this.videoElement.height = this.canvas.height;
        var stream = document.getElementById("canvas1").captureStream();
        
        try {
            this.videoElement.srcObject = stream;
        } catch (error) {
            console.log("ERROR " + error);
        }
        
    }
    
    displayFrom(streamHandler) {
        const self = this;
        var count = 0;
        
        streamHandler.setChunkHandler((chunk) => {
            var blob = new Blob([chunk], { type: "image/png" });
            var url = URL.createObjectURL(blob);
            var image=new Image();
            image.src=url;
            image.onload = function() {
                self.canvas.width = image.naturalWidth;
                self.canvas.height = image.naturalHeight;
                self.videoElement.width = self.canvas.width;
                self.videoElement.height = self.canvas.height;
                if (!self.hasSetUpStream) {
                    self.setupStream();
                }
                
                self.ctx.fillStyle = (count % 2 == 0 ? "blue" : "green");
                count += 1;
                //self.ctx.fillRect(0, 0, self.canvas.width, self.canvas.height);
                self.ctx.drawImage(image,0,0,self.canvas.width,self.canvas.height);
                console.log("Image loaded");
            };
        });
    }
}

class RGBAStreamHandler {
    constructor(canvas, videoElement) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.videoElement = videoElement;
    }
    
    displayFrom(streamHandler) {
        const self = this;
        try{
            this.videoElement.srcObject = this.canvas.captureStream(30);
            this.videoElement.play();
        }catch(err){
            //
        }
        
        streamHandler.setChunkHandler((chunk) => {
         const dv = new DataView(chunk.buffer);
         const width = dv.getUint32(0, true);
         const height = dv.getUint32(4, true);
         const pixelData = new Uint8ClampedArray(chunk.slice(8));
            for(var i=0; i<width*height*4; i+=4){
               //bgra
                //rgba
                const red = pixelData[i+2];
                const blue = pixelData[i];
                const green = pixelData[i+1];
                pixelData[i] = red;
                pixelData[i+1] = green;
                pixelData[i+2] = blue;
            }
         if (pixelData.length % 4 > 0) {
            console.log("Encountered bad data");
            return;
         }
         
         const imgData = new ImageData(pixelData, width, height);
         self.canvas.width = width;
         self.canvas.height = height;
         //self.videoElement.width = width;
         //self.videoElement.height = height;
         self.ctx.putImageData(imgData, 0, 0);
        });
    }
}

class CallableObject extends Function {
  constructor() {
    super('...args', 'return this._bound._call(...args)');
    // Or without the spread/rest operator:
    // super('return this._bound._call.apply(this._bound, arguments)')
    this._bound = this.bind(this);
 
    return this._bound;
  }
  
  _call(...args) {
    console.log(this, args);
  }
    
}

class StreamPacketCollector {
    constructor(reader, size) {
        this.size = size;
        this.reader = reader;
        this.buffer = new Uint8Array(size);
        this.filledCount = 0;
    }
    
    collectStartingWith(startingArray) {
        const self = this;
        const safeStart = startingArray || [];
        
        if(safeStart.length >= this.size) {
            return new Promise((resolve, reject) => {
                const filled = safeStart.slice(0, self.size);
                const extra = safeStart.slice(self.size, safeStart.length - self.size);
                resolve(filled, extra);
            });
        }
        
        (startingArray || []).forEach((element, index) => {
            self.buffer[self.filledCount] = element;
            self.filledCount += 1;
        })
        
        return new Promise((resolve, reject) => {
            function pump() {
                self.reader.read().then(({value, done}) => {
                    self.handleNewChunk(value).then((done, extra) => {
                        if (done) {
                            resolve(self.buffer, extra);
                        } else {
                            pump();
                        }
                    });
                });
            }
            pump();
        });
    }
    
    handleNewChunk(chunk) {
        const self = this;
        const safeChunk = chunk || [];
        
        if(safeChunk.length + self.filledCount >= self.size) {
            const remainingCount = self.size - self.filledCount;
            self.appendNewChunk(safeChunk.slice(0, remainingCount - 1));
            
            return new Promise((resolve, reject) => {
                const extra = safeChunk.slice(remainingCount);
                resolve(true, extra);
            });
        }
        
        self.appendNewChunk(safeChunk);
        return new Promise((resolve, reject) => {
           resolve(false);
        });
    }
    
    appendNewChunk(chunk) {
        (chunk || []).forEach((element, index) => {
            this.buffer[this.filledCount] = element;
            this.filledCount += 1;
        })
    }
}

class StreamApiCall {
    
    constructor(response) {
        this.response = response;
    }
    
    setChunkHandler(handler) {
        this.chunkHandler = handler;
        const self = this;
        
        const reader = this.response.body.getReader();
        self.reader = reader;
        
        function beginCollectingNewPacket(startingBuffer) {
            const size = new DataView(startingBuffer.buffer).getUint32(0, true);
            const collector = new StreamPacketCollector(reader, size);
            return collector.collectStartingWith(startingBuffer.slice(4));
        }
        
        function pump() {
            reader.read().then(({value, done}) => {
                if (done) {
                    return;
                }
                
                function goNext(finishedPacket, extra) {
                    handler(finishedPacket);
                    console.log("collected packet of length: " + finishedPacket.length);

                    if ((extra || []).length > 0) {
                        beginCollectingNewPacket(extra).then(goNext);
                    } else {
                        pump();
                    }
                }
                
                beginCollectingNewPacket(value).then(goNext);
            });
        }
        pump();
    }
    
    closeStream() {
        this.reader.cancel();
    }
}

class NativeApiCall extends CallableObject {

    constructor(nativeApiSymbol, origin) {
        super();
        this.nativeApiSymbol = nativeApiSymbol;
        this.origin = origin;
    }

    _call(...args) {
        const self = this;

        return new Promise((resolve, reject) => {
            const formData = new FormData();
            args.forEach((element, index) => {
                self.insert(element, index + '', formData);
            });
                
            self.makeApiCall(formData, resolve, reject);
        });
    }
    
    makeApiCall(formData, resultCallback, errorCallback) {
        const self = this;
        const url = `${this.origin}/${self.nativeApiSymbol}`;
        const options = {
          method: 'POST',
          mode: 'cors',
          body: formData
        };
        fetch(url, options)
        .then((response) => {
            console.log("HEEELP");
            if (!response.ok) {
              throw new Error(`HTTP error! status: ${response.status} for ${self.nativeApiSymbol} and ${formData}`);
            }
            
            const isStreamedResponse = response.headers.get("X-Stream-Header");
            
            if (isStreamedResponse && isStreamedResponse .includes("*")) {
                resultCallback(new StreamApiCall(response))
                return;
            }
    
            return response.json()        .then((jsonResponse) => {
                if(jsonResponse.error) {
                    errorCallback(jsonResponse.error);
                } else if(jsonResponse.result) {
                    self.processApiResult(jsonResponse.result, resultCallback, errorCallback);
                }
            }, errorCallback);
        })
    }
    
    processApiResult(resultArray, resultCallback, errorCallback) {
        const self = this;
        const promises = resultArray.map(element => {
            return self.promiseFor(element, resultArray)
        });
        
        Promise.all(promises).then((values) => {
            resultCallback(values);
        }, (errorReason) => {
            errorCallback(errorReason);
        });
    }
    
    promiseFor(valueItem, results) {
        const self = this;
        return new Promise((resolve, reject) => {
            if(!exists(valueItem.type)) { reject(`Unknown result type for value ${valueItem}; ${results} in call ${self.nativeApiSymbol}`); return;}
            if(valueItem.type == "number" || valueItem.type == "string") {
                const value = valueItem.value;
                if(!exists(value) || !(isNumber(value) || isString(value))) {
                    reject(`Value in ${valueItem} is neither string nor number; ${results}, ${self.nativeApiSymbol}`);
                    return;
                }
                resolve(value);
            } else {
                if(valueItem.type == "bytes") {
                    self.downloadBytes(valueItem, results, resolve, reject);
                }
            }
        });
    }
    
    downloadBytes(bytesItem, results, resolve, reject) {
        const self = this;
        if(!bytesItem.path || !(isString(bytesItem.path))) {
            reject(`Path field non-existend or wrong type: ${bytesItem}; ${results}, ${self.nativeApiSymbol}`);
            return;
        }
        const url = `${this.origin}${bytesItem.path}`;
        const options = {
        method: 'GET',
        mode: 'cors'
        };
        fetch(url, options)
        .then((response) => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status} for ${self.nativeApiSymbol} retrieving ${bytesItem.path}`);
            }
            return response.blob();
        })
        .then(resolve, reject);
    }
    
    insert(element, name, formData) {
        const isBasicType =
        (element instanceof Blob) ||
        isString(element) ||
        isNumber(element);
        
        if(isBasicType) {
            formData.set(name, element);
        } else {
            if(element instanceof Uint8Array) {
                formData.set(name, new Blob(element, {type : 'application/octet-stream'}));
            } else if(this.isArrayOfNumbersOrStrings(element)) {
                formData.set(name, JSON.stringify(element));
            } else {
                const message = `The value ${element} is not an instance of an accepted type. Only Number, String, [String|Number], Uint8Array and Blob are acceptable types. Api call: ${this.nativeApiSymbol}`;
                throw new Error(message);
            }
        }
    }
    
    isArrayOfNumbersOrStrings(element) {
        if(element instanceof Array) {
            return element.reduce((acc, value) => {
                return acc && (isNumber(value) || isString(value));
            }, true);
        }
        return false;
    }

}

class PSSmartWalletNativeLayer {

    constructor(origin) {
        this.nativeApiMap = {};
        this.origin = origin;
    }

    importNativeAPI(name) {
        const nativeApiCall = this.nativeApiMap[name] ||
          new NativeApiCall(name, this.origin);
        this.nativeApiMap[name] = nativeApiCall;
        return nativeApiCall;
    }
    
}

const defaultNativeSmartWallet = new PSSmartWalletNativeLayer(window.location.origin);
